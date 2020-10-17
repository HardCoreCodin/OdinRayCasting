package application

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

BitmapColor :: struct #packed {b, g, r: u8}
BitmapPixel :: struct {using color: BitmapColor, a: u8} 
Pixel :: struct #raw_union {
	using pixel: BitmapPixel,
	value: u32
}

BLACK,
WHITE,
GREY ,
RED  ,
GREEN,
BLUE ,
YELLOW,
CYAN ,
MAGENTA: Pixel;

initColors :: proc() {
	BLACK.r = 0x00;
	BLACK.g = 0x00;
	BLACK.b = 0x00;
	BLACK.a = 0xFF;
	WHITE.r = 0xFF;
	WHITE.g = 0xFF;
	WHITE.b = 0xFF;
	WHITE.a = 0xFF;

	GREY.r = 0x88;
	GREY.g = 0x88;
	GREY.b = 0x88;
	GREY.a = 0xFF;

	RED.r = 0xFF;
	RED.g = 0x00;
	RED.b = 0x00;
	RED.a = 0xFF;
	GREEN.r = 0x00;
	GREEN.g = 0xFF;
	GREEN.b = 0x00;
	GREEN.a = 0xFF;

	BLUE.r = 0x00;
	BLUE.g = 0x00;
	BLUE.b = 0xFF;
	BLUE.a = 0xFF;

	YELLOW.r = 0xFF;
	YELLOW.g = 0xFF;
	YELLOW.b = 0x00;
	YELLOW.a = 0xFF;

	CYAN.r = 0x00;
	CYAN.g = 0xFF;
	CYAN.b = 0xFF;
	CYAN.a = 0xFF;

	MAGENTA.r = 0xFF;
	MAGENTA.g = 0x00;
	MAGENTA.b = 0xFF;
	MAGENTA.a = 0xFF;
}

Grid :: struct (Cell: typeid) {
	_cells: []Cell,
	_rows: [][]Cell,
	cells: [][]Cell,
	width, height, size: i32	
}
Bitmap :: Grid(Pixel);

_setPixelPP :: inline proc(to: ^Pixel, from: ^Pixel) do to^ = from^;
_setPixelVV :: inline proc(to: ^vec4, from: ^vec4) do to^ = from^;
_setPixelVP :: inline proc(to: ^vec4, from: ^Pixel) {
	to.r = f32(from.r);
	to.g = f32(from.g);
	to.b = f32(from.b);
	to.a = f32(from.a);
}
_setPixelPV :: inline proc(to: ^Pixel, from: ^vec4) {
	to.r = u8(from.r);
	to.g = u8(from.g);
	to.b = u8(from.b);
	to.a = u8(from.a);
}
setPixel :: proc{_setPixelPP, _setPixelVV, _setPixelVP, _setPixelPV};

initGrid :: proc(grid: ^Grid($Cell), width, height: i32, cells: []Cell) {
	grid._cells = cells;
	resizeGrid(grid, width, height);
}

resizeGrid :: proc(grid: ^Grid($Cell), width, height: i32) {
	grid.width = width;
	grid.height = height;
	grid.size = width * height;

	start: i32;
	end := width;

	grid._rows = make_slice([][]Cell, height);

	for y in 0..<height {
		grid._rows[y] = grid._cells[start:end];
		start += width;
		end   += width;
	}

	grid.cells = grid._rows[:height];
}

_clearPixel :: inline proc(color: ^$T, transparent: bool = false) {
	color.r = 0;
	color.g = 0;
	color.b = 0;
	color.a = transparent ? 0 : 0xFF;
}
_clearSample :: inline proc(sample: ^Sample, transparent: bool = false) do for pixel in sample do _clearPixel(&pixel, transparent);
clearBitmap :: inline proc(bitmap: ^$T/Grid, transparent: bool = false) do for pixel in &bitmap._cells do clearPixel(&pixel, transparent);
clearPixel :: proc{_clearPixel, _clearSample};

