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

cross2 :: inline proc(a, b: vec2) -> f32 do return a.x*b.y - a.y*b.x;
cross :: proc{cross2};

squared_length2 :: inline proc(v: vec2) -> f32 do return dot2(v, v);
squared_length3 :: inline proc(v: vec3) -> f32 do return dot3(v, v);
squared_length4 :: inline proc(v: vec4) -> f32 do return dot4(v, v);
squared_length :: proc{squared_length2, squared_length3, squared_length4};

length2 :: inline proc(v: vec2) -> f32 do return sqrt(squared_length2(v));
length3 :: inline proc(v: vec3) -> f32 do return sqrt(squared_length3(v));
length4 :: inline proc(v: vec4) -> f32 do return sqrt(squared_length4(v));
length :: proc{length2, length3, length4};

norm2 :: inline proc(v: vec2) -> vec2 do return v/length2(v);
norm3 :: inline proc(v: vec3) -> vec3 do return v/length3(v);
norm4 :: inline proc(v: vec4) -> vec4 do return v/length4(v);
norm :: proc{norm2, norm3, norm4};

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