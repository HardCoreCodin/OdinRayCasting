package application

import "core:math"
sqrt :: math.sqrt_f32;
sin  :: math.sin_f32;
cos  :: math.cos_f32;
pow  :: math.pow_f32;

mat2 :: struct { X, Y: vec2 };
mat3 :: struct { X, Y, Z: vec3 };
mat4 :: struct { X, Y, Z, W: vec4 };

setMat2ToIdentity :: inline proc(using matrix: ^mat2) {
    X.x = 1; X.y = 0;
    Y.x = 0; Y.y = 1;
}
setMat3ToIdentity :: inline proc(using matrix: ^mat3) {
    X.x = 1; X.y = 0; X.z = 0;
    Y.x = 0; Y.y = 1; Y.z = 0;    
    Z.x = 0; Z.y = 0; Z.z = 1;
}
setMat4ToIdentity :: inline proc(using matrix: ^mat4) {
    X.x = 1; X.y = 0; X.z = 0; X.w = 0;
    Y.x = 0; Y.y = 1; Y.z = 0; Y.w = 0;
    Z.x = 0; Z.y = 0; Z.z = 1; Z.w = 0;
    W.x = 0; W.y = 0; W.z = 0; W.w = 1;
}
setMatrixToIdentity :: proc{setMat2ToIdentity, setMat3ToIdentity, setMat4ToIdentity};

transposeMat2 :: inline proc(m: ^mat2, using out: ^mat2) {
    X.x = m.X.x;  X.y = m.Y.x;
    Y.x = m.X.y;  Y.y = m.Y.y;
}
transposeMat3 :: inline proc(m: ^mat3, using out: ^mat3) {
    X.x = m.X.x;  X.y = m.Y.x;  X.z = m.Z.x;
    Y.x = m.X.y;  Y.y = m.Y.y;  Y.z = m.Z.y; 
    Z.x = m.X.z;  Z.y = m.Y.z;  Z.z = m.Z.z;
}
transposeMat4 :: inline proc(m: ^mat4, using out: ^mat4) {
    X.x = m.X.x;  X.y = m.Y.x;  X.z = m.Z.x;  X.w = m.W.x;
    Y.x = m.X.y;  Y.y = m.Y.y;  Y.z = m.Z.y;  Y.w = m.W.y; 
    Z.x = m.X.z;  Z.y = m.Y.z;  Z.z = m.Z.z;  Z.w = m.W.z;
    W.x = m.X.w;  W.y = m.Y.w;  W.z = m.Z.w;  W.w = m.W.w;
}
transposeMatrix :: proc{transposeMat2, transposeMat3, transposeMat4};

imulVec2Mat2 :: inline proc(out: ^vec2, using matrix: ^mat2) {
    v := out^;
    m: mat2;
    transposeMat2(matrix, &m);

    out.x = dot2(v, m.X);
    out.y = dot2(v, m.Y);
}
imulVec3Mat3 :: inline proc(out: ^vec3, using matrix: ^mat3) {
    v := out^;
    m: mat3;
    transposeMat3(matrix, &m);

    out.x = dot3(v, m.X);
    out.y = dot3(v, m.Y);
    out.z = dot3(v, m.Z);
}
imulVec4Mat4 :: inline proc(out: ^vec4, using matrix: ^mat4) {
    v := out^;
    m: mat4;
    transposeMat4(matrix, &m);

    out.x = dot4(v, m.X);
    out.y = dot4(v, m.Y);
    out.z = dot4(v, m.Z);
    out.w = dot4(v, m.W);
}
multiplyVectorByMatrixInPlace :: proc{imulVec2Mat2, imulVec3Mat3, imulVec4Mat4};

mulMat2 :: inline proc(lhs: ^mat2, rhs: ^mat2, using out: ^mat2) {
    rhsT: mat2;
    transposeMat2(rhs, &rhsT);
    
    X = {
        dot2(lhs.X, rhsT.X), 
        dot2(lhs.X, rhsT.Y)
    };
    
    Y = {
        dot2(lhs.Y, rhsT.X), 
        dot2(lhs.Y, rhsT.Y)
    };
}
mulMat3 :: inline proc(lhs: ^mat3, rhs: ^mat3, using out: ^mat3) {
    rhsT: mat3;
    transposeMat3(rhs, &rhsT);
    
    X = {
        dot3(lhs.X, rhsT.X), 
        dot3(lhs.X, rhsT.Y), 
        dot3(lhs.X, rhsT.Z)
    };
    
    Y = {
        dot3(lhs.Y, rhsT.X), 
        dot3(lhs.Y, rhsT.Y), 
        dot3(lhs.Y, rhsT.Z)
    };
    
    Z = {
        dot3(lhs.Z, rhsT.X), 
        dot3(lhs.Z, rhsT.Y), 
        dot3(lhs.Z, rhsT.Z)
    };
}
mulMat4 :: inline proc(lhs: ^mat4, rhs: ^mat4, using out: ^mat4) {
    rhsT: mat4;
    transposeMat4(rhs, &rhsT);
    
    X = {
        dot4(lhs.X, rhsT.X), 
        dot4(lhs.X, rhsT.Y), 
        dot4(lhs.X, rhsT.Z),
        dot4(lhs.X, rhsT.W)
    };
    
    Y = {
        dot4(lhs.Y, rhsT.X), 
        dot4(lhs.Y, rhsT.Y), 
        dot4(lhs.Y, rhsT.Z),
        dot4(lhs.Y, rhsT.W)
    };
    
    Z = {
        dot4(lhs.Z, rhsT.X), 
        dot4(lhs.Z, rhsT.Y), 
        dot4(lhs.Z, rhsT.Z), 
        dot4(lhs.Z, rhsT.W)
    };
    
    W = {
        dot4(lhs.W, rhsT.X), 
        dot4(lhs.W, rhsT.Y), 
        dot4(lhs.W, rhsT.Z), 
        dot4(lhs.W, rhsT.W)
    };
}
multiplyMatrices :: proc{mulMat2, mulMat3, mulMat4};

