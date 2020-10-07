package application


Texture :: struct {
	mips: []^Bitmap,
	mip_count: i32,
}
initTexture :: proc(using t: ^Texture, bitmap: ^Bitmap) {
	total_pixel_count: i32;
	mip_count = 1;
	mip_size: i32 = 1;
	
	for mip_size < bitmap.width {
		mip_size <<= 1;
		total_pixel_count += mip_size * mip_size;
		mip_count += 1;
	}	
	mip_size >>= 1;
	end_pixel_offset: i32 = mip_size * mip_size;
	start_pixel_offset: i32;

	total_pixel_count -= bitmap.size;
	total_pixel_count += 1;
	bits := make_slice([]u32, total_pixel_count);
	
	mips = make_slice([]^Bitmap, mip_count);
	mips[0] = bitmap;
	mip: ^Bitmap;
	
	for i in 1..<mip_count {
		mip = new(Bitmap); 
		mips[i] = mip;

		initBitmap(mip, mip_size, mip_size, bits[start_pixel_offset: end_pixel_offset]);
		
		mip_size >>= 1;
		
		start_pixel_offset = end_pixel_offset;
		end_pixel_offset += mip_size * mip_size;
	}
}


PixelBlock :: struct { TL, TR, BL, BR: vec4 };
PixelBlockRow :: []PixelBlock;
PixelBlockGrid :: []PixelBlockRow;
BlockedBitmap :: struct {
	all_pixel_blocks: PixelBlockRow,
	all_pixel_block_rows: []PixelBlockRow,
	pixel_blocks: PixelBlockGrid,
	width, height, size: i32	
}
initBlockedBitmap :: proc(using bb: ^BlockedBitmap, new_width, new_height: i32, bits: []PixelBlock) {
	all_pixel_blocks = bits;
	resizeBlockedBitmap(bb, new_width, new_height);
}

resizeBlockedBitmap :: proc(using bb: ^BlockedBitmap, new_width, new_height: i32) {
	width = new_width;
	height = new_height;
	size = width * height;

	start: i32;
	end := width;

	all_pixel_block_rows = make_slice([]PixelBlockRow, height);

	for y in 0..<height {
		all_pixel_block_rows[y] = all_pixel_blocks[start:end];
		start += width;
		end   += width;
	}

	pixel_blocks = all_pixel_block_rows[:height];
}

clearTexture :: inline proc(using t: ^Texture, transparent: bool = false) do 
	for mip in &mips do 
		clearBitmap(mip, transparent);

setMips :: proc(mips: []^Bitmap) {
	from_mip := mips[0];
	to_mip   := mips[1];
	
	to_color, from_color_bottom_left, from_color_bottom_right, from_color_top_left, from_color_top_right: ^Color;
	for i in 1..<len(mips) {
		to_mip = mips[i];
		clearBitmap(to_mip);
		for y in 0..<to_mip.height {
			for x in 0..<to_mip.width {
				to_color = &to_mip.pixels[y][x];
				from_color_top_left     = &from_mip.pixels[2*y    ][2*x];
				from_color_top_right    = &from_mip.pixels[2*y    ][2*x + 1];
				from_color_bottom_left  = &from_mip.pixels[2*y + 1][2*x    ];
				from_color_bottom_right = &from_mip.pixels[2*y + 1][2*x + 1];

				to_color.R = u8((f32(from_color_top_left.R) + f32(from_color_top_right.R) + f32(from_color_bottom_left.R) + f32(from_color_bottom_right.R)) / 4);
				to_color.G = u8((f32(from_color_top_left.G) + f32(from_color_top_right.G) + f32(from_color_bottom_left.G) + f32(from_color_bottom_right.G)) / 4);
				to_color.B = u8((f32(from_color_top_left.B) + f32(from_color_top_right.B) + f32(from_color_bottom_left.B) + f32(from_color_bottom_right.B)) / 4); 
			}
		}
		// print("setMips", i, to_mip.pixels[len(to_mip.pixels) - 1][len(to_mip.pixels[0]) - 1]);

		from_mip = to_mip;
	}
	// printBitmap(mips[3]);
}

