package application

INITIAL_WIDTH  :: 640;
INITIAL_HEIGHT :: 480;

import "core:fmt"
print :: fmt.println;

TEXTURE_COUNT :: 8;
TEXTURE_WIDTH :: 64;
TEXTURE_HEIGHT :: 64;
TEXTURE_SIZE :: TEXTURE_WIDTH * TEXTURE_HEIGHT;

texture_files: [TEXTURE_COUNT][]u8= {
	#load("../../assets/bluestone.bmp"),
	#load("../../assets/colorstone.bmp"),
	#load("../../assets/eagle.bmp"),
	#load("../../assets/graystone.bmp"),
	#load("../../assets/mossystone.bmp"),
	#load("../../assets/purplestone.bmp"),
	#load("../../assets/redbrick.bmp"),
	#load("../../assets/wood.bmp")
};
texture_bitmaps_data: [TEXTURE_COUNT][TEXTURE_SIZE]u32;
textures: [TEXTURE_COUNT]Bitmap;

mini_map: MiniMap;
tile_map: TileMap;

TILE_MAP_ASCII_GRID := `
22222222222111111111111111111111
2_________2____________________1
2__2___22_2____________________1
222222_2222____________________1
2__2_____22____________________1
2____22___2____________________1
2_____2_222____________________1
2_22222__22____________________1
2_________2____________________1
22222222222____________________1
1______________________________1
1___________22222223___________1
1__________________3___________1
1__________________3___________1
1__________________3___________1
1__________________34444444____1
1______________________________1
1______________________________1
1______________________________1
1______________________________1
1______________________________1
1______________________________1
1______________________________1
1______________________________1
1______________________________1
1______________________________1
1______________________________1
1______________________________1
1______________________________1
1______________________________1
1______________________________1
11111111111111111111111111111111
`;

SPEED :: 240;
MOVEMENT_SPEED :: 0.04;
TURNING_SPEED :: 0.01;
TARGET_FPS :: 60;
UPDATE_INTERVAL: u64;

is_running: bool = true;
class_name :: "Application";

camera: Camera2D;
camera_controller: CameraController2D;

body_radius: f32 = 0.3;
next_tile: ^Tile;
tile_map_changed: bool;

frame_buffer: FrameBuffer;

resize :: proc(new_width, new_height: i32) {
	resizeFrameBuffer(new_width, new_height, &frame_buffer);
	onResize();
	update();
	render();
}

mouseOnMiniMap :: inline proc() -> bool do return mini_map.is_visible && inBounds(mini_map.screen_bounds, mouse_pos);

