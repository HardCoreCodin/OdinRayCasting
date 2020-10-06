package application

import "core:fmt"

Pixel :: struct {
	using color: Color,
	opacity: u8
}
PixelRow :: []Pixel;
PixelGrid :: []PixelRow;
Bitmap :: struct {
	all_pixels: PixelRow,
	all_rows: []PixelRow,
	pixels: PixelGrid,
	width, height, size: i32	
}
initBitmap :: proc(using bitmap: ^Bitmap, new_width, new_height: i32, bits: []u32) {
	all_pixels = transmute(PixelRow)(bits);
	resizeBitmap(bitmap, new_width, new_height);
}

resizeBitmap :: proc(using bitmap: ^Bitmap, new_width, new_height: i32) {
	width = new_width;
	height = new_height;
	size = width * height;

	start: i32;
	end := width;

	all_rows = make_slice([]PixelRow, height);

	for y in 0..<height {
		all_rows[y] = all_pixels[start:end];
		start += width;
		end   += width;
	}

	pixels = all_rows[:height];
}

BLACK_PIXEL: Pixel = {color=BLACK, opacity=255};
TRANSPARENT_PIXEL: Pixel = {color=BLACK, opacity=0};

clearBitmap :: inline proc(using bm: ^Bitmap, transparent: bool = false) do 
	for pixel in &all_pixels do 
		pixel = transparent ? TRANSPARENT_PIXEL : BLACK_PIXEL;

_readBitmapPixelsFromFileData :: proc(using bitmap: ^Bitmap, data: []u8) {
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

_readBitmapFromFile :: proc(using bitmap: ^Bitmap, file: []u8, bits: []u32) {
	header:= (^BMP_FileHeader)(&file[0])^;

	initBitmap(bitmap, header.width, header.height, bits);

	_readBitmapPixelsFromFileData(bitmap, file[header.data_offset:]);
}

_allocateAndReadBitmapFromFile :: proc(using bitmap: ^Bitmap, file: []u8) {
	header:= (^BMP_FileHeader)(&file[0])^;

	bits := make_slice([]u32, header.width * header.height);
	initBitmap(bitmap, header.width, header.height, bits);

	_readBitmapPixelsFromFileData(bitmap, file[header.data_offset:]);
}
readBitmapFromFile :: proc{_readBitmapFromFile, _allocateAndReadBitmapFromFile};

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
			else do fmt.printf(TEXT_COLOR__MAG);

			fmt.print('#');
		}
		fmt.println();
	}

	fmt.printf(TEXT_COLOR__RESET);
}

drawBitmap :: proc(from, to: ^Bitmap, to_x: i32 = 0, to_y: i32 = 0) {
	if to_x > to.width ||
	    to_y > to.height ||
	    to_x + from.width < 0 ||
	    to_y + from.height < 0 do
	    return;

	to_start: vec2i = {
		max(to_x, 0),
		max(to_y, 0)
	}; 
	to_end: vec2i = {
		min(to_x+from.width, to.width),
		min(to_y+from.height, to.height)
	};

	from_alpha, to_alpha: f32;
	from_pixel, to_pixel: ^Pixel;
	for y in to_start.y..<to_end.y {
		for x in to_start.x..<to_end.x {
			to_pixel := &to.pixels[y][x];
			from_pixel = &from.pixels[y - to_y][x - to_x];

			if from_pixel.opacity != 0 {
				if from_pixel.opacity < 255 {
					from_alpha = f32(from_pixel.opacity) / 255;
					if to_pixel.opacity < 255 {
						to_alpha = f32(to_pixel.opacity) / 255;
						to_pixel.color.R = u8(min(255, f32(to_pixel.color.R) * to_alpha + f32(from_pixel.color.R) * from_alpha));
						to_pixel.color.G = u8(min(255, f32(to_pixel.color.G) * to_alpha + f32(from_pixel.color.G) * from_alpha));
						to_pixel.color.B = u8(min(255, f32(to_pixel.color.B) * to_alpha + f32(from_pixel.color.B) * from_alpha));
						to_pixel.opacity = u8(min(1, to_alpha + from_alpha) * 255);
					} else {
						to_pixel.color.R = u8(min(255, f32(to_pixel.color.R) + f32(from_pixel.color.R) * from_alpha));
						to_pixel.color.G = u8(min(255, f32(to_pixel.color.G) + f32(from_pixel.color.G) * from_alpha));
						to_pixel.color.B = u8(min(255, f32(to_pixel.color.B) + f32(from_pixel.color.B) * from_alpha));
					}
				} else do to_pixel^ = from_pixel^;
			}
		} 
	}
}

drawBitmapToScale :: proc(from, to: ^Bitmap) {
	pixel_size := f32(from.width) / f32(to.width);

	for y in 0..<to.height do
		for x in 0..<to.width do
			to.pixels[y][x] = from.pixels[i32(f32(y) * pixel_size)][i32(f32(x) * pixel_size)];
}

sampleBitmap :: inline proc(using bm: ^Bitmap, u, v: f32, pixel: ^Pixel) do
	pixel^ = pixels[i32(v * f32(height))][i32(u * f32(width))];

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