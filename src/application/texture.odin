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

readTextureFromFile :: proc(texture: ^Texture, file: []u8) {
	bitmap := new(Bitmap);
	readBitmapFromFile(bitmap, file);
	initTexture(texture, bitmap);
}
