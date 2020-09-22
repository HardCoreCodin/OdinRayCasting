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

loadTextures :: proc() {
	for texture, i in &textures {
		readBitmapFromFile(texture_files[i], &texture, texture_bitmaps_data[i][:]);
	}
}

tile_map: TileMap;
TILE_MAP_ASCII_GRID := `
1111111111111111111111111111111111111111
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1___________22222223___________________1
1__________________3___________________1
1__________________3___________________1
1__________________3___________________1
1__________________34444444____________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1111111111111111111111111111111111111111
`;

SPEED :: 240;
MOVEMENT_SPEED :: 0.04;
TURNING_SPEED :: 0.01;
TARGET_FPS :: 60;
UPDATE_INTERVAL: u64;

is_running: bool = true;
class_name :: "Application";

camera: Camera2D;
new_x, new_y: i32;
new_position, moved_by: vec2;
zoom: f64 = 1;
turned_by: f32;
turned, moved, tile_map_changed: bool;

stored_bounds: [dynamic]Bounds2Di;
canvas, frame_buffer: FrameBuffer;

// new_approach: bool;

resize :: proc(new_width, new_height: i32) {
	resizeFrameBuffer(new_width, new_height, &frame_buffer);
	setRayCount(new_width);
	generateRays(&camera);
	castRays();
	update();	
}

selected: i32;
intersected: bool;
update2 :: proc() {
	if !left_mouse_button.is_pressed {
		selected = 0;
		return;
	}

	pos: vec2 = {
		f32(mouse_pos.x), 
		f32(mouse_pos.y)
	};

	switch selected {
		case 0:
			if inRange(A.x - R, pos.x, A.x + R) &&
			   inRange(A.y - R, pos.y, A.y + R) do selected = 1; else 
			if inRange(B.x - R, pos.x, B.x + R) &&
			   inRange(B.y - R, pos.y, B.y + R) do selected = 2; else
			if inRange(C.x - R, pos.x, C.x + R) &&
			   inRange(C.y - R, pos.y, C.y + R) do selected = 3; else
			if inRange(D.x - R, pos.x, D.x + R) &&
			   inRange(D.y - R, pos.y, D.y + R) do selected = 4;
		case 1: A = pos;
		case 2: B = pos;
		case 3: C = pos;
		case 4: D = pos;
	}

	if mouse_moved && selected != 0 {
		mouse_moved = false;
		intersected = lineSegmentsIntersect(A, B, C, D, &P);
	}
}

update :: proc() {
	using frame_buffer;
	using update_timer;
	using camera.xform;

	ticks_after = getTicks();
	ticks_diff = ticks_after - ticks_before;

	amount := f32(SPEED * (f64(ticks_diff) * seconds_per_tick));

	// if move_up do new_approach = !new_approach;

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
		generateRays(&camera);
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
		if inRange(0, new_x, tile_map.width-1) && 
		   inRange(0, new_y, tile_map.height-1) && 
		   !tile_map.tiles[new_y][new_x].is_full {
			position = new_position;
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
		mouse_pos.x < TILE_SIZE*tile_map.width && 
		mouse_pos.y < TILE_SIZE*tile_map.height {

		tile_map.tiles[mouse_pos.y/TILE_SIZE][mouse_pos.x/TILE_SIZE].is_full = true;
		tile_map_changed = true;
	}

	if right_mouse_button.is_pressed &&
		mouse_pos.x < (TILE_SIZE*tile_map.width) && 
		mouse_pos.y < (TILE_SIZE*tile_map.height) {
		
		tile_map.tiles[mouse_pos.y/TILE_SIZE][mouse_pos.x/TILE_SIZE].is_full = false;
		tile_map_changed = true;
	}

	if tile_map_changed do generateTileMapEdges(&tile_map);
	if tile_map_changed || moved do transformTileMapEdges(&tile_map, position);
	if tile_map_changed || moved || turned do castRays();

	ticks_before = getTicks();
}


A: vec2 = {100, 120};
B: vec2 = {450, 380};
C: vec2 = {320, 120};
D: vec2 = {410, 370};
P: vec2;
R: f32 = 5;

render2 :: proc() {
	using camera.xform;
	using frame_buffer;
	fillRect(0, 0, width, height, BLACK, &bitmap);
	drawLine(A, B, WHITE, &bitmap);
	drawLine(C, D, WHITE, &bitmap);
	fillCircle(A, R, GREY, &bitmap);
	fillCircle(B, R, YELLOW, &bitmap);
	fillCircle(C, R, BLUE, &bitmap);
	fillCircle(D, R, GREEN, &bitmap);
	if intersected do
		fillCircle(P, R, RED, &bitmap);	
}

render :: proc() {
	using render_timer;
	using camera.xform;
	using frame_buffer;
	ticks_before = getTicks();
	castRays();
	ticks_after = getTicks();	

	fillRect(0, 0, width, height, BLACK, &bitmap);
	drawWalls(&camera);

	for row, y in &tile_map.tiles do
		for tile, x in &row do
			if tile.is_full do fillRect(tile.bounds.min*TILE_SIZE, tile.bounds.max*TILE_SIZE, BLUE, &bitmap);

	padding: vec2i = {1, 1};

	for ray in &rays do drawLine(TILE_SIZE*position, TILE_SIZE*ray.hit.position, GREY, &bitmap);
	// for ray in &rays do drawLine(TILE_SIZE*position, TILE_SIZE*position + ray.direction*50, GREEN, &bitmap);
	for edge in &tile_map.edges {
		using edge;
		drawLine(TILE_SIZE*from^, TILE_SIZE*to^, color, &bitmap);
		fillRect(TILE_SIZE*from^ - padding, TILE_SIZE*from^ + padding, WHITE, &bitmap);
		fillRect(TILE_SIZE*to^   - padding, TILE_SIZE*to^   + padding, WHITE, &bitmap);
	}
	fillCircle(TILE_SIZE*position, 4, RED, &bitmap);

	accumulateTimer(&render_timer);

	if (ticks_after - ticks_of_last_report) >= ticks_per_second {
		print(
			"Ray-Casting",
			// new_approach ? "(new):" : "(old)",
			u64(
				microseconds_per_tick * (
					f64(accumulated_ticks) / 
					f64(accumulated_frame_count)
				)
			),
			"μs/f"
		);

		accumulated_ticks = 0;
		accumulated_frame_count = 0;
		ticks_of_last_report = ticks_after;
	}
}


initApplication :: proc(platformGetTicks: GetTicks, platformTicksPerSecond: u64) {
	using camera.xform;
	position = 10;
	// intersected = lineSegmentsIntersect(A, B, C, D, &P);
	initTimers(platformGetTicks, platformTicksPerSecond);
	initFrameBuffer(&frame_buffer);
	initFrameBuffer(&canvas);
	initCamera(&camera);
	initTileMap(&tile_map);

	loadTextures();
	readTileMapFromASCIIgrid(&tile_map, &TILE_MAP_ASCII_GRID);
	generateTileMapEdges(&tile_map);
	transformTileMapEdges(&tile_map, position);
	UPDATE_INTERVAL = ticks_per_second / TARGET_FPS;
}