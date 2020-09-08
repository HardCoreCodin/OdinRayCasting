package application

move_right, turn_right,
move_left, turn_left,
move_up,
move_down,
move_forward,
move_backward: bool;

up_key, 
down_key, 
left_key, turn_left_key,
right_key, turn_right_key,
forward_key,
backward_key,
exit_key: u8;

keyChanged :: proc(key: u8, pressed: bool) {
	switch key {
		case turn_left_key: turn_left = pressed;
		case turn_right_key: turn_right = pressed;
		case left_key: move_left = pressed;
		case right_key: move_right = pressed;	
		case up_key: move_up = pressed;
		case down_key: move_down = pressed;
		case forward_key: move_forward = pressed;	
		case backward_key: move_backward = pressed;	
		case exit_key: is_running = false;
	}
}

Coords2D :: [2]i32;
MouseButton :: struct { 
	is_pressed,
	is_released: bool, 

	down_pos, 
	up_pos: Coords2D 
}

middle_mouse_button,
right_mouse_button,
left_mouse_button: MouseButton;
mouse_pos,
mouse_pos_diff: Coords2D;
mouse_is_captured: bool;
mouse_wheel_scrolled: bool;
mouse_wheel_scroll_amount: i16;

setMouseButtonDown :: proc(mouse_button: ^MouseButton, x, y: i32) {
	mouse_button.is_pressed = true;
	mouse_button.is_released = false;
	
	mouse_button.down_pos.x = x;
	mouse_button.down_pos.y = y;
}

setMouseButtonUp :: proc(mouse_button: ^MouseButton, x, y: i32) {
	mouse_button.is_released = true;
	mouse_button.is_pressed = false;
	
	mouse_button.up_pos.x = x;
	mouse_button.up_pos.y = y;
}

setMouseWheel :: proc(amount: f32) {
	mouse_wheel_scroll_amount += i16(amount * 100);
	mouse_wheel_scrolled = true;
}

setMousePosition :: proc(x, y: i32) {
	mouse_pos.x = x;
	mouse_pos.y = y;
}

setMouseMovement :: proc(x, y: i32) {
	mouse_pos_diff.x = x;
	mouse_pos_diff.y = y;
}