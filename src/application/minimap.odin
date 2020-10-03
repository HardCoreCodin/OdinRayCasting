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

MinimapTilesBitmap :: struct {
	using bitmap: Bitmap,
	bits: ^[MINIMAP__TILES_BITMAP_PIXEL_COUNT]u32
};

initMinimapTilesBitmap :: proc(using mmtbm: ^MinimapTilesBitmap) {
	bits = new([MINIMAP__TILES_BITMAP_PIXEL_COUNT]u32);
	initBitmap(&bitmap, MINIMAP__TILES_BITMAP_WIDTH, MINIMAP__TILES_BITMAP_HEIGHT, bits^[:]);
	clearBitmap(&bitmap);
}

MinimapCanvasBitmap :: struct {
	using bitmap: Bitmap,
	bits: ^[MINIMAP__CANVAS_BITMAP_PIXEL_COUNT]u32
};

initMinimapCanvasBitmap :: proc(using mmcbm: ^MinimapCanvasBitmap, transparent: bool = false) {
	bits = new([MINIMAP__CANVAS_BITMAP_PIXEL_COUNT]u32);
	initBitmap(&bitmap, MINIMAP__MAX_SIZE, MINIMAP__MAX_SIZE, bits^[:]);
	clearBitmap(&bitmap, transparent);
}

MiniMap :: struct {
	using canvas: MinimapCanvasBitmap,
	debug_canvas: MinimapCanvasBitmap,
	walls_bitmap,
	floor_bitmap,
	ceiling_bitmap: MinimapTilesBitmap,

	bounds, world_bounds: Bounds2Di,
	pos: ^vec2i,
	origin: ^vec2,

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

	panned,
	toggled,
	is_visible,
	is_debug_visible: bool,

	scale_factor: f32
}

initMiniMap :: proc(using mm: ^MiniMap, tm: ^TileMap, origin_position: ^vec2) {
	tile_map = tm;
	pos = &world_bounds.min;
	origin = origin_position;

	is_visible = true;
	
	initAmountAndFactor(&zoom,   MINIMAP__MIN_ZOOM_FACTOR,   MINIMAP__MAX_ZOOM_FACTOR, 4);
	initAmountAndFactor(&resize, MINIMAP__MIN_RESIZE_FACTOR, MINIMAP__MAX_RESIZE_FACTOR);

	center_color = RED;
	ray_color = YELLOW;
	front_edge_color = WHITE;
	back_edge_color = GREY;
	vertex_color = GREEN;
	tile_color = BLUE;

	initMinimapTilesBitmap(&walls_bitmap);
	initMinimapTilesBitmap(&floor_bitmap);
	initMinimapTilesBitmap(&ceiling_bitmap);

	initMinimapCanvasBitmap(&canvas);
	initMinimapCanvasBitmap(&debug_canvas, true);

	resizeMiniMap(mm, MINIMAP__MID_SIZE);
}

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
	size = clamp(new_size, MINIMAP__MIN_SIZE, MINIMAP__MAX_SIZE);
	initBitmap(&bitmap, size, size, bits^[:]);
	resetMiniMapSize(mm);
	bounds.max.x = bounds.min.x + width;
	bounds.max.y = bounds.min.y + height;
	world_bounds.max.x = world_bounds.min.x + width;
	world_bounds.max.y = world_bounds.min.y + height;
}

resetMiniMapSize :: proc(using mm: ^MiniMap) {
	resize.factor = f32(width) / MINIMAP__MID_SIZE;
	scale_factor = resize.factor * zoom.factor;
	center.x = f32(width) / 2;
	center.y = f32(height) / 2;
	offset = center + pan;	

	scaleMiniMap(mm);

	// print(scale_factor);
	pixel_size := scale_factor / TEXTURE_WIDTH;
	new_width := i32(f32(wall_tiles_texture.width) * pixel_size); 
	new_height := i32(f32(wall_tiles_texture.height) * pixel_size);

	resizeBitmap(&walls_bitmap.bitmap, new_width, new_height);
	resizeBitmap(&floor_bitmap.bitmap, new_width, new_height);
	resizeBitmap(&ceiling_bitmap.bitmap, new_width, new_height);

	clearBitmap(&walls_bitmap.bitmap, true);
	clearBitmap(&floor_bitmap.bitmap);
	clearBitmap(&ceiling_bitmap.bitmap);

	drawBitmapToScale(&wall_tiles_texture, &walls_bitmap.bitmap);
	drawBitmapToScale(&floor_tiles_texture, &floor_bitmap.bitmap);
	drawBitmapToScale(&ceiling_tiles_texture, &ceiling_bitmap.bitmap);
}

