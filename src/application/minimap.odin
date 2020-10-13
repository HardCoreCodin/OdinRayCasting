package application

MINIMAP__MIN_SIZE :: 64;
MINIMAP__MID_SIZE :: 128;
MINIMAP__MAX_SIZE :: 256;
MINIMAP__MIN_ZOOM_FACTOR  :: 0.5;
MINIMAP__MAX_ZOOM_FACTOR  :: 20;
MINIMAP__MIN_RESIZE_FACTOR :: 0.5;
MINIMAP__MAX_RESIZE_FACTOR :: 2;
MINIMAP__MAX_SCALE_FACTOR :: MINIMAP__MAX_ZOOM_FACTOR * MINIMAP__MAX_RESIZE_FACTOR;
MINIMAP__TILES_BITMAP_WIDTH       :: MINIMAP__MAX_SCALE_FACTOR * MAX_TILE_MAP_WIDTH;
MINIMAP__TILES_BITMAP_HEIGHT      :: MINIMAP__MAX_SCALE_FACTOR * MAX_TILE_MAP_HEIGHT;
MINIMAP__TILES_BITMAP_PIXEL_COUNT :: MINIMAP__TILES_BITMAP_WIDTH * MINIMAP__TILES_BITMAP_HEIGHT;
MINIMAP__CANVAS_BITMAP_PIXEL_COUNT :: MINIMAP__MAX_SIZE * MINIMAP__MAX_SIZE;

all_minimap_bitmap_pixels: [4 * MINIMAP__TILES_BITMAP_PIXEL_COUNT]Pixel;
// all_scaled_textures_pixels: [8 * 64 * 64]Pixel;
// scaled_textures: [8]Bitmap;

