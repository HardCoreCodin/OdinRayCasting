package application

import "core:fmt"
print :: fmt.println;

SPEED :: 240;
MOVEMENT_SPEED :: 0.4;
TURNING_SPEED :: 0.01;
TARGET_FPS :: 60;
UPDATE_INTERVAL: u64;

is_running: bool = true;
class_name :: "Application";

camera: Camera2D;
new_x, new_y: i32;
new_position, moved_by: vec2;
origin: vec2i;
zoom: f64 = 1;
turned_by: f32;
turned, moved, tile_map_changed: bool;

stored_bounds: [dynamic]Bounds2Di;
canvas, frame_buffer: FrameBuffer;

resize :: proc(new_width, new_height: i32) {
	resizeFrameBuffer(new_width, new_height, &frame_buffer);
	setRayCount(new_width);
	setRayDirections();
	castRays();
	update();	
}

update :: proc() {
	using frame_buffer;
	using update_timer;
	using camera.xform;

	ticks_after = getTicks();
	ticks_diff = ticks_after - ticks_before;

	amount := f32(SPEED * (f64(ticks_diff) * seconds_per_tick));

	moved_by = 0;
	if move_right    do moved_by.x += amount * MOVEMENT_SPEED;
	if move_left     do moved_by.x -= amount * MOVEMENT_SPEED;
	if move_forward  do moved_by.y -= amount * MOVEMENT_SPEED;
	if move_backward do moved_by.y += amount * MOVEMENT_SPEED;
	moved = moved_by.x != 0 || moved_by.y != 0;

	turned_by = 0;
	if turn_right    do turned_by += amount * TURNING_SPEED;
	if turn_left     do turned_by -= amount * TURNING_SPEED;
	turned = turned_by != 0;

	if turned {
		rotate(&camera.xform, turned_by, 0);
		setRayDirections();
	}

	// if mouse_is_captured || middle_mouse_button.is_pressed {	
	// 	if mouse_pos_diff.x != 0 do moved_by.x += amount * f64(mouse_pos_diff.x) * MOVEMENT_SPEED;
	// 	if mouse_pos_diff.y != 0 do moved_by.y += amount * f64(mouse_pos_diff.y) * MOVEMENT_SPEED;
	// 	mouse_pos_diff.x = 0;
	// 	mouse_pos_diff.y = 0;
	// }

	if moved {
		new_position = position + moved_by;
		new_x = i32(new_position.x);
		new_y = i32(new_position.y);	
		if new_x >= 0 && 
		   new_y >= 0 && 
		   new_x < (tile_map.width * tile_map.tile_size) && 
		   new_y < (tile_map.height * tile_map.tile_size) && 
		   !tile_map.tiles[new_y / tile_map.tile_size][new_x / tile_map.tile_size].is_full {
			position = new_position;
			origin = {new_x, new_y};
		}
	}
	
	if mouse_wheel_scrolled {
		mouse_wheel_scrolled = false;

		// -200  -150  -100  -50  0   50  100  150  200
		//   8     6     4    2   1  1/2  1/4  1/6  1/8                 
		if      mouse_wheel_scroll_amount == 0 do zoom = 1;
		else if mouse_wheel_scroll_amount  > 0 do zoom = 50 / (2 * f64(mouse_wheel_scroll_amount));
		else                                   do zoom =     (-2 * f64(mouse_wheel_scroll_amount)) / 50;
	}

	tile_map_changed = false;
	if left_mouse_button.is_pressed && 
		mouse_pos.x < (tile_map.width * tile_map.tile_size) && 
		mouse_pos.y < (tile_map.height * tile_map.tile_size) {

		tile_map.tiles[mouse_pos.y / tile_map.tile_size][mouse_pos.x / tile_map.tile_size].is_full = true;
		tile_map_changed = true;
	}

	if right_mouse_button.is_pressed &&
		mouse_pos.x < (tile_map.width * tile_map.tile_size) && 
		mouse_pos.y < (tile_map.height * tile_map.tile_size) {
		
		tile_map.tiles[mouse_pos.y / tile_map.tile_size][mouse_pos.x / tile_map.tile_size].is_full = false;
		tile_map_changed = true;
	}

	if tile_map_changed do generateTileMapEdges(&tile_map);
	if tile_map_changed || moved do transformTileMapEdges(&tile_map, origin);
	if tile_map_changed || moved || turned do castRays();

	ticks_before = getTicks();
}

render :: proc() {
	using render_timer;
	using camera.xform;
	using frame_buffer;

	ticks_before = getTicks();

	fillRect(0, 0, width, height, &BLACK, &frame_buffer.bitmap);

	for row, y in &tile_map.tiles do
		for tile, x in &row do
			if tile.is_full do fillRect(&tile.bounds, &BLUE, &frame_buffer.bitmap);

	padding: vec2i = {1, 1};

	for ray in &rays do drawLine(position, ray.hit.position, &GREEN, &frame_buffer.bitmap);
	for edge in &tile_map.edges {
		using edge;
		drawLine(from^, to^, color, &frame_buffer.bitmap);
		print(1);
		fillRect(from^ - padding, from^ + padding, &GREEN, &frame_buffer.bitmap);
		print(2);
		fillRect(to^   - padding, to^   + padding, &GREEN, &frame_buffer.bitmap);
		print(3);
	}
	print(4);
	fillCircle(position, 4, &RED, &frame_buffer.bitmap);

	// bounds.min = coords - padding*2;
	// bounds.max = coords + padding*2;

	// fillBounds(&frame_buffer.bitmap, &bounds, &RED);

	ticks_after = getTicks();	

	accumulateTimer(&render_timer);

	if (ticks_after - ticks_of_last_report) >= ticks_per_second {
		// print(
		// 	"Frame count:", accumulated_frame_count,
		// 	"Average microseconds per frame:", 
		// 	u64(
		// 		microseconds_per_tick * (
		// 			f64(accumulated_ticks) / 
		// 			f64(accumulated_frame_count)
		// 		)
		// 	)
		// );

		accumulated_ticks = 0;
		accumulated_frame_count = 0;
		ticks_of_last_report = ticks_after;
	}
}


initApplication :: proc(platformGetTicks: GetTicks, platformTicksPerSecond: u64) {
	using camera.xform;
	position = 100;
	origin = 100;

	initTimers(platformGetTicks, platformTicksPerSecond);
	initFrameBuffer(&frame_buffer);
	initFrameBuffer(&canvas);
	initCamera(&camera);
	initTileMap(&tile_map);
	readTileMapFromASCIIgrid(&tile_map, &TILE_MAP_ASCII_GRID);
	generateTileMapEdges(&tile_map);
	transformTileMapEdges(&tile_map, origin);
	UPDATE_INTERVAL = ticks_per_second / TARGET_FPS;
}