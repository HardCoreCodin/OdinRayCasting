package application

RayHit :: struct {
    tile_coords: vec2i,
    position: vec2,

    distance,
    edge_fraction,
    tile_fraction: f32,
    
    edge: ^TileEdge,
    column: ^Circle,
    texture_id: u8
}
Ray :: struct {     
    origin: ^vec2,
    direction: vec2,
    
    rise_over_run,
    run_over_rise: f32,

    is_vertical,
    is_horizontal,
    is_facing_up,
    is_facing_down,
    is_facing_left,
    is_facing_right: bool,

    hit: RayHit
}
all_rays: [FRAME_BUFFER__MAX_WIDTH]Ray;
rays: []Ray;

VerticalHitLevel :: struct #align(16) {
    distance, 
    dim_factor,
    mip_factor: f32,
    mip_level: u8,
}
VerticalHit :: struct {
    dim_factor: f32,
    direction: vec2,
    tile_coords: vec2i,
    u, v: f32,

    floor_texture_id,
    ceiling_texture_id: u8,

    found: bool
}
vertical_hit_levels: [FRAME_BUFFER__MAX_HEIGHT / 2]VerticalHitLevel; 
vertical_hits_buffer: [FRAME_BUFFER__MAX_WIDTH * (FRAME_BUFFER__MAX_HEIGHT / 2)]VerticalHit;
vertical_hits: Grid(VerticalHit);

horizontal_distance_factor: f32 = 20 * DIM_FACTOR_RANGE / MAX_TILE_MAP_VIEW_DISTANCE;
vertical_distance_factor: f32;

half_width,
half_height: f32;

initRayCast :: proc() {
    onResize();
}

onResize :: proc() {
    using frame_buffer;
    half_width = f32(width) / 2;
    half_height = f32(height) / 2;
    half_height_int := height / 2;
    vertical_distance_factor = f32(DIM_FACTOR_RANGE) / f32(height);

    rays = all_rays[:width];

    initGrid(&vertical_hits, width, half_height_int, vertical_hits_buffer[:]);

    current_mip_level: f32 = f32(len(wall_textures[0].bitmaps));  
    current_mip_levelI: i32;

    vertical_hit_level: ^VerticalHitLevel; 

    for y in 1..<half_height_int {
        vertical_hit_level = &vertical_hit_levels[half_height_int - y];
        using vertical_hit_level;

        distance = camera.focal_length / f32(2 * y);
        dim_factor = 1.1 / (1 + distance * half_width);// + MIN_DIM_FACTOR;

        current_mip_level *= 0.975;
        current_mip_levelI = i32(current_mip_level);
        
        mip_level = u8(current_mip_levelI);
        mip_factor = current_mip_level - f32(current_mip_levelI);
    }
    generateRays();
    castRays(&tile_map);
}

onFocalLengthChanged :: proc() {
    generateRays();
}

generateRays :: proc() {
    using camera;
    using xform;
    ray_direction := forward_direction^ * focal_length;
    ray_direction -= right_direction^;
    ray_direction *= half_width;
    ray_direction += right_direction^ / 2;

    vertical_hit: ^VerticalHit;
    vertical_hit_level: ^VerticalHitLevel;
    for ray, x in &rays {
        using ray;
        origin = &position;
        direction = norm(ray_direction);
        is_vertical     = direction.x == 0;
        is_horizontal   = direction.y == 0;
        is_facing_left  = direction.x < 0;
        is_facing_up    = direction.y < 0;
        is_facing_right = direction.x > 0;
        is_facing_down  = direction.y > 0;
        rise_over_run = direction.y / direction.x;
        run_over_rise = 1 / rise_over_run;

        for vertical_hit_row, y in &vertical_hits.cells {
            if y == 0 do continue;

            vertical_hit_level = &vertical_hit_levels[y];
            vertical_hit = &vertical_hit_row[x];
            vertical_hit.direction = ray_direction;
            vertical_hit.direction *= vertical_hit_level.distance;
            vertical_hit.dim_factor = max(vertical_hit_level.dim_factor, 1.5 / max(1, 0.25 + squared_length(vertical_hit.direction)));
        }

        ray_direction += right_direction^;
    }
}

Plane :: struct { position, normal: vec2}
EPS :: 0.000001;

getU :: proc(v: vec2) -> f32 {
    u := v.y / v.x;
    if u > 1 || u < -1 do u = -1 / u;
    return (u + 1) * 0.5;
}

rayIntersectsWithPlane :: proc(ray: ^Ray, plane: ^Plane, hit: ^RayHit) -> bool {
    RD_dot_N := dot2(ray.direction, plane.normal);                if RD_dot_N > 0 || -RD_dot_N < EPS do return false;
    RP_dot_N := dot2(plane.position - ray.origin^, plane.normal);  if RP_dot_N > 0 || -RP_dot_N < EPS do return false;
    t := RP_dot_N / RD_dot_N;
    ray.hit.position = ray.origin^ + t*ray.direction;
    return true;
}

rayIntersectsWithCircle :: proc(ray: ^Ray, circle: ^Circle, using hit: ^RayHit) {
    C := circle.position - ray.origin^;
    t := dot(C, ray.direction);
    if (t > 0) {
        dt := circle.radius * circle.radius - squared_length(ray.direction * t - C);
        if (dt > 0 && t*t > dt) { // Inside the sphere
            t -= sqrt(dt);
            if column != nil ? t < distance : t*t < distance {
                distance = t;
                column = circle;
            }
        }
    }
}

