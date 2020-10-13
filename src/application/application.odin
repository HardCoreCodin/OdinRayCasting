package application

FRAME_BUFFER__INITIAL_WIDTH  :: 640;
FRAME_BUFFER__INITIAL_HEIGHT :: 480;
FRAME_BUFFER__MAX_WIDTH  :: 3840;
FRAME_BUFFER__MAX_HEIGHT :: 2160;
FRAME_BUFFER__MAX_SIZE   :: FRAME_BUFFER__MAX_WIDTH * FRAME_BUFFER__MAX_HEIGHT;

import "core:fmt"
print :: fmt.println;

mini_map: MiniMap;
tile_map: TileMap;

WALLS := `
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

FLOOR := `
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
77777777777777777777777777777777
`;

CEILING := `
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
33333333333333333333333333333333
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

next_pos_f: f32;
next_pos_i: i32;
body_radius: f32 = 0.3;
next_tile: ^Tile;
tile_map_changed: bool;

frame_buffer_bits: [FRAME_BUFFER__MAX_SIZE]u32;
frame_buffer: FrameBuffer;

resize :: proc(new_width, new_height: i32) {
	initGrid(&frame_buffer, new_width, new_height, transmute([]FrameBufferPixel)(frame_buffer_bits[:]));
	
	onResize();
	update();
	render();
}

mouseOnMiniMap :: inline proc() -> bool do return mini_map.is_visible && inBounds(mini_map.screen_bounds, mouse_pos);

update :: proc() {
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
		else if middle_mouse_button.is_pressed {
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
			next_pos_f = position.x + body_radius;
			next_pos_i = i32(next_pos_f);
			if (tile_map.is_full[u8(position.y)] & (1 << u32(next_pos_i))) != 0 do 
				position.x = f32(next_pos_i) - body_radius;
		} else if movement.x < 0 {
			next_pos_f = position.x - body_radius;
			next_pos_i = i32(next_pos_f);
			if (tile_map.is_full[u8(position.y)] & (1 << u32(next_pos_i))) != 0 do 
				position.x = f32(next_pos_i) + 1 + body_radius;
		}
		
		if movement.y < 0 {
			next_pos_f = position.y - body_radius;
			next_pos_i = i32(next_pos_f);
			if (tile_map.is_full[next_pos_i] & (1 << u8(position.x))) != 0 do 
				position.y = f32(next_pos_i) + 1 + body_radius;
		} else if movement.y > 0 {
			next_pos_f = position.y + body_radius;
			next_pos_i = i32(next_pos_f);
			if (tile_map.is_full[next_pos_i] & (1 << u8(position.x))) != 0 do 
				position.y = f32(next_pos_i) - body_radius;
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
				if left_mouse_button.is_pressed {
					tile_map.texture_ids.cells[tile_coords.y][tile_coords.x].wall = 0;
					tile_map.is_full[tile_coords.y] |= (1 << u16(tile_coords.x));
				} else do 
					tile_map.is_full[tile_coords.y] &= ~(1 << u16(tile_coords.x));

				tile_map_changed = true;
			}
		}
	}

	if tile_map_changed {
		generateTileMapEdges(&tile_map);
		drawMiniMapTextures(&mini_map);
		// drawMapTextures(&tile_map, true);
		// scaleTexture(walls_map_texture.samples[0], &mini_map.walls);
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
	   mini_map.toggled do drawMiniMapPlayerView(&mini_map);
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

	ticks_before = getTicks();

	// clearBitmap(&bitmap);
	// for pixel in &all_pixels do pixel.color = BLACK;
	// fillBounds2Di(&bitmap, &bounds, BLACK, 0);
	// drawBitmap(&walls_map_texture.bitmaps[], &frame_buffer, 0, 0);
		
	drawWalls(&camera);
	if mini_map.is_visible {
		// drawBitmap(&mini_map.floor, &frame_buffer, mini_map.screen_position.x, mini_map.screen_position.y);
		drawBitmap(&mini_map.canvas, &frame_buffer, mini_map.screen_position.x, mini_map.screen_position.y);
		drawRect(&frame_buffer, &mini_map.screen_bounds, &WHITE);
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

	initGrid(&frame_buffer, FRAME_BUFFER__MAX_WIDTH, FRAME_BUFFER__MAX_HEIGHT, transmute([]FrameBufferPixel)(frame_buffer_bits[:]));
	
	initCamera(&camera);
	initCameraController(&camera_controller.controller);
	camera_controller.camera = &camera;
	
	initRender();

	initTileMap(&tile_map);
	readTileMap(&tile_map, &WALLS, &FLOOR, &CEILING);
	generateTileMapEdges(&tile_map);
	moveTileMap(&tile_map, position);
	
	initRayCast();
    drawMapTextures(&tile_map, true, true, true);

	initMiniMap(&mini_map, &tile_map, &position);
	drawMiniMap(&mini_map);
	UPDATE_INTERVAL = ticks_per_second / TARGET_FPS;
}