setBlockedBitmap :: proc(blocked_bitmap: ^BlockedBitmap, using bitmap: ^Bitmap, smear_edges: bool = false, wrap_edges: bool = false) {
	tl, tr, bl, br: ^Pixel;
	TLi, TRi, BLi, BRi: i32; 

	top_row_offset,
	bottom_row_offset: i32;
	bottom_row_offset = width;

	first_pixel_index: i32;
	last_pixel_index: i32 = size - 1;
	last_pixel_in_row: i32 = width - 1;
	first_pixel_of_last_row: i32 = last_pixel_index - last_pixel_in_row;

	x, y,
	X, Y: i32;

	for row, row_index in &blocked_bitmap.pixel_blocks {
		Y = i32(row_index);
		y = Y - 1;

		for pixel_block, column_index in &row {
			X = i32(column_index);
			x = X - 1;

			if wrap_edges {
				if (X == 0 || X == width) {  
					if (Y == 0 || Y == height) { // TL/TR/BL/BR
						TLi = last_pixel_index;
						TRi = first_pixel_of_last_row;
						BLi = last_pixel_in_row;
						BRi = first_pixel_index;
					} else { // L/R:
						TLi = top_row_offset + last_pixel_in_row;
						TRi = top_row_offset;
						BLi = bottom_row_offset + last_pixel_in_row;
						BRi = bottom_row_offset;						
					}
				} else {
					if (Y == 0 || Y == height) { // T/B
						TLi = first_pixel_of_last_row + x;
						TRi = first_pixel_of_last_row + x + 1;
						BLi = x;
						BRi = x + 1;
					} else {
						TLi = x + top_row_offset;
						TRi = x + top_row_offset + 1;
						BLi = x + bottom_row_offset;
						BRi = x + bottom_row_offset + 1;	
					}
				}
			} else if smear_edges {
				if Y == 0 {
					if X == 0 { // TL
						TLi = first_pixel_index;
						TRi = first_pixel_index;
						BLi = first_pixel_index;
						BRi = first_pixel_index;			
					} else if X == width { // TR
						TLi = last_pixel_in_row;
						TRi = last_pixel_in_row;
						BLi = last_pixel_in_row;
						BRi = last_pixel_in_row;
					} else { // T
						TLi = x;
						TRi = x + 1;
						BLi = x;
						BRi = x + 1;
					}
				} else if Y == height {
					if X == 0 { // BL
						TLi = first_pixel_of_last_row;
						TRi = first_pixel_of_last_row;
						BLi = first_pixel_of_last_row;
						BRi = first_pixel_of_last_row;			
					} else if X == width { // BR
						TLi = last_pixel_index;
						TRi = last_pixel_index;
						BLi = last_pixel_index;
						BRi = last_pixel_index;
					} else { // B
						TLi = first_pixel_of_last_row + x;
						TRi = first_pixel_of_last_row + x + 1;
						BLi = first_pixel_of_last_row + x;
						BRi = first_pixel_of_last_row + x + 1;
					}
				} else { 
					if X == 0 { // T
						TLi = top_row_offset;
						TRi = top_row_offset;
						BLi = bottom_row_offset;			
						BRi = bottom_row_offset;
					} else if X == width { // R
						TLi = top_row_offset + last_pixel_in_row;
						TRi = top_row_offset + last_pixel_in_row;
						BLi = bottom_row_offset + last_pixel_in_row;
						BRi = bottom_row_offset + last_pixel_in_row;	
					} else {
						TLi = x + top_row_offset;
						TRi = x + top_row_offset + 1;
						BLi = x + bottom_row_offset;
						BRi = x + bottom_row_offset + 1;
					}
				}
			} else {
				if Y == 0 { 
					if X == 0 { // TL
						TLi = -1;
						TRi = -1;
						BLi = -1;
						BRi = first_pixel_index;			
					} else if X == width { // TR
						TLi = -1;
						TRi = -1;
						BLi = last_pixel_in_row;
						BRi = -1;
					} else { // T
						TLi = -1;
						TRi = -1;
						BLi = x;
						BRi = x + 1;
					}
				} else if Y == height { 
					if X == 0 { // BL
						TLi = -1;
						TRi = first_pixel_of_last_row;
						BLi = -1;
						BRi = -1;			
					} else if X == width { // BR
						TLi = last_pixel_index;
						TRi = -1;
						BLi = -1;
						BRi = -1;
					} else { // B
						TLi = first_pixel_of_last_row + x;
						TRi = first_pixel_of_last_row + x + 1;
						BLi = -1;
						BRi = -1;	
					}
				} else { 
					if X == 0 { // L
						TLi = -1;
						TRi = top_row_offset;
						BLi = -1;			
						BRi = bottom_row_offset;
					} else if X == width { // R
						TLi = top_row_offset + last_pixel_in_row;
						TRi = -1;
						BLi = bottom_row_offset + last_pixel_in_row;
						BRi = -1;
					} else {
						TLi = x + top_row_offset;
						TRi = x + top_row_offset + 1;
						BLi = x + bottom_row_offset;
						BRi = x + bottom_row_offset + 1;
					}
				}
			}

			tl = TLi == -1 ? &BLACK_PIXEL : &all_pixels[TLi];
			tr = TRi == -1 ? &BLACK_PIXEL : &all_pixels[TRi];
			bl = BLi == -1 ? &BLACK_PIXEL : &all_pixels[BLi];
			br = BRi == -1 ? &BLACK_PIXEL : &all_pixels[BRi];

			using pixel_block;

			TL.r = f32(tl.R);
			TR.r = f32(tr.R);
			BL.r = f32(bl.R);
			BR.r = f32(br.R);

			TL.g = f32(tl.G);
			TR.g = f32(tr.G);
			BL.g = f32(bl.G);
			BR.g = f32(br.G);

			TL.b = f32(tl.B);
			TR.b = f32(tr.B);
			BL.b = f32(bl.B);
			BR.b = f32(br.B);

			TL.a = f32(tl.opacity);
			TR.a = f32(tr.opacity);
			BL.a = f32(bl.opacity);
			BR.a = f32(br.opacity);
		}

		if Y != 0 {
			top_row_offset = bottom_row_offset;
			bottom_row_offset += width;
		}
	}
}

sampleBlockedBitmap :: inline proc(using blocked_bitmap: ^BlockedBitmap, u, v: f32, pixel: ^Pixel, factor: f32 = 1) {
	U := u * f32(width) - 0.5;
	V := v * f32(height) - 0.5;

	x := i32(U);
	y := i32(V);

	samples := &pixel_blocks[y][x];

	right_ratio  := U - f32(x);
	bottom_ratio := V - f32(y);
	
	left_ratio := 1 - right_ratio;
	top_ratio := 1 - bottom_ratio;

	using samples;
	top := TL * left_ratio + TR * right_ratio;
	bottom := BL * left_ratio + BR * right_ratio;
	result := top * top_ratio + bottom * bottom_ratio;

	pixel.R = u8(result.r);
	pixel.G = u8(result.g);
	pixel.B = u8(result.b);
	pixel.opacity = u8(result.a);
}

readTextureFromFile :: proc(texture: ^Texture, file: []u8) {
	bitmap := new(Bitmap);
	readBitmapFromFile(bitmap, file);
	initTexture(texture, bitmap);
}
