package application

MINIMAP__MIN_SIZE :: 64;
MINIMAP__MID_SIZE :: 128;
MINIMAP__MAX_SIZE :: 256;
MINIMAP__MIN_ZOOM_FACTOR  :: 0.1;
MINIMAP__MAX_ZOOM_FACTOR  :: 10;
MINIMAP__MIN_RESIZE_FACTOR :: 0.5;
MINIMAP__MAX_RESIZE_FACTOR :: 2;
MINIMAP__MAX_SCALE_FACTOR :: MINIMAP__MAX_ZOOM_FACTOR * MINIMAP__MAX_RESIZE_FACTOR;
MINIMAP__TILES_BITMAP_WIDTH       :: MINIMAP__MAX_SCALE_FACTOR * MAX_TILE_MAP_WIDTH;
MINIMAP__TILES_BITMAP_HEIGHT      :: MINIMAP__MAX_SCALE_FACTOR * MAX_TILE_MAP_HEIGHT;
MINIMAP__TILES_BITMAP_PIXEL_COUNT :: MINIMAP__TILES_BITMAP_WIDTH * MINIMAP__TILES_BITMAP_HEIGHT;
MINIMAP__CANVAS_BITMAP_PIXEL_COUNT :: MINIMAP__MAX_SIZE * MINIMAP__MAX_SIZE;

minimap_canvas_buffer: [2 *  MINIMAP__CANVAS_BITMAP_PIXEL_COUNT]u32;
minimap_textures_buffer: [3 * MINIMAP__TILES_BITMAP_PIXEL_COUNT]u32;

MiniMap :: struct {
	using tile_map_textures: TileMapTextures,
	
	canvas,	
	line_of_sight_canvas: Bitmap,

	walls_bits,
	floor_bits,
	ceiling_bits,
	canvas_bits,
	line_of_sight_canvas_bits: []u32,	

	screen_bounds: Bounds2Di,
	screen_position: ^vec2i,
	origin: ^vec2,
	top_left: vec2,

	tile_map: ^TileMap,
	center, pan, offset: vec2,
	center_color,
	front_edge_color,
	back_edge_color,
	vertex_color,
	tile_color,
	ray_color: Color,
 
 	zoom, 
 	resize: AmountAndFactor,

	scale_factor: f32,

	mip_level,
	mip_width,
	mip_height: i32,

	panned,
	toggled,
	is_visible,
	is_debug_visible: bool
}
initMiniMap :: proc(using mm: ^MiniMap, tm: ^TileMap, origin_position: ^vec2) {
	tile_map = tm;
	origin = origin_position;
	screen_position = &screen_bounds.min;

	is_visible = true;
	
	initAmountAndFactor(&zoom,   MINIMAP__MIN_ZOOM_FACTOR,   MINIMAP__MAX_ZOOM_FACTOR, 4);
	initAmountAndFactor(&resize, MINIMAP__MIN_RESIZE_FACTOR, MINIMAP__MAX_RESIZE_FACTOR);

	center_color = RED;
	ray_color = YELLOW;
	front_edge_color = WHITE;
	back_edge_color = GREY;
	vertex_color = GREEN;
	tile_color = BLUE;

	canvas_bits = minimap_canvas_buffer[0:MINIMAP__CANVAS_BITMAP_PIXEL_COUNT];
	line_of_sight_canvas_bits = minimap_canvas_buffer[MINIMAP__CANVAS_BITMAP_PIXEL_COUNT:MINIMAP__CANVAS_BITMAP_PIXEL_COUNT*2];
	walls_bits = minimap_textures_buffer[0:MINIMAP__TILES_BITMAP_PIXEL_COUNT];
	floor_bits = minimap_textures_buffer[MINIMAP__TILES_BITMAP_PIXEL_COUNT:MINIMAP__TILES_BITMAP_PIXEL_COUNT*2];
	ceiling_bits = minimap_textures_buffer[MINIMAP__TILES_BITMAP_PIXEL_COUNT*2:MINIMAP__TILES_BITMAP_PIXEL_COUNT*3];
	
	initBitmap(&canvas,               MINIMAP__MAX_SIZE, MINIMAP__MAX_SIZE, canvas_bits);
	initBitmap(&line_of_sight_canvas, MINIMAP__MAX_SIZE, MINIMAP__MAX_SIZE, line_of_sight_canvas_bits);
	initBitmap(&walls  , MINIMAP__TILES_BITMAP_WIDTH, MINIMAP__TILES_BITMAP_HEIGHT, walls_bits);
	initBitmap(&floor  , MINIMAP__TILES_BITMAP_WIDTH, MINIMAP__TILES_BITMAP_HEIGHT, floor_bits);
	initBitmap(&ceiling, MINIMAP__TILES_BITMAP_WIDTH, MINIMAP__TILES_BITMAP_HEIGHT, ceiling_bits);	
	
	clearBitmap(&canvas);
	clearBitmap(&line_of_sight_canvas, true);
	clearBitmap(&walls);
	clearBitmap(&floor);
	clearBitmap(&ceiling);

	resizeMiniMap(mm, MINIMAP__MID_SIZE);
}

moveMiniMap :: inline proc(using mm: ^MiniMap, movement: vec2) do top_left += movement;