_isTransparent :: inline proc(pixel: ^$T) -> bool do return pixel.r == 0xFF && pixel.b == 0xFF && pixel.g == 0;
_readBitmapFromFileData :: proc(using bitmap: ^$T/Grid, bitmap_file_data: []u8) {
	bitmap_pixel: BitmapPixel;
	for row, y in &cells do 
		for pixel, x in &row {
			pixel.color = (^BitmapColor)(&bitmap_file_data[((height-1 -i32(y))*width + i32(x))*3])^;
			pixel.a = _isTransparent(&pixel.color) ? 0 : 0xFF;
		}
}
_readBitmapFromFile :: proc(bitmap: ^Grid($Cell), file: ^[]u8, pixels: []Cell) {
	header:= (^BMP_FileHeader)(&file[0])^;
	bitmap_file_data := file[header.data_offset:];

	initGrid(bitmap, header.width, header.height, pixels);
	_readBitmapFromFileData(bitmap, bitmap_file_data);
}
_allocateAndReadBitmapFromFile :: proc(bitmap: ^$T/Grid , file: ^[]u8) {
	header:= (^BMP_FileHeader)(&file[0])^;
	bitmap_file_data := file[header.data_offset:];

	pixels := make_slice([]Cell, header.width * header.height);
	initGrid(bitmap, header.width, header.height, pixels);
	_readBitmapFromFileData(bitmap.cells, bitmap_file_data);
}
readBitmapFromFile :: proc{_readBitmapFromFile, _allocateAndReadBitmapFromFile};

sampleGrid :: inline proc(using grid: ^$T/Grid, u, v: f32, cell: ^$Cell) do setPixel(cell, &grid.cells[i32(v * f32(height))][i32(u * f32(width))]);
scaleGrid :: proc(from: ^$T/Grid, to: ^$S/Grid) {
	scale_factor := f32(from.width) / f32(to.width);
	for y in 0..<to.height do
		for x in 0..<to.width do
			setPixel(&to.cells[y][x], &from.cells[i32(f32(y) * scale_factor)][i32(f32(x) * scale_factor)]);
}

drawPixel :: inline proc(to_pixel: ^$To, from_pixel: ^$From) {
	to_color: vec4;
	from_alpha, to_alpha: f32;
	if from_pixel.a != 0 {
		if from_pixel.a < 255 {
			from_alpha = f32(from_pixel.a) / 255;
			if to_pixel.a < 255 {
				to_alpha = f32(to_pixel.a) / 255;
				to_color.r = min(255, f32(to_pixel.r) * to_alpha + f32(from_pixel.r) * from_alpha);
				to_color.g = min(255, f32(to_pixel.g) * to_alpha + f32(from_pixel.g) * from_alpha);
				to_color.b = min(255, f32(to_pixel.b) * to_alpha + f32(from_pixel.b) * from_alpha);
				to_color.a = min(1, to_alpha + from_alpha) * 255;
			} else {
				to_color.r = min(255, f32(to_pixel.r) + f32(from_pixel.r) * from_alpha);
				to_color.g = min(255, f32(to_pixel.g) + f32(from_pixel.g) * from_alpha);
				to_color.b = min(255, f32(to_pixel.b) + f32(from_pixel.b) * from_alpha);
				to_color.a = 255;
			}
			setPixel(to_pixel, &to_color);
		} else do setPixel(to_pixel, from_pixel);
	}
}

drawBitmap :: proc(from: ^$T/Grid, to: ^$S/Grid, to_x: i32 = 0, to_y: i32 = 0) {
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

	for y in to_start.y..<to_end.y do
		for x in to_start.x..<to_end.x do 
			drawPixel(&to.cells[y][x], &from.cells[y - to_y][x - to_x]);
}


import "core:fmt"

printBitmap :: proc(bitmap: ^$T/Grid ) {
	fmt.printf(TEXT_COLOR__RESET);

	for row in &bitmap.cells {
		for pixel in row {
			if pixel.a == 0 do fmt.printf(TEXT_COLOR__BLACK);
			else if pixel.r == 255 && pixel.g == 255 && pixel.b == 255 do fmt.printf(TEXT_COLOR__WHITE);
			else if pixel.r == 255 && pixel.g ==   0 && pixel.b == 255 do fmt.printf(TEXT_COLOR__MAG);
			else if pixel.g >= pixel.r && pixel.g >= pixel.b do fmt.printf(TEXT_COLOR__GREEN);
			else if pixel.r >= pixel.g && pixel.r >= pixel.b do fmt.printf(TEXT_COLOR__RED);
			else if pixel.b >= pixel.g && pixel.b >= pixel.r do fmt.printf(TEXT_COLOR__BLUE);
			else do fmt.printf(TEXT_COLOR__MAG);

			fmt.print('#');
		}
		fmt.println();
	}

	fmt.printf(TEXT_COLOR__RESET);
}