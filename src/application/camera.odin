package application

Camera2D :: struct {focal_length: f32, xform: xform2};
Camera3D :: struct {focal_length: f32, xform: xform3};

initCamera2D :: proc(using cam: ^Camera2D, initial_focal_length: f32 = 1) {
    focal_length = initial_focal_length;
    initXform(&xform);
}
initCamera3D :: proc(using cam: ^Camera3D, initial_focal_length: f32 = 1) {
    focal_length = initial_focal_length;
    initXform(&xform);
}
initCamera :: proc{initCamera2D, initCamera3D};

CameraController :: struct {
    moved, 
    turned, 
    zoomed: bool,

    max_velocity, 
    max_acceleration, 
    turn_speed,
    zoom_amount: f32
};

initCameraController :: proc(ctrl: ^CameraController,
    zoom_amount: f32 = 1,
    max_velocity: f32 = 1,
    max_acceleration: f32 = 6,

    turn_speed: f32 = 0.008) {

    ctrl.max_velocity = max_velocity;
    ctrl.max_acceleration = max_acceleration;
    ctrl.turn_speed = turn_speed;
    ctrl.zoom_amount = zoom_amount;
};

CameraController2D :: struct { using controller: CameraController,
    camera: ^Camera2D,

    movement,    
    old_position,
    target_velocity, 
    current_velocity: vec2
};
CameraController3D :: struct { using controller: CameraController,
    camera: ^Camera3D,

    movement,
    old_position,
    target_velocity, 
    current_velocity: vec3
};

onMouseScrolled :: proc(using ctrl: ^CameraController2D) {
    zoomed = true;

    zoom_amount += mouse_wheel_scroll_amount;
         if zoom_amount > +1 do camera.focal_length = zoom_amount;
    else if zoom_amount < -1 do camera.focal_length = -1 / zoom_amount;
    else                     do camera.focal_length = 1;

    mouse_wheel_scroll_amount = 0;
    mouse_wheel_scrolled = false;
}

onMouseMoved :: proc(using ctrl: ^CameraController2D) {
    turned = true;
    
    rotate(&camera.xform,
        -f32(mouse_pos_diff.x) * turn_speed,
        -f32(mouse_pos_diff.y) * turn_speed
    );
    
    mouse_pos_diff.x = 0;
    mouse_pos_diff.y = 0;
    mouse_moved = false;
}

onUpdate3D :: proc(using ctrl: ^CameraController3D) {
    target_velocity = 0;
    if move_right     do target_velocity.x += max_velocity;
    if move_left      do target_velocity.x -= max_velocity;
    if move_up        do target_velocity.y += max_velocity;
    if move_down      do target_velocity.y -= max_velocity;
    if move_forward   do target_velocity.z += max_velocity;
    if move_backward  do target_velocity.z -= max_velocity;

    // Update the current velocity:
    delta_time := f32(clamp(update_timer.seconds, 0, 1));
    approach(
        &current_velocity, 
        &target_velocity, 
        max_acceleration * delta_time
    );
    if non_zero(current_velocity) { // Update the current position:
        movement = current_velocity * delta_time;

        using camera.xform;
        position.y += movement.y;
        position.z += movement.x * yaw_matrix.X.z + movement.z * yaw_matrix.Z.z;
        position.x += movement.x * yaw_matrix.X.x + movement.z * yaw_matrix.Z.x;
    }
}

onUpdate2D :: proc(using ctrl: ^CameraController2D) {    
    target_velocity = 0;
    if move_right     do target_velocity.y += max_velocity;
    if move_left      do target_velocity.y -= max_velocity;
    if move_forward   do target_velocity.x += max_velocity;
    if move_backward  do target_velocity.x -= max_velocity;

    // Update the current velocity:
    using update_timer;
    approach(
        &current_velocity, 
        &target_velocity, 
        max_acceleration * delta_time
    );

    moved = non_zero(current_velocity);
    if moved { // Update the current position:
        using camera.xform;
        movement = multiplyVectorByMatrix(current_velocity * delta_time, &rotation_matrix);
        old_position = position;
        position += movement;
    }
    if turn_right || turn_left {
        turned = true;
        rotate(&camera.xform, turn_left ? delta_time*5 : delta_time*-5, 0);
    }
}
