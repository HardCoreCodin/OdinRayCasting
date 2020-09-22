package application

// import "../textures"

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

castRay :: proc(using ray: ^Ray) {
    closest_hit, current_hit: RayHit;
    closest_hit.distance = 1000000;
    for edge in &tile_map.edges do if edge.is_facing_forward && rayIntersectsWithEdge(ray, &edge, &current_hit) {
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
        rise_over_run = direction.y / direction.x;
        run_over_rise = 1 / rise_over_run;

        is_vertical    = direction.x == 0;
        is_horizontal  = direction.y == 0;
        is_facing_left = direction.x < 0;
        is_facing_up   = direction.y < 0;
        is_facing_right = direction.x > 0;
        is_facing_down  = direction.y > 0;

        ray_direction += right_direction^;
    }
}

setRayCount :: inline proc(count: i32) {
    rays = all_rays[:count];
}

castRays :: inline proc() {
    for ray in &rays do castRay(&ray);
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

drawWalls :: proc(using cam: ^Camera2D) {
    using xform;
    using frame_buffer;

    top, bottom, 
    pixel_offset,
    column_height: i32;

    texel_height,
    distance, u, v: f32;
    tiles_to_projection_plane := f32(width) * focal_length * TILE_SIZE;

    for ray, x in &rays {
        using ray;

        distance = dot((hit.position - position)*TILE_SIZE, forward_direction^);
        if distance < 0 do distance = -distance;
        
        column_height = i32(tiles_to_projection_plane / distance);

        top    = column_height < height ? (height - column_height) / 2 : 0;
        bottom = column_height < height ? (height + column_height) / 2 : height;


        // Draw the floor and ceiling
        drawVLine2D(0     , top   , i32(x), CEILING_COLOR, &bitmap);
        // drawVLine2D(top   , bottom, i32(x), RED, &bitmap);
        drawVLine2D(bottom, height, i32(x), FLOOR_COLOR  , &bitmap);

        texel_height = 1 / f32(column_height);
        v = column_height > height ? f32((column_height - height) / 2) * texel_height : 0;
        
        // Draw the wall
        pixel_offset = top * width + i32(x);
        for y in top..<bottom {
            all_pixels[pixel_offset] = sampleBitmap(&textures[hit.tile.texture_id], hit.tile_fraction, v);

            pixel_offset += width;
            v += texel_height;
        }
    }
}
    

// castRayWolf3D :: proc(using ray: ^Ray) {
//     size := f32(tile_map.tile_size);
//     factor :=  1 / size;
    
//     horizontal_hit.position.y = f32(i32(factor * origin.y) * tile_map.tile_size) + (is_facing_down ? size : 0);
//     horizontal_hit.position.x = origin.x + (horizontal_hit.position.y - origin.y) * run_over_rise;
//     inc_y := is_facing_up ? -size : size;
//     inc_x := run_over_rise * ((is_facing_left && rise_over_run > 0) != (is_facing_right && rise_over_run < 0) ? -size : size);
//     findHit(&horizontal_hit, factor, inc_x, inc_y, false, is_facing_up);

//     vertical_hit.position.x = f32(i32(factor * origin.x) * tile_map.tile_size) + (is_facing_right ? size : 0);
//     vertical_hit.position.y = origin.y + (vertical_hit.position.x - origin.x) * rise_over_run;
//     inc_x = is_facing_left ? -size : size;
//     inc_y = rise_over_run * ((is_facing_up && rise_over_run > 0) != (is_facing_down && rise_over_run < 0) ? -size : size);
//     findHit(&vertical_hit, factor, inc_x, inc_y, is_facing_left, false);
    
//     horizontal_hit.distance = squared_length(horizontal_hit.position - origin^);
//       vertical_hit.distance = squared_length(  vertical_hit.position - origin^);
//     hit = horizontal_hit.distance < vertical_hit.distance ? horizontal_hit : vertical_hit;
//     hit.distance = sqrt(hit.distance);
// }
// findHit :: proc(using hit: ^RayHit, factor, inc_x, inc_y: f32, dec_x, dec_y: bool) {
//     tile: ^Tile;
//     x, y: i32;
//     found: bool;
//     end_x := tile_map.width  - 1;
//     end_y := tile_map.height - 1;
//     for !found {
//         x = i32(factor * (dec_x ? (position.x - 1) : position.x));
//         y = i32(factor * (dec_y ? (position.y - 1) : position.y));

//         if inRange(0, x, end_x) && 
//            inRange(0, y, end_y) {
//             tile = &tile_map.tiles[y][x];
//             if tile.is_full {
//                 texture_id = tile.texture_id;
//                 found = true;
//             } else {
//                 position.x += inc_x;
//                 position.y += inc_y;
//             }
//         } else do found = true;
//     }
// }