yaw2 :: inline proc(angle: f32, using out: ^mat2) {
    s := sin(angle);
    c := cos(angle);

    LX := X;
    LY := Y;

    X.x = c*LX.x + s*LX.y;
    Y.x = c*LY.x + s*LY.y;

    X.y = c*LX.y - s*LX.x;
    Y.y = c*LY.y - s*LY.x;
};
yaw3 :: inline proc(angle: f32, using out: ^mat3) {
    s := sin(angle);
    c := cos(angle);

    LX := X;
    LY := Y;
    LZ := Z;

    X.x = c*LX.x - s*LX.z;
    Y.x = c*LY.x - s*LY.z;
    Z.x = c*LZ.x - s*LZ.z;

    X.z = c*LX.z + s*LX.x;
    Y.z = c*LY.z + s*LY.x;
    Z.z = c*LZ.z + s*LZ.x;
};
yaw4 :: inline proc(angle: f32, using out: ^mat4) {
    s := sin(angle);
    c := cos(angle);

    LX := X;
    LY := Y;
    LZ := Z;
    LW := W;

    X.x = c*LX.x - s*LX.z;
    Y.x = c*LY.x - s*LY.z;
    Z.x = c*LZ.x - s*LZ.z;
    W.x = c*LW.x - s*LW.z;

    X.z = c*LX.z + s*LX.x;
    Y.z = c*LY.z + s*LY.x;
    Z.z = c*LZ.z + s*LZ.x;
    W.z = c*LW.z + s*LW.x;
};
yaw :: proc{yaw2, yaw3, yaw4};

pitch3 :: inline proc(angle: f32, using out: ^mat3) {
    s := sin(angle);
    c := cos(angle);

    LX := X;
    LY := Y;
    LZ := Z;

    X.y = c*LX.y + s*LX.z;
    Y.y = c*LY.y + s*LY.z;
    Z.y = c*LZ.y + s*LZ.z;

    X.z = c*LX.z - s*LX.y;
    Y.z = c*LY.z - s*LY.y;
    Z.z = c*LZ.z - s*LZ.y;
};
pitch4 :: inline proc(angle: f32, using out: ^mat4) {
    s := sin(angle);
    c := cos(angle);

    LX := X;
    LY := Y;
    LZ := Z;
    LW := W;

    X.y = c*LX.y + s*LX.z;
    Y.y = c*LY.y + s*LY.z;
    Z.y = c*LZ.y + s*LZ.z;
    W.y = c*LW.y + s*LW.z;

    X.z = c*LX.z - s*LX.y;
    Y.z = c*LY.z - s*LY.y;
    Z.z = c*LZ.z - s*LZ.y;
    W.z = c*LW.z - s*LW.y;
};
pitch :: proc{pitch3, pitch4};

roll3 :: inline proc(angle: f32, using out: ^mat3) {
    s := sin(angle);
    c := cos(angle);

    LX := X;
    LY := Y;
    LZ := Z;

    X.x = c*LX.x + s*LX.y;
    Y.x = c*LY.x + s*LY.y;
    Z.x = c*LZ.x + s*LZ.y;

    X.y = c*LX.y - s*LX.z;
    Y.y = c*LY.y - s*LY.z;
    Z.y = c*LZ.y - s*LZ.z;
};
roll4 :: inline proc(angle: f32, using out: ^mat4) {
    s := sin(angle);
    c := cos(angle);

    LX := X;
    LY := Y;
    LZ := Z;
    LW := W;

    X.x = c*LX.x + s*LX.y;
    Y.x = c*LY.x + s*LY.y;
    Z.x = c*LZ.x + s*LZ.y;
    W.x = c*LW.x + s*LW.y;

    X.y = c*LX.y - s*LX.z;
    Y.y = c*LY.y - s*LY.z;
    Z.y = c*LZ.y - s*LZ.z;
    W.y = c*LW.y - s*LW.z;
};
roll :: proc{roll3, roll4};