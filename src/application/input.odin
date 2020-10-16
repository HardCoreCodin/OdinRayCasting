package application

move_right, turn_right,
move_left, turn_left,
move_up,
move_down,
move_forward,
move_backward,
ctrl_is_pressed,
show_minimap,
show_minimap_debug: bool;

FilterMode :: enum {None, BiLinear, TriLinear}
filter_mode: FilterMode;

up_key, 
down_key, 
left_key, turn_left_key,
right_key, turn_right_key,
forward_key,
backward_key,
toggle_map,
toggle_map_debug,
no_filter,
bi_linear,
tri_linear,
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
		case toggle_map: if !pressed do show_minimap = !show_minimap;
		case toggle_map_debug: if !pressed do show_minimap_debug = !show_minimap_debug;
		case no_filter: if !pressed do filter_mode = FilterMode.None;
		case bi_linear: if !pressed do filter_mode = FilterMode.BiLinear;
		case tri_linear: if !pressed do filter_mode = FilterMode.TriLinear;
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