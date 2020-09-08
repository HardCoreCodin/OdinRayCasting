package application

Camera2D :: struct {focal_length: f32, xform: xform2};
Camera3D :: struct {focal_length: f32, xform: xform3};

initCamera2D :: proc(out: ^Camera2D, focal_length: f32 = 1) {
    out.focal_length = focal_length;
    initXform(&out.xform);
}
initCamera3D :: proc(out: ^Camera3D, focal_length: f32 = 1) {
    out.focal_length = focal_length;
    initXform(&out.xform);
}
initCamera :: proc{initCamera2D, initCamera3D};

CameraController :: struct {
    moved, 
    rotated, 
    zoomed: bool,

    max_velocity, 
    max_acceleration, 
    orientation_speed,
    zoom_speed,
    zoom_amount: f32
};
CameraController2D :: struct { using controller: CameraController,
    camera: ^Camera2D,
    
    target_velocity, 
    current_velocity: vec2
};
CameraController3D :: struct { using controller: CameraController,
    camera: ^Camera3D,

    target_velocity, 
    current_velocity: vec3
};

initController :: proc(ctrl: ^$CameraControllerType/$CameraController,
    zoom_amount: f32 = 1,
    zoom_speed: f32 = 0.005,

    max_velocity: f32 = 8,
    max_acceleration: f32 = 20,

    orientation_speed: f32 = 2.0 / 1000) {

    ctrl.max_velocity = max_velocity;
    ctrl.max_acceleration = max_acceleration;
    ctrl.orientation_speed = orientation_speed;
    ctrl.zoom_speed = zoom_speed;
    ctrl.zoom_amount = zoom_amount;
};

onMouseScrolled :: proc(using ctrl: ^$CameraControllerType/$CameraController) {
    camera.focal_length += zoom_speed * f32(mouse_wheel_scroll_amount);
    zoom_amount = camera.focal_length;
    zoomed = true;
}
onMouseMoved :: proc(using ctrl: ^$CameraControllerType/$CameraController) {
    rotate(&xform,
        -f32(mouse_pos_diff.x) * orientation_speed,
        -f32(mouse_pos_diff.y) * orientation_speed
    );
    rotated = true;
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
        movement := current_velocity * delta_time;

        using camera.xform;
        position.y += movement.y;
        position.z += movement.x * yaw_matrix.X.z + movement.z * yaw_matrix.Z.z;
        position.x += movement.x * yaw_matrix.X.x + movement.z * yaw_matrix.Z.x;
    }
}

onUpdate2D :: proc(using ctrl: ^CameraController2D) {    
    target_velocity = 0;
    if move_right     do target_velocity.x += max_velocity;
    if move_left      do target_velocity.x -= max_velocity;
    if move_forward   do target_velocity.y += max_velocity;
    if move_backward  do target_velocity.y -= max_velocity;

    // Update the current velocity:
    delta_time := f32(clamp(update_timer.seconds, 0, 1));
    approach(
        &current_velocity, 
        &target_velocity, 
        max_acceleration * delta_time
    );
    if non_zero(current_velocity) { // Update the current position:
        movement := current_velocity * delta_time;

        using camera.xform;
        position.x += movement.x*rotation_matrix.X.x + movement.y*rotation_matrix.Y.x;
        position.y += movement.x*rotation_matrix.X.y + movement.y*rotation_matrix.Y.y;
    }
}