scaleMiniMap :: inline proc(using mm: ^MiniMap) {
	for vertex, i in &tile_map.vertices_in_local_space do tile_map.vertices_in_minimap_space[i] = (vertex * scale_factor) + offset;
	for row in &tile_map.tiles {
		for tile in &row {
			using tile.minimap_space;
			bounds.min.x = f32(tile.bounds.min.x);
			bounds.min.y = f32(tile.bounds.min.y);
			bounds.max.x = f32(tile.bounds.max.x);
			bounds.max.y = f32(tile.bounds.max.y);
			bounds.min -= origin^;
			bounds.max -= origin^;
			bounds.min *= scale_factor;
			bounds.max *= scale_factor;
			bounds.min += offset;
			bounds.max += offset;	
			x_range.min = i32(bounds.min.x);
			x_range.max = i32(bounds.max.x);
			y_range.min = i32(bounds.min.y);
			y_range.max = i32(bounds.max.y);
			x_range.range = x_range.max - x_range.min;
			y_range.range = y_range.max - y_range.min;
		}
	}
}

moveMiniMap :: inline proc(using mm: ^MiniMap, movement: vec2) {
	for vertex, i in &tile_map.vertices_in_local_space do tile_map.vertices_in_minimap_space[i] += movement;
	for row in &tile_map.tiles {
		for tile in &row {
			using tile.minimap_space;
			bounds.min += movement;
			bounds.max += movement;
			x_range.min = i32(bounds.min.x);
			x_range.max = i32(bounds.max.x);
			y_range.min = i32(bounds.min.y);
			y_range.max = i32(bounds.max.y);
			x_range.range = x_range.max - x_range.min;
			y_range.range = y_range.max - y_range.min;
		}	
	}
}

panMiniMap :: inline proc(using mm: ^MiniMap) {
	panned = true;
	movement: vec2 = {f32(mouse_pos_diff.x), f32(mouse_pos_diff.y)};
	pan += movement;
	offset += movement;
	moveMiniMap(mm, movement);
    mouse_pos_diff.x = 0;
    mouse_pos_diff.y = 0;
    mouse_moved = false;
}

drawMiniMap :: inline proc(using mm: ^MiniMap) {
	fillBounds2Di(&bitmap, &bounds, BLACK, 0);

	texture: ^Bitmap;
	pixel_offset: i32;

	p: vec2i = {
		i32(tile_map.all_tiles[0].minimap_space.bounds.min.x),
		i32(tile_map.all_tiles[0].minimap_space.bounds.min.y)
	};
	drawBitmap(&floor_bitmap, &canvas, p);
	drawBitmap(&walls_bitmap, &canvas, p);
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

	clearBitmap(&debug_canvas.bitmap, true);
	for ray in &rays do drawLine(&debug_canvas.bitmap, offset, offset + (ray.hit.position - origin^)*scale_factor, ray_color, 64);
	p = 0;
	drawBitmap(&debug_canvas.bitmap, &canvas, p);
		
	if is_debug_visible do
		for edge in &tile_map.edges {
			using edge.minimap;
			drawLine(&bitmap, from^, to^, edge.is_facing_forward ? front_edge_color : back_edge_color);
			fillRect(&bitmap, from^ - padding, from^ + padding, vertex_color);
			fillRect(&bitmap, to^   - padding, to^   + padding, vertex_color);
		}
	fillCircle(&bitmap, offset, max(scale_factor * body_radius, 1), center_color);
}
