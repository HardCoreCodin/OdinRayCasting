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

setBlockedBitmap :: proc(blocked_bitmap: ^BlockedBitmap, using bitmap: ^Bitmap, smear_edges: bool = true, wrap_edges: bool = false) {
	tl, tr, bl, br: ^Pixel;
	
	i: [4]i32; 

	T,
	B: i32;
	B = width;

	L: i32;
	BR: i32 = size - 1;
	R: i32 = width - 1;
	BL: i32 = BR - R;
	__: i32 = -1;

	x, y,
	X, Y: i32;

	for row, row_index in &blocked_bitmap.pixel_blocks {
		Y = i32(row_index);
		y = Y - 1;

		for pixel_block, column_index in &row {
			X = i32(column_index);
			x = X - 1;

			i = {T+x, T+x+1,
				 B+x, B+x+1};

			if wrap_edges {
				if (X == 0 || X == width) {  
					if (Y == 0 || Y == height) do i = { // TL/TR/BL/BR
						BR, BL,
				        R,  L
				    }; else do i = { // L/R:
				    	T+R, T,  
				    	B+R, B
				    };
				} else if (Y == 0 || Y == height) do i = { // T/B
					BL+x, BL+x+1,
				    x,    x+1
				};
			} else if smear_edges {
				if Y == 0 {
					if X == 0 do i = { // TL
						L, L,
				        L, L
				    }; else if X == width do i = { // TR
						R, R,
				        R, R
				    }; else do i = { // T
						x, x+1,
				        x, x+1
					};
				} else if Y == height {
					if X == 0 do i = { // BL
						BL, BL,
				        BL, BL		
					}; else if X == width do i = { // BR
						BR, BR,
				        BR, BR
					}; else do i = { // B
						BL+x, BL+x+1,
				        BL+x, BL+x+1
					};
				} else { 
					if X == 0 do i = { // T
						T, T,
				        B, B
					}; else if X == width do i = { // R
						T+R, T+R,
				        B+R, B+R
					};
				}
			} else {
				if Y == 0 { 
					if X == 0 do i = { // TL
						__, __,
				        __, L		
					}; else if X == width do i = { // TR
						__, __,
				        R, __
					}; else do i = { // T
						__, __,
				        x, x+1
					};
				} else if Y == height { 
					if X == 0 do i = { // BL
						__, BL,
				        __, __		
					}; else if X == width do i = { // BR
						BR, __,
				        __,  __
					}; else do i = { // B
						BL+x, BL+x+1,
				        __,    __ 
					};
				} else { 
					if X == 0 do i = { // L
						__, T,
				        __, B
					}; else if X == width do i ={ // R
						T+R, __,
				        B+R, __
					};
				}
			}

			tl = i[0] == __ ? &BLACK_PIXEL : &all_pixels[i[0]];
			tr = i[1] == __ ? &BLACK_PIXEL : &all_pixels[i[1]];
			bl = i[2] == __ ? &BLACK_PIXEL : &all_pixels[i[2]];
			br = i[3] == __ ? &BLACK_PIXEL : &all_pixels[i[3]];


			pixel_block.TL.r = f32(tl.R);
			pixel_block.TR.r = f32(tr.R);
			pixel_block.BL.r = f32(bl.R);
			pixel_block.BR.r = f32(br.R);

			pixel_block.TL.g = f32(tl.G);
			pixel_block.TR.g = f32(tr.G);
			pixel_block.BL.g = f32(bl.G);
			pixel_block.BR.g = f32(br.G);

			pixel_block.TL.b = f32(tl.B);
			pixel_block.TR.b = f32(tr.B);
			pixel_block.BL.b = f32(bl.B);
			pixel_block.BR.b = f32(br.B);

			pixel_block.TL.a = f32(tl.opacity);
			pixel_block.TR.a = f32(tr.opacity);
			pixel_block.BL.a = f32(bl.opacity);
			pixel_block.BR.a = f32(br.opacity);
		}

		if Y != 0 {
			T = B;
			B += width;
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