rayIntersectsWithEdge :: proc(ray: ^Ray, edge: ^TileEdge, hit: ^RayHit) -> bool {
    hit.edge = edge;
    using edge.local;

    if edge.is_vertical {
        if ray.is_vertical || (is_left && ray.is_facing_right) || (is_right && ray.is_facing_left) do return false;
        hit.position = to.x;
        hit.position.y *= ray.rise_over_run;
        return inRange(from.y, hit.position.y, to.y);
    } else { // Edge is horizontal:
        if ray.is_horizontal || (is_below && ray.is_facing_up) || (is_above && ray.is_facing_down) do return false;
        hit.position = to.y;
        hit.position.x *= ray.run_over_rise;
        return inRange(from.x, hit.position.x, to.x);
    }

    return false;
}

castRays :: inline proc(using tm: ^TileMap) {
    pos: vec2;
    using camera.xform;
    last_tile_coords: vec2i = {-1, -1};
    last_tile_texture_id: u8;

    closest_hit, current_hit: RayHit;

    for ray in &rays {
        using ray;
        closest_hit.distance = 1000000;
        
        for edge in &edges do if edge.is_facing_forward && rayIntersectsWithEdge(&ray, &edge, &current_hit) {
            current_hit.distance = squared_length(current_hit.position);
            if current_hit.distance < closest_hit.distance do closest_hit = current_hit;
        }

        for column_id in 0..<column_count do rayIntersectsWithCircle(&ray, &columns[column_id], &closest_hit);

        hit = closest_hit;
        using hit;

        if column != nil {
            position = origin^ + direction * distance;
            tile_coords.x = i32(position.x);
            tile_coords.y = i32(position.y);
            tile_fraction = getU(position - column.position);
            tile_fraction *= column.radius;
            tile_fraction -= f32(i32(tile_fraction));
            texture_id = columns_texture_id;
        } else {
            position += origin^;
            distance = sqrt(distance);

            tile_coords.x = i32(position.x);
            tile_coords.y = i32(position.y);

            if edge.is_vertical {
                edge_fraction = position.y - f32(edge.from.y);
                if edge.is_facing_right do tile_coords.x -= 1;
            } else {
                edge_fraction = position.x - f32(edge.from.x);
                if edge.is_facing_down do tile_coords.y -= 1;
            }
            tile_fraction = edge_fraction - f32(i32(edge_fraction)); 

            if tile_coords.x != last_tile_coords.x ||
               tile_coords.y != last_tile_coords.y {

                last_tile_texture_id = cells[tile_coords.y][tile_coords.x].texture_id;
                last_tile_coords = tile_coords;
            }

            texture_id = last_tile_texture_id;   
        }
    }

    for vertical_hit_row in &vertical_hits.cells {
        for vertical_hit in &vertical_hit_row {
            using vertical_hit;
            pos = position + direction;
            found = inRange(0, pos.x, f32(width-1)) &&
                    inRange(0, pos.y, f32(height-1));

            if found {
                tile_coords.x = i32(pos.x);
                tile_coords.y = i32(pos.y);
                u = pos.x - f32(tile_coords.x);
                v = pos.y - f32(tile_coords.y);

                if tile_coords.x != last_tile_coords.x ||
                   tile_coords.y != last_tile_coords.y {

                    last_tile_texture_id = cells[tile_coords.y][tile_coords.x].texture_id;
                    last_tile_coords = tile_coords;
                }
            }
        } 
    }
}

// horizontal_hit, vertical_hit: RayHit;

// castRayWolf3D :: proc(using ray: ^Ray) {    
//     horizontal_hit.position.y = origin.y;
//     if is_facing_down do horizontal_hit.position.y += 1;
//     horizontal_hit.position.x = origin.x + (horizontal_hit.position.y - origin.y) * run_over_rise;
//     inc_y: f32 = is_facing_up ? -1 : 1;
//     inc_x: f32 = run_over_rise * ((is_facing_left && rise_over_run > 0) != (is_facing_right && rise_over_run < 0) ? -1 : 1);
//     findHit(&horizontal_hit, inc_x, inc_y, false, is_facing_up);

//     vertical_hit.position.x = origin.x;
//     if is_facing_right do vertical_hit.position.x += 1;
//     vertical_hit.position.y = origin.y + (vertical_hit.position.x - origin.x) * rise_over_run;
//     inc_x = is_facing_left ? -1 : 1;
//     inc_y = rise_over_run * ((is_facing_up && rise_over_run > 0) != (is_facing_down && rise_over_run < 0) ? -1 : 1);
//     findHit(&vertical_hit, inc_x, inc_y, is_facing_left, false);
    
//     horizontal_hit.distance = squared_length(horizontal_hit.position - origin^);
//       vertical_hit.distance = squared_length(  vertical_hit.position - origin^);
//     hit = horizontal_hit.distance < vertical_hit.distance ? horizontal_hit : vertical_hit;
//     hit.distance = sqrt(hit.distance);
// }

// findHit :: proc(using hit: ^RayHit, inc_x, inc_y: f32, dec_x, dec_y: bool) {
//     x, y: i32;
//     found: bool;
//     end_x := tile_map.width  - 1;
//     end_y := tile_map.height - 1;
//     for !found {
//         x = i32(dec_x ? (position.x - 1) : position.x);
//         y = i32(dec_y ? (position.y - 1) : position.y);

//         if inRange(0, x, end_x) && 
//            inRange(0, y, end_y) {
//             tile = &tile_map.tiles[y][x];
//             if tile.is_full {
//                 found = true;
//             } else {
//                 position.x += inc_x;
//                 position.y += inc_y;
//             }
//         } else do found = true;
//     }
// }