MiniMap :: struct {
	size: struct { pixel, scaled, scaled_tile, tile, tile_map: Size2Df},
	canvas_pixels: [MINIMAP__CANVAS_BITMAP_PIXEL_COUNT]Pixel,

	walls, scaled_walls,
	floor, scaled_floor,
	ceiling, scaled_ceiling,
	view,
	canvas: Bitmap,
	
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
	ray_color: Pixel,
 
 	zoom, 
 	resize: AmountAndFactor,

	mip_count,
	mip_level,
	texture_count: i32,
	scale_factor: f32,

	panned,
	toggled,
	is_visible,
	is_debug_visible: bool
}
initMiniMap :: proc(using mm: ^MiniMap, tm: ^TileMap, origin_position: ^vec2) {
	tile_map = tm;
	origin = origin_position;
	screen_position = &screen_bounds.min;

	size.tile.width = f32(textures[0].bitmaps[0].width);
	size.tile.height = f32(textures[0].bitmaps[0].height);
	size.tile_map.width = f32(tile_map.width);
	size.tile_map.height = f32(tile_map.height);
	
	tile_size := i32(size.tile.width * size.tile.height);

	mip_count = i32(len(textures[0].bitmaps));
	is_visible = true;
	
	initAmountAndFactor(&zoom,   MINIMAP__MIN_ZOOM_FACTOR,   MINIMAP__MAX_ZOOM_FACTOR, 4);
	initAmountAndFactor(&resize, MINIMAP__MIN_RESIZE_FACTOR, MINIMAP__MAX_RESIZE_FACTOR);

	center_color = RED;
	ray_color = YELLOW;
	ray_color.a = 64;
	front_edge_color = WHITE;
	back_edge_color = GREY;
	vertex_color = GREEN;
	tile_color = BLUE;


	texture_count = i32(len(textures));
	texture_pixels_count := texture_count * tile_size;

	// for scaled_texture, t in &scaled_textures do 
	// 	initGrid(&scaled_texture, i32(size.tile.width), i32(size.tile.height), all_scaled_textures_pixels[i32(t)*tile_size:(i32(t)+1)*tile_size]);

	walls_pixels   := all_minimap_bitmap_pixels[MINIMAP__TILES_BITMAP_PIXEL_COUNT*0:MINIMAP__TILES_BITMAP_PIXEL_COUNT*1];
	floor_pixels   := all_minimap_bitmap_pixels[MINIMAP__TILES_BITMAP_PIXEL_COUNT*1:MINIMAP__TILES_BITMAP_PIXEL_COUNT*2];
	ceiling_pixels := all_minimap_bitmap_pixels[MINIMAP__TILES_BITMAP_PIXEL_COUNT*2:MINIMAP__TILES_BITMAP_PIXEL_COUNT*3];
	view_pixels    := all_minimap_bitmap_pixels[MINIMAP__TILES_BITMAP_PIXEL_COUNT*3:MINIMAP__TILES_BITMAP_PIXEL_COUNT*4];

	initGrid(&canvas, MINIMAP__MAX_SIZE, MINIMAP__MAX_SIZE, canvas_pixels[:]);
	initGrid(&view,   MINIMAP__MAX_SIZE, MINIMAP__MAX_SIZE, view_pixels);
	
	initGrid(&walls  , MINIMAP__TILES_BITMAP_WIDTH, MINIMAP__TILES_BITMAP_HEIGHT, walls_pixels);
	initGrid(&floor  , MINIMAP__TILES_BITMAP_WIDTH, MINIMAP__TILES_BITMAP_HEIGHT, floor_pixels);
	initGrid(&ceiling, MINIMAP__TILES_BITMAP_WIDTH, MINIMAP__TILES_BITMAP_HEIGHT, ceiling_pixels);	

	clearBitmap(&canvas);
	clearBitmap(&view, true);

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
	s := clamp(new_size, MINIMAP__MIN_SIZE, MINIMAP__MAX_SIZE);
	resizeGrid(&canvas, s, s);
	resizeGrid(&view, s, s);
	
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

	size.pixel.width = scale_factor / size.tile.width;
	size.pixel.height = scale_factor / size.tile.height;
	size.scaled_tile.width  = size.tile.width * size.pixel.width;
	size.scaled_tile.height = size.tile.height * size.pixel.height;
	size.scaled.width  = size.scaled_tile.width * size.tile_map.width;
	size.scaled.height = size.scaled_tile.width * size.tile_map.height;

	w := i32(size.scaled.width);
	h := i32(size.scaled.height);
	resizeGrid(&walls,   w, h);
	resizeGrid(&floor,   w, h);
	resizeGrid(&ceiling, w, h);
	resizeGrid(&view,    w, h);

	mip_level = 0;
	mip_pixel_width: f32 = 1;

	for mip_pixel_width > size.pixel.width && mip_level < (mip_count - 1) {
		mip_pixel_width /= 2;
		mip_level += 1;
	}
	// mip_level -= 1;

	// for scaled_texture, t in &scaled_textures {
	// 	resizeGrid(&scaled_texture, i32(size.scaled_tile.width), i32(size.scaled_tile.height));
	// 	scaleTexture(textures[t].samples[mip_level], &scaled_texture);
	// }

	drawMiniMapTextures(mm);
	drawMiniMapPlayerView(mm);
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

drawMiniMapPlayerView :: proc(using mm: ^MiniMap) {
	clearBitmap(&view, true);
	
	pos := origin^ * scale_factor;

	for ray in &rays do 
		drawLine(&view, pos, pos + (ray.hit.position - origin^) * scale_factor, &ray_color);
}

drawMiniMapTextures :: proc(using mm: ^MiniMap) {
	clearBitmap(&walls, true);
	clearBitmap(&floor);
	// clearBitmap(&ceiling);
	// mip_level = 1;

	
  //   column_id,
  //   current_row_is_full: u32;

  //   texture_ids_row: ^[]TileTextureIDs;
  //   tile_texture_ids: ^TileTextureIDs;

  //   tile_width := i32(size.scaled_tile.width);
  //   tile_height := i32(size.scaled_tile.height);
    
  //   pos: vec2i;

  //   for y in 0..<tile_map.height {
  //   	pos.x = 0;

		// column_id = 1;
		// current_row_is_full = tile_map.is_full[y]; 
		// texture_ids_row = &tile_map.texture_ids.cells[y];

		// for x in 0..<tile_map.width {
		// 	tile_texture_ids = &texture_ids_row[x];

  //       	if (current_row_is_full & column_id) != 0 do
  //       		drawBitmap(&scaled_textures[tile_texture_ids.wall], &walls, pos.x, pos.y);

  //       	drawBitmap(&scaled_textures[tile_texture_ids.floor], &floor, pos.x, pos.y);
        	
		// 	column_id <<= 1;
		// 	pos.x += tile_width;			
  //       }
  //       pos.y += tile_height;
  //   }
    
    tile_index: vec2i;
    column_id: u32 = 1;
	
	texture_ids_row := &tile_map.texture_ids.cells[0];
	tile_texture_ids := texture_ids_row[0];

	current_row_is_full := tile_map.is_full[0];
	current_tile_is_full: bool = true;

	current_wall_texture := textures[tile_texture_ids.wall].samples[mip_level];
	current_floor_texture:= textures[tile_texture_ids.floor].samples[mip_level];
	// current_ceiling_texture: ^Samples = textures[tile_texture_ids.ceiling].samples[mip_level];

	u, v: f32;
	u_step := 1 / size.scaled_tile.width;
	v_step := 1 / size.scaled_tile.height;

	wall_pixel_row: ^[]Pixel;
    
    for floor_pixel_row, y in &floor.cells {
    	wall_pixel_row = &walls.cells[y];
    
    	for floor_pixel, x in &floor_pixel_row {
    		sample(current_floor_texture, u, v, &floor_pixel);
    		if current_tile_is_full do
    			sample(current_wall_texture, u, v, &wall_pixel_row[x]);	

    		u += u_step;
    		if u >= 1 && i32(x) < (floor.width - 1) {
	    		u -= 1;

	    		tile_index.x += 1;
	    		tile_texture_ids = texture_ids_row[tile_index.x];

	    		column_id <<= 1;
	    		current_tile_is_full = (current_row_is_full & column_id) != 0;
				current_floor_texture = textures[tile_texture_ids.floor].samples[mip_level];
	    		if current_tile_is_full do
	    			current_wall_texture = textures[tile_texture_ids.wall].samples[mip_level];
	    	}
    	}

    	tile_index.x = 0;
    	u = 0;
    	v += v_step;
    	if v >= 1 && i32(y) < (floor.height - 1) {
    		v -= 1;
    		
    		tile_index.y += 1;
    		current_row_is_full = tile_map.is_full[tile_index.y];
    		
    		texture_ids_row = &tile_map.texture_ids.cells[tile_index.y];
    	}

    	tile_texture_ids = texture_ids_row[0];

		column_id = 1;
		current_tile_is_full = (current_row_is_full & column_id) != 0;			
		current_floor_texture = textures[tile_texture_ids.floor].samples[mip_level];
		if current_tile_is_full do
			current_wall_texture = textures[tile_texture_ids.wall].samples[mip_level];
    }
}

drawMiniMap :: inline proc(using mm: ^MiniMap) {
	clearBitmap(&canvas);

	x := i32(top_left.x);
	y := i32(top_left.y);
	
	drawBitmap(&floor, &canvas, x, y);
	drawBitmap(&walls, &canvas, x, y);
	drawBitmap(&view,  &canvas, x, y);
	
	padding: vec2 = {1, 1};		
	// if is_debug_visible do
	// 	for edge in &tile_map.edges {
	// 		using edge.minimap;
	// 		drawLine(&bitmap, from^, to^, edge.is_facing_forward ? front_edge_color : back_edge_color);
	// 		fillRect(&bitmap, from^ - padding, from^ + padding, vertex_color);
	// 		fillRect(&bitmap, to^   - padding, to^   + padding, vertex_color);
	// 	}
	fillCircle(&canvas, offset, max(scale_factor * body_radius, 1), &center_color);
}
