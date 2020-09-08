package application

Pixel :: struct {
	using color: Color,
	A: u8
}
PixelRow :: []Pixel;
PixelGrid :: []PixelRow;
Bitmap :: struct {
	all_pixels: PixelRow,
	all_rows: [MAX_HEIGHT]PixelRow,
	pixels: PixelGrid,
	width, height, size: i32	
}

initBitmap :: proc(using bitmap: ^Bitmap, new_width, new_height: i32, bits: []u32) {
	all_pixels = transmute(PixelRow)(bits);

	width = new_width;
	height = new_height;
	size = width * height;

	start: i32;
	end := width;

	for y in 0..<height {
		all_rows[y] = all_pixels[start:end];
		start += width;
		end   += width;
	}

	pixels = all_rows[:height];
}

drawBitmap :: proc(from, to: ^Bitmap, pos: vec2i) {
	if pos.x > to.width ||
	    pos.y > to.height ||
	    pos.x + from.width < 0 ||
	    pos.y + from.height < 0 do
	    return;

	to_start: vec2i = {
		max(pos.x, 0),
		max(pos.y, 0)
	}; 
	to_end: vec2i = {
		min(pos.x+from.width, to.width),
		min(pos.y+from.height, to.height)
	};

	pixel: ^Pixel;
	for y in to_start.y..<to_end.y {
		for x in to_start.x..<to_end.x {
			pixel = &from.pixels[y - pos.y][x - pos.x];
			if pixel.A != 0 do to.pixels[y][x] = pixel^;
		} 
	}
}