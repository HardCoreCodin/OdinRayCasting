package application

RayHit :: struct {
    is_vertical: bool,
    texture_id: u8,
    position: vec2
}
Ray :: struct {
    direction: vec2,
    
    is_facing_up,
    is_facing_down,
    is_facing_left,
    is_facing_right: bool,

    hit: RayHit
}
horizontal_hit: RayHit;
vertical_hit: RayHit = {is_vertical=true};
all_rays: [MAX_WIDTH]Ray;
rays: []Ray;

findHit :: proc(using hit: ^RayHit, inc: vec2, dec_x: bool = false, dec_y: bool = false) {
    tile: ^Tile;
    x, y: i32;

    // Increment inc until we find a wall
    found: bool;
    for !found {
        x = i32((dec_x ? (position.x - 1) : position.x) / TILE_SIZE);
        y = i32((dec_y ? (position.y - 1) : position.y) / TILE_SIZE);

        if inRange(x, MAP_WIDTH) && 
           inRange(y, MAP_HEIGHT) {
            tile = &tile_map[y][x];
            if tile.is_full {
                texture_id = tile.texture_id;
                found = true;
            } else do position += inc;
        } else do found = true;
    }
}

castRay :: proc(using ray: ^Ray) {
    using camera.xform;
    size := f32(TILE_SIZE);
    inc: vec2;
    islope := direction.x / direction.y;
    slope  := direction.y / direction.x;
    slope_is_positive := slope > 0;
    slope_is_negative := !slope_is_positive;
    
    // HORIZONTAL:
    invert := (is_facing_left && slope_is_positive) != (is_facing_right && slope_is_negative); 
    horizontal_hit.position.y = f32(i32(position.y / size) * TILE_SIZE) + (is_facing_down ? size : 0);
    horizontal_hit.position.x = position.x + (horizontal_hit.position.y - position.y) * islope;
    inc.y = is_facing_up ? -size : size;
    inc.x = islope * (invert ? -size : size);
    findHit(&horizontal_hit, inc, false, is_facing_up);

    // VERTICAL:
    invert = (is_facing_up && slope_is_positive) != (is_facing_down && slope_is_negative);    
    vertical_hit.position.x = f32(i32(position.x / size) * TILE_SIZE) + (is_facing_right ? size : 0);
    vertical_hit.position.y = position.y + (vertical_hit.position.x - position.x) * slope;
    inc.x = is_facing_left ? -size : size;
    inc.y = slope * (invert ? -size : size);
    findHit(&vertical_hit, inc, is_facing_left);
    
    hit = squared_length(horizontal_hit.position - position) < 
          squared_length(vertical_hit.position - position) ? horizontal_hit : vertical_hit;
}

setRayDirections :: proc() {
    using camera;
    using xform;
    ray_direction := forward_direction^ * focal_length;
    ray_direction -= right_direction^;
    ray_direction *= f32(len(rays)) / 2;
    ray_direction += right_direction^ / 2;

    for ray in &rays {
        using ray;
        direction = norm(ray_direction);
        is_facing_right = direction.x > 0;
        is_facing_down  = direction.y > 0;    
        is_facing_left = !is_facing_right;
        is_facing_up   = !is_facing_down;

        ray_direction += right_direction^;
    }
}

setRayCount :: inline proc(count: i32) {
    rays = all_rays[:count];
}

castRays :: inline proc() {
    for ray in &rays do castRay(&ray);
}