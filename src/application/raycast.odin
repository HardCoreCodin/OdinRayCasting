package application

RayHit :: struct {
    is_vertical: bool,
    texture_id: u8,
    position, t_position: vec2
}
Ray :: struct {
    origin: ^vec2,
    direction: vec2,
    slope, islope: f32,

    is_facing_up,
    is_facing_down,
    is_facing_left,
    is_facing_right,
    is_horizontal,
    is_vertical: bool,

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
        x = i32((dec_x ? (position.x - 1) : position.x) / f32(tile_map.tile_size));
        y = i32((dec_y ? (position.y - 1) : position.y) / f32(tile_map.tile_size));

        if inRange(x, tile_map.width) && 
           inRange(y, tile_map.height) {
            tile = &tile_map.tiles[y][x];
            if tile.is_full {
                texture_id = tile.texture_id;
                found = true;
            } else do position += inc;
        } else do found = true;
    }
}

castRay :: proc(using ray: ^Ray) {
    size := f32(tile_map.tile_size);
    inc: vec2;
    slope_is_positive := slope > 0;
    slope_is_negative := !slope_is_positive;
    
    // HORIZONTAL:
    invert := (is_facing_left && slope_is_positive) != (is_facing_right && slope_is_negative); 
    horizontal_hit.position.y = f32(i32(origin.y / size) * tile_map.tile_size) + (is_facing_down ? size : 0);
    horizontal_hit.position.x = origin.x + (horizontal_hit.position.y - origin.y) * islope;
    inc.y = is_facing_up ? -size : size;
    inc.x = islope * (invert ? -size : size);
    findHit(&horizontal_hit, inc, false, is_facing_up);

    // VERTICAL:
    invert = (is_facing_up && slope_is_positive) != (is_facing_down && slope_is_negative);    
    vertical_hit.position.x = f32(i32(origin.x / size) * tile_map.tile_size) + (is_facing_right ? size : 0);
    vertical_hit.position.y = origin.y + (vertical_hit.position.x - origin.x) * slope;
    inc.x = is_facing_left ? -size : size;
    inc.y = slope * (invert ? -size : size);
    findHit(&vertical_hit, inc, is_facing_left);
    
    hit = squared_length(horizontal_hit.position - origin^) < 
          squared_length(vertical_hit.position - origin^) ? horizontal_hit : vertical_hit;
}

rayIntersectsWithEdge :: proc(ray: ^Ray, using edge: ^TileEdge, pos: ^vec2) -> bool {
    if (ray.is_horizontal && is_horizontal) ||
       (ray.is_vertical  && !is_horizontal) do
       return false;

    found: bool;
    if is_horizontal {
        pos.x = t_to.y;
        pos.y = t_to.y;
        pos.x *= ray.islope;
        found = ((ray.direction.x > 0) == (pos.x > 0)) && ((ray.direction.y > 0) == (pos.y > 0)) && inRange(pos.x, t_to.x, t_from.x);
    } else {
        pos.x = t_to.x;
        pos.y = t_to.x;
        pos.y *= ray.slope;
        found = ((ray.direction.x > 0) == (pos.x > 0)) && ((ray.direction.y > 0) == (pos.y > 0)) && inRange(pos.y, t_to.y, t_from.y);
    }

    return found;
}

castRay2 :: proc(using ray: ^Ray) {
    closest_hit_position, current_hit_position: vec2;
    closest_length: f32 = 100000; 
    current_length: f32;

    for edge in &tile_map.edges do 
        if edge.is_facing_forward do 
            if rayIntersectsWithEdge(ray, &edge, &current_hit_position) {
                current_length = squared_length(current_hit_position);
                if closest_length > current_length {
                    closest_length = current_length;
                    closest_hit_position = current_hit_position;
                }
            }

    hit.position = closest_hit_position + origin^;
}

generateRays :: proc(using cam: ^Camera2D) {
    using xform;
    ray_direction := forward_direction^ * focal_length;
    ray_direction -= right_direction^;
    ray_direction *= f32(len(rays)) / 2;
    ray_direction += right_direction^ / 2;

    for ray in &rays {
        using ray;
        origin = &position;
        direction = norm(ray_direction);
        slope = direction.y / direction.x;
        islope = 1 / slope;

        is_facing_right = direction.x > 0;
        is_facing_down  = direction.y > 0;    
        is_facing_left = !is_facing_right;
        is_facing_up   = !is_facing_down;
        is_vertical    = direction.x == 0;
        is_horizontal  = direction.y == 0;

        ray_direction += right_direction^;
    }
}

setRayCount :: inline proc(count: i32) {
    rays = all_rays[:count];
}

castRays :: inline proc() {
    for ray in &rays do castRay(&ray);
}