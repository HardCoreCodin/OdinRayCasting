package application

MINIMAP__MIN_SIZE :: 64;
MINIMAP__MID_SIZE :: 128;
MINIMAP__MAX_SIZE :: 256;
MINIMAP__MIN_ZOOM_FACTOR  ::  0.1;
MINIMAP__MAX_ZOOM_FACTOR  :: 10.0;
MINIMAP__MIN_RESIZE_FACTOR :: 0.5;
MINIMAP__MAX_RESIZE_FACTOR :: 2.0;

MiniMap :: struct {
	using bitmap: Bitmap,
	bits: ^[MINIMAP__MAX_SIZE*MINIMAP__MAX_SIZE]u32,

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

	bits = new([MINIMAP__MAX_SIZE*MINIMAP__MAX_SIZE]u32);
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
}

scaleMiniMap :: inline proc(using mm: ^MiniMap) {
	for vertex, i in &tile_map.vertices_in_local_space do tile_map.vertices_in_minimap_space[i] = (vertex * scale_factor) + offset;
	for row in &tile_map.tiles {
		for tile in &row {
			using tile;
			using bounds_in_minimap_space;
			min.x = f32(bounds.min.x);
			min.y = f32(bounds.min.y);
			max.x = f32(bounds.max.x);
			max.y = f32(bounds.max.y);
			min -= origin^;
			max -= origin^;
			min *= scale_factor;
			max *= scale_factor;
			min += offset;
			max += offset;	
		}
	}
}

moveMiniMap :: inline proc(using mm: ^MiniMap, movement: vec2) {
	for vertex, i in &tile_map.vertices_in_local_space do tile_map.vertices_in_minimap_space[i] += movement;
	for row in &tile_map.tiles {
		for tile in &row {
			tile.bounds_in_minimap_space.min += movement;
			tile.bounds_in_minimap_space.max += movement;
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
	for row, y in &tile_map.tiles do
		for tile, x in &row do
			if tile.is_full do 
				fillRect(&bitmap,
						 tile.bounds_in_minimap_space.min, 
					     tile.bounds_in_minimap_space.max, 
					     tile_color);
	
	padding: vec2 = {1, 1};

	for ray in &rays do drawLine(&bitmap, offset, offset + (ray.hit.position - origin^)*scale_factor, ray_color, 64);
		
	if is_debug_visible do
		for edge in &tile_map.edges {
			using edge.minimap;
			drawLine(&bitmap, from^, to^, edge.is_facing_forward ? front_edge_color : back_edge_color);
			fillRect(&bitmap, from^ - padding, from^ + padding, vertex_color);
			fillRect(&bitmap, to^   - padding, to^   + padding, vertex_color);
		}
	fillCircle(&bitmap, offset, max(scale_factor * body_radius, 1), center_color);
}
