package application

vec2i :: [2]i32;

vec2 :: [2]f32;
vec3 :: [3]f32;
vec4 :: [4]f32;

non_zero2 :: inline proc(v: vec2) -> bool do return v.x != 0 || v.y != 0;
non_zero3 :: inline proc(v: vec3) -> bool do return v.x != 0 || v.y != 0 || v.z != 0;
non_zero4 :: inline proc(v: vec4) -> bool do return v.x != 0 || v.y != 0 || v.z != 0 || v.w != 0;
non_zero :: proc{non_zero2, non_zero3, non_zero4};

perp :: inline proc(v: vec2) -> vec2 do return vec2{-v.y, v.x};

dot2 :: inline proc(a, b: vec2) -> f32 do return a.x*b.x + a.y*b.y;
dot3 :: inline proc(a, b: vec3) -> f32 do return a.x*b.x + a.y*b.y + a.z*b.z;
dot4 :: inline proc(a, b: vec4) -> f32 do return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w;
dot :: proc{dot2, dot3, dot4};

cross2 :: inline proc(a, b: vec2) -> f32 do return 
    a.x*b.y - 
    a.y*b.x;
cross3 :: inline proc(a, b: vec3) -> vec3 do return vec3{ 
    a.y*b.z - a.z*b.y,
    a.z*b.x - a.x*b.z,
    a.x*b.y - a.y*b.x
};
cross :: proc{cross2, cross3};

conj :: inline proc(q: Quaternion) -> Quaternion do return Quaternion{-q.v, q.w};
mul :: inline  proc(q1, q2: Quaternion) -> Quaternion {

    out : Quaternion;
    out.v.x =  q1.v.x * q2.w + q1.v.y * q2.v.z - q1.v.z * q2.v.y + q1.w * q2.v.x;
    out.v.y = -q1.v.x * q2.v.z + q1.v.y * q2.w + q1.v.z * q2.v.x + q1.w * q2.v.y;
    out.v.z =  q1.v.x * q2.v.y - q1.v.y * q2.v.x + q1.v.z * q2.w + q1.w * q2.v.z;

    out.w = -q1.v.x * q2.v.x - q1.v.y * q2.v.y - q1.v.z * q2.v.z + q1.w * q2.w;
    return out;
};

Quaternion :: struct {v: vec3, w: f32}

getRotation :: inline proc(a, b: vec3) -> Quaternion {
    q: Quaternion = {
        cross(a, b),
        dot(a, b) + 1 
    };
    norm(&q);
    return q;
}
getRotationFromUp :: inline proc(a: vec3) -> Quaternion {
    using q: Quaternion;
    v.x = -a.z;
    v.z =  a.x;
    w   =  a.y + 1;
    
    li := 1 / sqrt(v.x*v.x + v.z*v.z + w*w);
    
    w   *= li;
    v.x *= li;
    v.z *= li;
    
    return q;
}
rotateQ :: inline proc(V: vec3, using q: Quaternion) -> vec3 do return 
    (w*w - dot(v, v)) * V +
    2 *    dot(v, V) * v +  
    2*w* cross(v, V);

squared_length2 :: inline proc(v: vec2) -> f32 do return dot2(v, v);
squared_length3 :: inline proc(v: vec3) -> f32 do return dot3(v, v);
squared_length4 :: inline proc(v: vec4) -> f32 do return dot4(v, v);
squared_lengthQ :: inline proc(q: Quaternion) -> f32 do return dot3(q.v, q.v) + q.w*q.w;
squared_length :: proc{squared_length2, squared_length3, squared_length4, squared_lengthQ};

length2 :: inline proc(v: vec2) -> f32 do return sqrt(squared_length2(v));
length3 :: inline proc(v: vec3) -> f32 do return sqrt(squared_length3(v));
length4 :: inline proc(v: vec4) -> f32 do return sqrt(squared_length4(v));
lengthQ :: inline proc(q: Quaternion) -> f32 do return sqrt(squared_lengthQ(q));
length :: proc{length2, length3, length4, lengthQ};

norm2 :: inline proc(v: vec2) -> vec2 do return v/length2(v);
norm3 :: inline proc(v: vec3) -> vec3 do return v/length3(v);
norm4 :: inline proc(v: vec4) -> vec4 do return v/length4(v);
normQ :: inline proc(q: Quaternion) -> Quaternion {
    l := lengthQ(q);
    return Quaternion{
        v = q.v / l,
        w = q.w / l
    };
}
inormQ :: inline proc(q: ^Quaternion) {
    l := lengthQ(q^);
    q.v /= l;
    q.w /= l;
}
norm :: proc{norm2, norm3, norm4, normQ, inormQ};

dist2 :: inline proc(from, to: ^vec2) -> f32 do return length2(to^ - from^);
dist3 :: inline proc(from, to: ^vec3) -> f32 do return length3(to^ - from^);
dist4 :: inline proc(from, to: ^vec4) -> f32 do return length4(to^ - from^);
dist :: proc{dist2, dist3, dist4};

approach2D :: inline proc(current, target: ^vec2, delta: f32) {
    for target_value, i in target do switch {
        case current[i] + delta < target_value: current[i] += delta;
        case current[i] - delta > target_value: current[i] -= delta;
        case                                  : current[i]  = target_value;
    }
}
approach3D :: inline proc(current, target: ^vec3, delta: f32) {
    for target_value, i in target do switch {
        case current[i] + delta < target_value: current[i] += delta;
        case current[i] - delta > target_value: current[i] -= delta;
        case                                  : current[i]  = target_value;
    }
}
approach :: proc{approach2D, approach3D};