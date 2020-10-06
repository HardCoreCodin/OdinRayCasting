package application

selected: i32;

R: f32 = 5;

A: vec2 = {100, 120};
B: vec2 = {450, 380};
C: vec2 = {320, 120};
D: vec2 = {410, 370};
P: vec2;

intersected: bool = lineSegmentsIntersect(A, B, C, D, &P);

updateLSI :: proc() {
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


renderLSI :: proc() {
	using camera.xform;
	
	fillRect(&frame_buffer, 0, 0, frame_buffer.width, frame_buffer.height, BLACK);
	
	drawLine(&frame_buffer, A, B, WHITE);
	drawLine(&frame_buffer, C, D, WHITE);

	fillCircle(&frame_buffer, A, R, GREY);
	fillCircle(&frame_buffer, B, R, YELLOW);
	fillCircle(&frame_buffer, C, R, BLUE);
	fillCircle(&frame_buffer, D, R, GREEN);
	
	if intersected do fillCircle(&frame_buffer, P, R, RED);	
}