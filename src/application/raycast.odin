package application

RayHit :: struct {
    position: vec2,
    distance,
    edge_fraction,
    tile_fraction: f32,
    tile: ^Tile,
    edge: ^TileEdge
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

VerticalHitInfo :: struct {
    distance, dim_factor: f32,
    mip_level: u8
}
all_vertical_hit_infos: [FRAME_BUFFER__MAX_HEIGHT/2]VerticalHitInfo;
vertical_hit_infos: []VerticalHitInfo;

VerticalHit :: struct {
    info: ^VerticalHitInfo,
    floor_texture, 
    ceiling_texture: ^Bitmap,
    
    direction: vec2,
    tile_coords: vec2i,
    
    u, v: f32,
    found: bool
}

VerticalHitRow :: []VerticalHit;
VerticalHitGrid :: []VerticalHitRow;

all_vertical_hits: VerticalHitRow;
all_vertical_hit_rows: [FRAME_BUFFER__MAX_HEIGHT/2]VerticalHitRow;
vertical_hits: VerticalHitGrid;

distance_factor: f32 = DIM_FACTOR_RANGE / MAX_TILE_MAP_VIEW_DISTANCE;
half_width,
half_height: f32;

initRayCast :: proc() {
    bits := new([FRAME_BUFFER__MAX_WIDTH * (FRAME_BUFFER__MAX_HEIGHT * 2)]VerticalHit);
    all_vertical_hits = bits^[:];

    onResize();
}

onResize :: proc() {
    using frame_buffer;

    half_width = f32(width) / 2;
    half_height = f32(height) / 2;

    half_height_int := height / 2;

    rays = all_rays[:width];
    vertical_hit_infos = all_vertical_hit_infos[:half_height_int];

    start: i32;
    end := width;

    for y in 0..<half_height_int {
        all_vertical_hit_rows[y] = all_vertical_hits[start:end];
        start += width;
        end   += width;
    }

    vertical_hits = all_vertical_hit_rows[:half_height_int];

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

    num_vertical_hit_infos := len(vertical_hit_infos); 

    vertical_hit_info: ^VerticalHitInfo;
    for y in 1..num_vertical_hit_infos {
        vertical_hit_info = &vertical_hit_infos[num_vertical_hit_infos - y];
        using vertical_hit_info;
        distance = 1 / (2 * f32(y));
        dim_factor = 1 - distance * half_height * distance_factor + MIN_DIM_FACTOR;
        mip_level = u8(f32(MIP_COUNT/2) * (1 - f32(y) / f32(num_vertical_hit_infos))); 
    }

    vertical_hit: ^VerticalHit;
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
        ray_direction += right_direction^;

        for info, y in &vertical_hit_infos {
            vertical_hit = &vertical_hits[y][x];
            vertical_hit.direction = ray_direction * info.distance;
            vertical_hit.info = &info;
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

castRay :: proc(using ray: ^Ray, using tm: ^TileMap) {
    closest_hit, current_hit: RayHit;
    closest_hit.distance = 1000000;
    for edge in &edges do if edge.is_facing_forward && rayIntersectsWithEdge(ray, &edge, &current_hit) {
        current_hit.distance = squared_length(current_hit.position);
        if current_hit.distance < closest_hit.distance do closest_hit = current_hit;
    }
    hit = closest_hit;
    using hit;
    position += origin^;
    distance = sqrt(distance);

    tile_index: vec2i = {
        i32(position.x),
        i32(position.y)
    };
    if edge.is_vertical {
        edge_fraction = position.y - f32(edge.from.y);
        if edge.is_facing_right do tile_index.x -= 1;
    } else {
        edge_fraction = position.x - f32(edge.from.x);
        if edge.is_facing_down do tile_index.y -= 1;
    }

    tile = &tile_map.tiles[tile_index.y][tile_index.x];
    tile_fraction = edge_fraction - f32(i32(edge_fraction));
}

castRays :: inline proc(using tm: ^TileMap) {
    for ray in &rays do castRay(&ray, tm);

    pos: vec2;
    using camera.xform;

    for row in &vertical_hits {
        for hit in &row {
            using hit;
            pos = position + direction;
            found = inRange(0, pos.x, f32(width-1)) &&
                    inRange(0, pos.y, f32(height-1));

            if found {
                tile_coords.x = i32(pos.x);
                tile_coords.y = i32(pos.y);
                // floor_texture   = &textures[tiles[tile_coords.y][tile_coords.x].texture_id];
                // ceiling_texture = &textures[tiles[tile_coords.y][tile_coords.x].texture_id];
                u = pos.x - f32(tile_coords.x);
                v = pos.y - f32(tile_coords.y);
            }
        } 
    }
}

horizontal_hit, vertical_hit: RayHit;

castRayWolf3D :: proc(using ray: ^Ray) {    
    horizontal_hit.position.y = origin.y;
    if is_facing_down do horizontal_hit.position.y += 1;
    horizontal_hit.position.x = origin.x + (horizontal_hit.position.y - origin.y) * run_over_rise;
    inc_y: f32 = is_facing_up ? -1 : 1;
    inc_x: f32 = run_over_rise * ((is_facing_left && rise_over_run > 0) != (is_facing_right && rise_over_run < 0) ? -1 : 1);
    findHit(&horizontal_hit, inc_x, inc_y, false, is_facing_up);

    vertical_hit.position.x = origin.x;
    if is_facing_right do vertical_hit.position.x += 1;
    vertical_hit.position.y = origin.y + (vertical_hit.position.x - origin.x) * rise_over_run;
    inc_x = is_facing_left ? -1 : 1;
    inc_y = rise_over_run * ((is_facing_up && rise_over_run > 0) != (is_facing_down && rise_over_run < 0) ? -1 : 1);
    findHit(&vertical_hit, inc_x, inc_y, is_facing_left, false);
    
    horizontal_hit.distance = squared_length(horizontal_hit.position - origin^);
      vertical_hit.distance = squared_length(  vertical_hit.position - origin^);
    hit = horizontal_hit.distance < vertical_hit.distance ? horizontal_hit : vertical_hit;
    hit.distance = sqrt(hit.distance);
}

findHit :: proc(using hit: ^RayHit, inc_x, inc_y: f32, dec_x, dec_y: bool) {
    x, y: i32;
    found: bool;
    end_x := tile_map.width  - 1;
    end_y := tile_map.height - 1;
    for !found {
        x = i32(dec_x ? (position.x - 1) : position.x);
        y = i32(dec_y ? (position.y - 1) : position.y);

        if inRange(0, x, end_x) && 
           inRange(0, y, end_y) {
            tile = &tile_map.tiles[y][x];
            if tile.is_full {
                found = true;
            } else {
                position.x += inc_x;
                position.y += inc_y;
            }
        } else do found = true;
    }
}