zoomMiniMap :: inline proc(using mm: ^MiniMap) {
    zoom.amount += mouse_wheel_scroll_amount;
    mouse_wheel_scroll_amount = 0;  
    mouse_wheel_scrolled = false;
    updateAmountAndFactor(&zoom);
	resetMiniMapSize(mm);
}

resizeMiniMapByMouseWheel :: inline proc(using mm: ^MiniMap) {
    resize.amount += mouse_wheel_scroll_amount;
    mouse_wheel_scroll_amount = 0;   
    updateAmountAndFactor(&resize);
    resizeMiniMap(mm, i32(MINIMAP__MID_SIZE * resize.factor));
}

resizeMiniMap :: inline proc(using mm: ^MiniMap, new_size: i32) {
	size := clamp(new_size, MINIMAP__MIN_SIZE, MINIMAP__MAX_SIZE);
	initBitmap(&canvas, size, size, canvas_bits);
	resetMiniMapSize(mm);
	screen_bounds.max.x = screen_bounds.min.x + canvas.width;
	screen_bounds.max.y = screen_bounds.min.y + canvas.height;
}

resetMiniMapSize :: proc(using mm: ^MiniMap) {
	resize.factor = f32(canvas.width) / MINIMAP__MID_SIZE;
	scale_factor = resize.factor * zoom.factor;
	center.x = f32(canvas.width) / 2;
	center.y = f32(canvas.height) / 2;
	offset = center + pan;
	top_left = offset - origin^ * scale_factor;

	pixel_size := scale_factor / TEXTURE_WIDTH;
	new_width := i32(f32(map_textures[0].walls.width) * pixel_size); 
	new_height := i32(f32(map_textures[0].walls.height) * pixel_size);

	resizeBitmap(&walls,   new_width, new_height);
	resizeBitmap(&floor,   new_width, new_height);
	resizeBitmap(&ceiling, new_width, new_height);

	clearBitmap(&walls);
	clearBitmap(&floor);
	clearBitmap(&ceiling);

	mip_level = 0;
	mip_width = TEXTURE_WIDTH;
	mip_height = TEXTURE_HEIGHT;
	for pixel_size < 1 && mip_level < (MIP_COUNT - 1) {
		pixel_size += pixel_size;
		mip_level += 1;
		mip_width >>= 1;
		mip_height >>= 1;
	}

	drawBitmapToScale(walls_mips[mip_level], &walls);
	drawBitmapToScale(floor_mips[mip_level], &floor);
	drawBitmapToScale(ceiling_mips[mip_level], &ceiling);
}

panMiniMap :: inline proc(using mm: ^MiniMap) {
	panned = true;
	movement: vec2 = {
		f32(mouse_pos_diff.x), 
		f32(mouse_pos_diff.y)
	};
	pan += movement;
	offset += movement;
	
	moveMiniMap(mm, movement);

    mouse_pos_diff.x = 0;
    mouse_pos_diff.y = 0;
    mouse_moved = false;
}

drawMiniMap :: inline proc(using mm: ^MiniMap) {
	clearBitmap(&canvas, true);

	drawBitmap(&floor, &canvas, i32(top_left.x), i32(top_left.y));
	drawBitmap(&walls, &canvas, i32(top_left.x), i32(top_left.y));
	// for pixel in &canvas.all_pixels do pixel.opacity = 254;

	// for row, y in &tile_map.tiles do
	// 	for tile, x in &row {
	// 		using tile.minimap_space;
	// 		if x_range.min >= bitmap.width ||
	// 		   y_range.min >= bitmap.height ||
	// 		   x_range.max < 0 ||
	// 		   y_range.max < 0 do
	// 		   continue;

	// 		texture = tile.is_full ? &textures[tile.texture_id] : floor_texture;

	// 		start_y := max(y_range.min, 0);
	// 		end_y   := min(y_range.max, bitmap.height);
	// 		pixel_offset = bitmap.width * start_y + x_range.min;
	// 		for y in y_range.min..<y_range.max {
	// 			if !(y < 0 || y >= bitmap.height) do 
	// 				for x in x_range.min..<x_range.max do
	// 					if !(x < 0 || x >= bitmap.width || (pixel_offset + x) < 0) do
	// 						sampleBitmap(texture, 0.5, 0.5, &all_pixels[pixel_offset + x]); 

	// 			pixel_offset += bitmap.width;
	// 		}

	// 		if tile.is_full do 
	// 			fillRect(&bitmap,
	// 					 bounds.min, 
	// 				     bounds.max, 
	// 				     tile_color);
	// 	}
	
	padding: vec2 = {1, 1};

	clearBitmap(&line_of_sight_canvas, true);
	for ray in &rays do drawLine(&line_of_sight_canvas, offset, offset + (ray.hit.position - origin^)*scale_factor, ray_color, 64);
	drawBitmap(&line_of_sight_canvas, &canvas);
		
	// if is_debug_visible do
	// 	for edge in &tile_map.edges {
	// 		using edge.minimap;
	// 		drawLine(&bitmap, from^, to^, edge.is_facing_forward ? front_edge_color : back_edge_color);
	// 		fillRect(&bitmap, from^ - padding, from^ + padding, vertex_color);
	// 		fillRect(&bitmap, to^   - padding, to^   + padding, vertex_color);
	// 	}
	fillCircle(&canvas, offset, max(scale_factor * body_radius, 1), center_color);
}
