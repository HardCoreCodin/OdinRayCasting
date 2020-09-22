package application

import "core:fmt"

MAX_BITMAP_WIDTH  :: 3840;
MAX_BITMAP_HEIGHT :: 2160;
MAX_BITMAP_SIZE   :: MAX_BITMAP_WIDTH * MAX_BITMAP_HEIGHT;

Pixel :: struct {
	using color: Color,
	opacity: u8
}
PixelRow :: []Pixel;
PixelGrid :: []PixelRow;
Bitmap :: struct {
	all_pixels: PixelRow,
	all_rows: [MAX_BITMAP_HEIGHT]PixelRow,
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

readBitmapFromFile :: proc(file: []u8, using bitmap: ^Bitmap, bits: []u32) {
	header:= (^BMP_FileHeader)(&file[0])^;
	data := file[header.data_offset:];

	initBitmap(bitmap, header.width, header.height, bits);

	for row, y in &pixels do 
		for pixel, x in &row {
			pixel.color = (^Color)(&data[((height-1 -i32(y))*width + i32(x))*3])^;
			pixel.opacity = (
				pixel.color.R == 0xFF && 
			 	pixel.color.B == 0xFF && 
			 	pixel.color.G == 0
			 ) ? 0 : 0xFF;
		} 
}

printBitmap :: proc(using bm: ^Bitmap) {
	fmt.printf(TEXT_COLOR__RESET);

	for row in &pixels {
		for pixel in row {
			using pixel.color;
			if pixel.opacity == 0 do fmt.printf(TEXT_COLOR__BLACK);
			else if R == 255 && G == 255 && B == 255 do fmt.printf(TEXT_COLOR__WHITE);
			else if R == 255 && G ==   0 && B == 255 do fmt.printf(TEXT_COLOR__MAG);
			else if G >= R && G >= B do fmt.printf(TEXT_COLOR__GREEN);
			else if R >= G && R >= B do fmt.printf(TEXT_COLOR__RED);
			else if B >= G && B >= R do fmt.printf(TEXT_COLOR__BLUE);

			fmt.print('#');
		}
		fmt.println();
	}

	fmt.printf(TEXT_COLOR__RESET);
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
			if pixel.opacity != 0 do to.pixels[y][x] = pixel^;
		} 
	}
}

sampleBitmap :: proc(using bm: ^Bitmap, u, v: f32) -> Pixel {
	return pixels[i32(v * f32(TEXTURE_HEIGHT))][i32(u * f32(TEXTURE_WIDTH))];
}

BMP_FileHeader :: struct #packed {
	file_type : u16,  // Type of the file
    file_size : u32,  // Size of the file (in bytes)
    
    reserved1 : u16,  // Reserved (0)
    reserved2 : u16,  // Reserved (0)
    
    data_offset : u32,  // Offset to the data (in bytes)
    struct_size : u32,  // Struct size (in bytes )
    
    width  : i32,   // Bitmap width  (in pixels)
    height : i32,   // Bitmap height (in pixels)
    
    planes    : u16,   // Color planes count (1)
    bit_depth : u16,   // Bits per pixel

    compression : u32,  // Compression type
    image_size  : u32,  // Image size (in bytes)
    
    x_pixels_per_meter : i32,   // X Pixels per meter
    y_pixels_per_meter : i32,   // Y pixels per meter
    
    colors_used      : u32,  // User color count
    colors_important : u32   // Important color count
};