update :: proc() {
	using frame_buffer;
	using update_timer;
	using camera.xform;
	using camera_controller;

	mini_map.panned = false;
	mini_map.zoom.changed = false;
	mini_map.resize.changed = false;
	mini_map.toggled = mini_map.is_visible != toggle1 || mini_map.is_debug_visible != toggle2;
	mini_map.is_visible = toggle1;
	mini_map.is_debug_visible = toggle2;

	ticks_after = getTicks();
	ticks_diff = ticks_after - ticks_before;
	delta_time = f32(f64(ticks_diff) * seconds_per_tick);

	if mouse_moved {
		if mouse_is_captured do onMouseMoved(&camera_controller);
		else if !mouse_is_captured && middle_mouse_button.is_pressed && mouseOnMiniMap() {
			if ctrl_is_pressed {
				mini_map.screen_bounds.min += mouse_pos_diff;
				mini_map.screen_bounds.max += mouse_pos_diff;
				mouse_pos_diff.x = 0;
			    mouse_pos_diff.y = 0;
			    mouse_moved = false;
			} else do panMiniMap(&mini_map);
		}
	}
	
	onUpdate2D(&camera_controller);
	if moved { // Detect collisions:
		if movement.x > 0 {
			next_tile = &tile_map.tiles[i32(position.y)][i32(position.x + body_radius)];
			if next_tile.is_full do position.x = f32(next_tile.bounds.left) - body_radius;
		} else if movement.x < 0 {
			next_tile = &tile_map.tiles[i32(position.y)][i32(position.x - body_radius)];
			if next_tile.is_full do position.x = f32(next_tile.bounds.right) + body_radius;
		}
		
		if movement.y < 0 {
			next_tile = &tile_map.tiles[i32(position.y - body_radius)][i32(position.x)];
			if next_tile.is_full do position.y = f32(next_tile.bounds.bottom) + body_radius;
		} else if movement.y > 0 {
			next_tile = &tile_map.tiles[i32(position.y + body_radius)][i32(position.x)];
			if next_tile.is_full do position.y = f32(next_tile.bounds.top) - body_radius;
		}

		movement = position - old_position;
	}

	tile_map_changed = false;
	if !mouse_is_captured {
		if (left_mouse_button.is_pressed || 
			right_mouse_button.is_pressed) &&
			mouseOnMiniMap() {
			tile_coords := mouse_pos;
			tile_coords -= mini_map.screen_position^;
			tile_pos: vec2 = {f32(tile_coords.x), f32(tile_coords.y)};
			tile_pos -= mini_map.offset;
			tile_pos /= mini_map.scale_factor;
			tile_pos += position;
			tile_coords = {i32(tile_pos.x), i32(tile_pos.y)};
			if !(tile_coords.x == i32(position.x) && 
			     tile_coords.y == i32(position.y)) {
				tile_map.tiles[tile_coords.y][tile_coords.x].is_full = left_mouse_button.is_pressed;
				tile_map_changed = true;
			}
		}
	}

	if tile_map_changed {
		generateTileMapEdges(&tile_map);
		drawWallTilesTexture(&tile_map);
		drawBitmapToScale(&wall_tiles_texture, &mini_map.walls_bitmap.bitmap);
	}
	if tile_map_changed || moved {
		moveTileMap(&tile_map, position);
		moveMiniMap(&mini_map, movement * -mini_map.scale_factor);
	}
	if mouse_wheel_scrolled {
		if mouse_is_captured {
			onMouseScrolled(&camera_controller);
			onFocalLengthChanged();
		} else if mouseOnMiniMap() {
			if ctrl_is_pressed do resizeMiniMapByMouseWheel(&mini_map);
			else               do zoomMiniMap(&mini_map);
		} else do mouse_wheel_scroll_amount = 0;
	}
	if turned || zoomed do generateRays();
	if tile_map_changed || moved || turned || zoomed do castRays(&tile_map);
	if tile_map_changed || moved || turned || zoomed || 
	   mini_map.resize.changed || 
	   mini_map.zoom.changed || 
	   mini_map.panned || 
	   mini_map.toggled do drawMiniMap(&mini_map);

	ticks_before = getTicks();
}

render :: proc() {
	using render_timer;
	using camera.xform;
	using frame_buffer;

	ticks_before = getTicks();

	// clearBitmap(&bitmap);
	// for pixel in &all_pixels do pixel.color = BLACK;
	// fillBounds2Di(&bitmap, &bounds, BLACK, 0);
	drawWalls(&camera);
	if mini_map.is_visible {
		drawBitmap(&mini_map.canvas.bitmap, &bitmap, mini_map.screen_position.x, mini_map.screen_position.y);
		drawRect(&bitmap, &mini_map.screen_bounds, WHITE);
	}

	ticks_after = getTicks();
	accumulateTimer(&render_timer);

	if (ticks_after - ticks_of_last_report) >= ticks_per_second {
		print("FPS:", 1 / (seconds_per_tick * (
					f64(accumulated_ticks) / 
					f64(accumulated_frame_count)
				)));
		// print(
		// 	"Ray-Casting",
		// 	u64(
		// 		microseconds_per_tick * (
		// 			f64(accumulated_ticks) / 
		// 			f64(accumulated_frame_count)
		// 		)
		// 	),
		// 	"μs/f"
		// );

		accumulated_ticks = 0;
		accumulated_frame_count = 0;
		ticks_of_last_report = ticks_after;
	}
}

initApplication :: proc(platformGetTicks: GetTicks, platformTicksPerSecond: u64) {
	using camera.xform;
	position = 20;
	toggle1 = true;
	
	initTimers(platformGetTicks, platformTicksPerSecond);
	initFrameBuffer(&frame_buffer);

	initCamera(&camera);
	initCameraController(&camera_controller.controller);
	camera_controller.camera = &camera;
	
	initTileMap(&tile_map);
	
	for texture, i in &textures do readBitmapFromFile(texture_files[i], &texture, texture_bitmaps_data[i][:]);
	readTileMapFromASCIIgrid(&tile_map, &TILE_MAP_ASCII_GRID);
	generateTileMapEdges(&tile_map);
	moveTileMap(&tile_map, position);

	initRayCast();
	drawWallTilesTexture(&tile_map);
	initMiniMap(&mini_map, &tile_map, &position);
	drawMiniMap(&mini_map);
	
	UPDATE_INTERVAL = ticks_per_second / TARGET_FPS;
}