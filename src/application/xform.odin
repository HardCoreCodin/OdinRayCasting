package application

xform2 :: struct {
    matrix,
    rotation_matrix,
    rotation_matrix_inverted: mat2,

    position: vec2,
    
    right_direction, 
    forward_direction: ^vec2
};
xform3 :: struct {
    matrix,
    yaw_matrix, 
    pitch_matrix, 
    roll_matrix,
    rotation_matrix,
    rotation_matrix_inverted: mat3,

    position: vec3,
    
    up_direction, 
    right_direction, 
    forward_direction: ^vec3
};
xform4 :: struct {
    matrix,
    yaw_matrix, 
    pitch_matrix, 
    roll_matrix,
    rotation_matrix,
    rotation_matrix_inverted: mat4,

    position: vec4,
    
    up_direction, 
    right_direction, 
    forward_direction: ^vec4
};

initXform2 :: proc(using out: ^xform2) {
    setMat2ToIdentity(&matrix);
    setMat2ToIdentity(&rotation_matrix);
    setMat2ToIdentity(&rotation_matrix_inverted);

    using rotation_matrix;
    right_direction   = &X;
    forward_direction = &Y;
}
initXform3 :: proc(using out: ^xform3) {
    setMat3ToIdentity(&matrix);
    setMat3ToIdentity(&yaw_matrix);
    setMat3ToIdentity(&pitch_matrix);
    setMat3ToIdentity(&roll_matrix);
    setMat3ToIdentity(&rotation_matrix);
    setMat3ToIdentity(&rotation_matrix_inverted);

    using rotation_matrix;
    right_direction   = &X;
    up_direction      = &Y;
    forward_direction = &Z;
}
initXform4 :: proc(using out: ^xform4) {
    setMat4ToIdentity(&matrix);
    setMat4ToIdentity(&yaw_matrix);
    setMat4ToIdentity(&pitch_matrix);
    setMat4ToIdentity(&roll_matrix);
    setMat4ToIdentity(&rotation_matrix);
    setMat4ToIdentity(&rotation_matrix_inverted);

    using rotation_matrix;
    right_direction   = &X;
    up_direction      = &Y;
    forward_direction = &Z;
}
initXform :: proc{initXform2, initXform3, initXform4};

rotate2D :: inline proc(using transform: ^xform2, yaw_angle: f32 = 0, pitch_angle: f32 = 0) {
    if yaw_angle == 0 do return;
    yaw2(yaw_angle, &rotation_matrix);
    transposeMat2(&rotation_matrix, &rotation_matrix_inverted);
    mulMat2(&matrix, &rotation_matrix, &matrix);
}
rotate3D :: inline proc(using transform: ^xform3, yaw_angle: f32 = 0, pitch_angle: f32 = 0, roll_angle: f32  = 0) {
    if yaw_angle == 0 do setMat3ToIdentity(&yaw_matrix); else do yaw3(yaw_angle, &yaw_matrix);
    if pitch_angle == 0 do setMat3ToIdentity(&pitch_matrix); else do pitch3(pitch_angle, &pitch_matrix);
    if roll_angle == 0 do setMat3ToIdentity(&roll_matrix); else do roll3(roll_angle, &roll_matrix);
    mulMat3(&pitch_matrix, &yaw_matrix, &rotation_matrix);
    mulMat3(&rotation_matrix, &roll_matrix, &rotation_matrix);
    transposeMat3(&rotation_matrix, &rotation_matrix_inverted);
    mulMat3(&matrix, &rotation_matrix, &matrix);
}
rotate4D :: inline proc(using transform: ^xform4, yaw_angle: f32 = 0, pitch_angle: f32 = 0, roll_angle: f32 = 0) {
    if yaw_angle == 0 do setMat4ToIdentity(&yaw_matrix); else do yaw4(yaw_angle, &yaw_matrix);
    if pitch_angle == 0 do setMat4ToIdentity(&pitch_matrix); else do pitch4(pitch_angle, &pitch_matrix);
    if roll_angle == 0 do setMat4ToIdentity(&roll_matrix); else do roll4(roll_angle, &roll_matrix);
    mulMat4(&pitch_matrix, &yaw_matrix, &rotation_matrix);
    mulMat4(&rotation_matrix, &roll_matrix, &rotation_matrix);
    transposeMat4(&rotation_matrix, &rotation_matrix_inverted);
    mulMat4(&matrix, &rotation_matrix, &matrix);
}
rotate :: proc{rotate2D, rotate3D, rotate4D};