package application

MIN_MINIMAP_SIZE :: 64;
MID_MINIMAP_SIZE :: 128;
MAX_MINIMAP_SIZE :: 256;

MIN_MINIMAP_ZOOM_AMOUNT :: -10;
MAX_MINIMAP_ZOOM_AMOUNT :: +10;

MiniMap :: struct {
	using bitmap: Bitmap,
	bits: ^[MAX_MINIMAP_SIZE*MAX_MINIMAP_SIZE]u32,

	bounds: Bounds2Di,
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

	resized,
	zoomed, 
	panned,
	toggled,
	is_visible,
	is_debug_visible: bool,

	zoom_amount,
	zoom_factor,

	resize_amount,
	resize_factor,

	size_factor,
	scale_factor: f32
}

initMiniMap :: proc(using mm: ^MiniMap, tm: ^TileMap, origin_position: ^vec2) {
	tile_map = tm;
	pos = &bounds.min;
	origin = origin_position;

	is_visible = true;
	
	zoom_amount = 0;
	zoom_factor = 1;

	center_color = RED;
	ray_color = YELLOW;
	front_edge_color = WHITE;
	back_edge_color = GREY;
	vertex_color = GREEN;
	tile_color = BLUE;

	bits = new([MAX_MINIMAP_SIZE*MAX_MINIMAP_SIZE]u32);
	resizeMiniMap(mm, MID_MINIMAP_SIZE, MID_MINIMAP_SIZE);
}

resizeMiniMapByMouseWheel :: inline proc(using mm: ^MiniMap) {
    resize_amount += mouse_wheel_scroll_amount;
         if resize_amount > +1 do resize_factor = 0.1 * resize_amount;
    else if resize_amount < -1 do resize_factor = -0.1 / resize_amount;
    else                       do resize_factor = 1;

	// print(resize_factor);
    mouse_wheel_scroll_amount = 0;
    resized = true;
	resizeMiniMap(mm, i32(resize_factor * MID_MINIMAP_SIZE), i32(resize_factor * MID_MINIMAP_SIZE));
}

resizeMiniMap :: inline proc(using mm: ^MiniMap, new_width, new_height: i32) {
	print(new_width);
	initBitmap(&bitmap, 
		min(max(new_width, MIN_MINIMAP_SIZE), MAX_MINIMAP_SIZE), 
		min(max(new_height, MIN_MINIMAP_SIZE), MAX_MINIMAP_SIZE), 
		bits^[:]
	);
	resetMiniMapSize(mm);

	bounds.max.x = bounds.min.x + width;
	bounds.max.y = bounds.min.y + height;
}

resetMiniMapSize :: proc(using mm: ^MiniMap) {
	size_factor = f32(width) / MID_MINIMAP_SIZE;
	scale_factor = size_factor * zoom_factor;
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

zoomMiniMap :: inline proc(using mm: ^MiniMap) {
    zoom_amount += mouse_wheel_scroll_amount;
    zoom_amount = min(max(zoom_amount, MIN_MINIMAP_ZOOM_AMOUNT), MAX_MINIMAP_ZOOM_AMOUNT);

         if zoom_amount > +1 do zoom_factor = zoom_amount;
    else if zoom_amount < -1 do zoom_factor = -1 / zoom_amount;
    else                     do zoom_factor = 1;

    mouse_wheel_scroll_amount = 0;
    zoomed = true;

	resetMiniMapSize(mm);
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
	fillCircle(&bitmap, offset, max(zoom_factor * (body_radius + 0.15), 1), center_color);

	zoomed = false;
}
