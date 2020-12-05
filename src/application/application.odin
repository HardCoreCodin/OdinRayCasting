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
11111111111111111111111111111111
1_________1____________________1
1__1___11_1____________________1
111111_1111____________________1
1__1_____11____________________1
1____11___1____________________1
1_____1_111____________________1
1_11111__11____________________1
1_________1____________________1
11111111111____________________1
1______________________________1
1___________11111111___________1
1__________________1___________1
1__________________1___________1
1__________________1___________1
1__________________11111111____1
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

TARGET_FPS :: 60;
UPDATE_INTERVAL: u64;

is_running: bool = true;
class_name :: "Application";

camera: Camera2D;
camera_controller: CameraController2D;

column_is_being_added: bool;
new_column: ^Circle;

body_radius: f32 = 0.3;
next_tile: ^Tile;
tile_map_changed: bool;

frame_buffer_bits: [FRAME_BUFFER__MAX_SIZE]u32;
frame_buffer: Bitmap;

resize :: proc(new_width, new_height: i32) {
	initGrid(&frame_buffer, new_width, new_height, transmute([]Pixel)(frame_buffer_bits[:]));
	
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
	mini_map.toggled = mini_map.is_visible != show_minimap || mini_map.is_debug_visible != show_minimap_debug;
	mini_map.is_visible = show_minimap;
	mini_map.is_debug_visible = show_minimap_debug;

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

	ticks_after = getTicks();
	ticks_diff = ticks_after - ticks_before;
	delta_time = f32(f64(ticks_diff) * seconds_per_tick);
	
	onUpdate2D(&camera_controller);

	ticks_before = getTicks();
	
	distance_to_column, min_distance_allowed, max_radius_allowed, displacement: f32;
	vector_to_column: vec2;

	if moved { // Detect collisions:
		if movement.x > 0 {
			next_tile = &tile_map.cells[i32(position.y)][i32(position.x + body_radius)];
			if next_tile.is_full do position.x = f32(next_tile.bounds.left) - body_radius;
		} else if movement.x < 0 {
			next_tile = &tile_map.cells[i32(position.y)][i32(position.x - body_radius)];
			if next_tile.is_full do position.x = f32(next_tile.bounds.right) + body_radius;
		}
		
		if movement.y < 0 {
			next_tile = &tile_map.cells[i32(position.y - body_radius)][i32(position.x)];
			if next_tile.is_full do position.y = f32(next_tile.bounds.bottom) + body_radius;
		} else if movement.y > 0 {
			next_tile = &tile_map.cells[i32(position.y + body_radius)][i32(position.x)];
			if next_tile.is_full do position.y = f32(next_tile.bounds.top) - body_radius;
		}

		for column, i in &tile_map.columns {
			if i32(i) == tile_map.column_count do break;
			vector_to_column = column.position - position;
			distance_to_column = length(vector_to_column);
			min_distance_allowed = body_radius + column.radius;
			if distance_to_column < min_distance_allowed do 
				position -= (vector_to_column / distance_to_column) * (min_distance_allowed - distance_to_column);
		}

		movement = position - old_position;
	}

	if left_mouse_button.is_released do column_is_being_added = false;

	tile_map_changed = false;
	column: ^Circle;
	if !mouse_is_captured {
		if (left_mouse_button.is_pressed || 
			right_mouse_button.is_pressed) && mouseOnMiniMap() {

			tile_coords := mouse_pos;
			tile_coords -= mini_map.screen_position^;
			tile_pos: vec2 = {
				f32(tile_coords.x), 
				f32(tile_coords.y)
			};
			tile_pos -= mini_map.offset;
			tile_pos /= mini_map.scale_factor;
			tile_pos += position;
			tile_coords = {
				i32(tile_pos.x), 
				i32(tile_pos.y)
			};
			
			if ctrl_is_pressed {
				if left_mouse_button.is_pressed {
					if !column_is_being_added {
						if tile_map.column_count <= MAX_COLUMN_COUNT && 
						   length(tile_pos - position) > body_radius {
							column_is_being_added = true;
							new_column = &tile_map.columns[tile_map.column_count];
							new_column.position = tile_pos;
							tile_map.column_count += 1;
						}
					}
					if column_is_being_added {
						tile_map_changed = true;
						new_column.radius = length(new_column.position - tile_pos);
						distance_to_column = length(new_column.position - position);
						max_radius_allowed = distance_to_column - body_radius;
						if new_column.radius > max_radius_allowed do 
							new_column.radius = max_radius_allowed;				
					}
				} ;
				 if right_mouse_button.is_pressed {
					right_mouse_button.is_pressed = false;
					closest_column_id: i32 = -1;
					closest_column_distance: f32 = 10000;

					for column, i in &tile_map.columns {
						if i32(i) == tile_map.column_count do break;
						vector_to_column = column.position - tile_pos;
						distance_to_column = length(vector_to_column);
						if distance_to_column < column.radius &&
						   distance_to_column < closest_column_distance {
						   	closest_column_distance = distance_to_column;
						   	closest_column_id = i32(i);
						   }
					}

					if closest_column_id > -1 {
						tile_map_changed = true;
						tile_map.column_count -= 1;
						if closest_column_id != tile_map.column_count do
							for column_id in closest_column_id..tile_map.column_count do
								tile_map.columns[column_id] = tile_map.columns[column_id + 1];
					}					
				}
			} else {
				if !(tile_coords.x == i32(position.x) && 
				     tile_coords.y == i32(position.y)) {
					tile_map.cells[tile_coords.y][tile_coords.x].is_full = left_mouse_button.is_pressed;
					tile_map_changed = true;
				}					
			}
		}
	}

	if tile_map_changed {
		generateTileMapEdges(&tile_map);
		drawMiniMapTextures(&mini_map);
	}
	if tile_map_changed || moved {
		moveTileMap(&tile_map, position);
		moveMiniMap(&mini_map, movement * -mini_map.scale_factor);
		movement.x = 0;
		movement.y = 0;
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
}

render :: proc() {
	using render_timer;
	using camera.xform;

	ticks_before = getTicks();

	// clearBitmap(&bitmap);
	// for pixel in &all_pixels do pixel.color = BLACK;
	// fillBounds2Di(&bitmap, &bounds, BLACK, 0);
	// drawBitmap(floor_texture.bitmaps[0], &frame_buffer, 0, 0);
		
	drawWalls(&camera);
	if mini_map.is_visible {
		// drawBitmap(&mini_map.floor, &frame_buffer, mini_map.screen_position.x, mini_map.screen_position.y);
		drawBitmap(&mini_map.canvas, &frame_buffer, mini_map.screen_position.x, mini_map.screen_position.y);
		drawRect(&frame_buffer, &mini_map.screen_bounds, &WHITE);
	}

	ticks_after = getTicks();
	accumulateTimer(&render_timer);

	if (ticks_after - ticks_of_last_report) >= ticks_per_second {
		print(frame_buffer.width, "x", frame_buffer.height, "FPS:", 1 / (seconds_per_tick * (
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

	initColors();
	initTimers(platformGetTicks, platformTicksPerSecond);
	initGrid(&frame_buffer, FRAME_BUFFER__MAX_WIDTH, FRAME_BUFFER__MAX_HEIGHT, transmute([]Pixel)(frame_buffer_bits[:]));
	
	initCamera(&camera);
	initCameraController(&camera_controller.controller);
	camera_controller.camera = &camera;
	
	initRender();

	initTileMap(&tile_map);
	readTileMap(&tile_map, &WALLS);
	generateTileMapEdges(&tile_map);
	moveTileMap(&tile_map, position);
	
	initRayCast();

	initMiniMap(&mini_map, &tile_map, &position);
	drawMiniMap(&mini_map);

	show_minimap = true;
	filter_mode = FilterMode.BiLinear;

	UPDATE_INTERVAL = ticks_per_second / TARGET_FPS;
}