package application

move_right, turn_right,
move_left, turn_left,
move_up,
move_down,
move_forward,
move_backward,
ctrl_is_pressed,
toggle1,
toggle2: bool;

up_key, 
down_key, 
left_key, turn_left_key,
right_key, turn_right_key,
forward_key,
backward_key,
toggle1_key,
toggle2_key,
ctrl_key,
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
		case toggle1_key: if !pressed do toggle1 = !toggle1;	
		case toggle2_key: if !pressed do toggle2 = !toggle2;
		case ctrl_key: ctrl_is_pressed = pressed;		
		case exit_key: is_running = false;
	}
}

MouseButton :: struct { 
	is_pressed,
	is_released: bool, 

	down_pos, 
	up_pos: vec2i 
}

middle_mouse_button,
right_mouse_button,
left_mouse_button: MouseButton;
mouse_pos,
mouse_pos_diff: vec2i;
mouse_moved,
mouse_is_captured,
mouse_wheel_scrolled: bool;
mouse_wheel_scroll_amount: f32;

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
	mouse_wheel_scroll_amount += amount;
	mouse_wheel_scrolled = true;
}

setMousePosition :: proc(x, y: i32) {
	mouse_pos.x = x;
	mouse_pos.y = y;
}

setMouseMovement :: proc(x, y: i32) {
	mouse_pos_diff.x = x;
	mouse_pos_diff.y = y;
	mouse_moved = true;
}