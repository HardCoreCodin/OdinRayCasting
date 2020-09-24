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
all_rays: [MAX_BITMAP_WIDTH]Ray;
rays: []Ray;

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
        is_vertical     = direction.x == 0;
        is_horizontal   = direction.y == 0;
        is_facing_left  = direction.x < 0;
        is_facing_up    = direction.y < 0;
        is_facing_right = direction.x > 0;
        is_facing_down  = direction.y > 0;
        rise_over_run = direction.y / direction.x;
        run_over_rise = 1 / rise_over_run;
        ray_direction += right_direction^;
    }
}

setRayCount :: inline proc(count: i32) {
    rays = all_rays[:count];
}

castRays :: inline proc(tm: ^TileMap) {
    for ray in &rays do castRay(&ray, tm);
    // for ray in &rays do castRayWolf3D(&ray);
}

CEILING_COLOR: Color = {
    R = 44,
    G = 44,
    B = 44
};
FLOOR_COLOR: Color = {
    R = 88,
    G = 88,
    B = 88
};

MIN_DIM_FACTOR :: 0.1;
MAX_DIM_FACTOR :: 2;
DIM_FACTOR_RANGE :: MAX_DIM_FACTOR - MIN_DIM_FACTOR;

drawWalls :: proc(using cam: ^Camera2D) {
    using xform;
    using frame_buffer;

    top, bottom, 
    pixel_offset,
    column_height: i32;

    texel_height,
    distance, dim_factor, u, v: f32;
    tiles_to_projection_plane := f32(width / 2) * focal_length;

    texture: ^Bitmap;
    pixel: Pixel;

    distance_factor: f32 = DIM_FACTOR_RANGE / MAX_TILE_MAP_VIEW_DISTANCE;

    for ray, x in &rays {
        using ray;

        texture = &textures[hit.tile.texture_id];

        distance = dot((hit.position - position), forward_direction^);
        if distance < 0 do distance = -distance;
        
        dim_factor = 1 - distance * distance_factor + MIN_DIM_FACTOR;

        column_height = i32(tiles_to_projection_plane / distance);

        top    = column_height < height ? (height - column_height) / 2 : 0;
        bottom = column_height < height ? (height + column_height) / 2 : height;


        // Draw the floor and ceiling
        drawVLine2D(&bitmap, 0     , top   , i32(x), CEILING_COLOR);
        // drawVLine2D(&bitmap, top   , bottom, i32(x), RED);
        drawVLine2D(&bitmap, bottom, height, i32(x), FLOOR_COLOR);

        texel_height = 1 / f32(column_height);
        v = column_height > height ? f32((column_height - height) / 2) * texel_height : 0;
        
        // Draw the wall
        pixel_offset = top * width + i32(x);
        for y in top..<bottom {
            sampleBitmap(texture, hit.tile_fraction, v, &pixel);

            pixel.color.R = u8(clamp(dim_factor * f32(pixel.color.R), 0, MAX_COLOR_VALUE));
            pixel.color.G = u8(clamp(dim_factor * f32(pixel.color.G), 0, MAX_COLOR_VALUE));
            pixel.color.B = u8(clamp(dim_factor * f32(pixel.color.B), 0, MAX_COLOR_VALUE));

            all_pixels[pixel_offset] = pixel;

            pixel_offset += width;
            v += texel_height;
        }
    }
}  

MAX_COLOR_VALUE :: 0xFF;

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
