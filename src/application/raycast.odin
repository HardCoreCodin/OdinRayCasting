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


VerticalHitInfo :: struct {
    distance, dim_factor: f32
}
all_vertical_hit_infos: [MAX_BITMAP_HEIGHT/2]VerticalHitInfo;
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
all_vertical_hit_rows: [MAX_BITMAP_HEIGHT/2]VerticalHitRow;
vertical_hits: VerticalHitGrid;

distance_factor: f32 = DIM_FACTOR_RANGE / MAX_TILE_MAP_VIEW_DISTANCE;
half_width,
half_height: f32;

TILE_MAP_TEXTURE_PIXEL_COUND :: MAX_TILE_MAP_SIZE*TEXTURE_SIZE;

TileMapTexture :: struct {
    using bitmap: Bitmap,
    bits: ^[TILE_MAP_TEXTURE_PIXEL_COUND]u32
};

floor_texture   := &textures[7];
ceiling_texture := &textures[3];

floor_tiles_texture,
wall_tiles_texture,
ceiling_tiles_texture: TileMapTexture;

initTileMapTexture :: proc(using tmt: ^TileMapTexture) {
    bits = new([TILE_MAP_TEXTURE_PIXEL_COUND]u32);
    initBitmap(&bitmap, 
        MAX_TILE_MAP_WIDTH * TEXTURE_WIDTH, 
        MAX_TILE_MAP_HEIGHT * TEXTURE_HEIGHT, 
        bits^[:]
    );
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

initRayCast :: proc() {
    bits := new([MAX_BITMAP_WIDTH*(MAX_BITMAP_HEIGHT*2)]VerticalHit);
    all_vertical_hits = bits^[:];

    onResize();

    initTileMapTexture(&wall_tiles_texture);
    initTileMapTexture(&floor_tiles_texture);
    initTileMapTexture(&ceiling_tiles_texture);

    drawFloorTilesTexture(&tile_map);
    drawCeilingTilesTexture(&tile_map);   
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
    max_distance := half_width * focal_length;

    vertical_hit: ^VerticalHit;
    texture: ^Bitmap;
    pixel: Pixel;

    floor_pixel_offset := size - width;
    ceiling_pixel_offset: i32;

    for vertical_hit_row, y in &vertical_hits {
        for vertical_hit, x in &vertical_hit_row {
            if !vertical_hit.found do continue;

            dim_factor = vertical_hit.info.dim_factor;

            sampleBitmap(floor_texture, vertical_hit.u, vertical_hit.v, &pixel);
            pixel.color.R = u8(clamp(dim_factor * f32(pixel.color.R), 0, MAX_COLOR_VALUE));
            pixel.color.G = u8(clamp(dim_factor * f32(pixel.color.G), 0, MAX_COLOR_VALUE));
            pixel.color.B = u8(clamp(dim_factor * f32(pixel.color.B), 0, MAX_COLOR_VALUE));
            all_pixels[floor_pixel_offset + i32(x)] = pixel;

            sampleBitmap(ceiling_texture, vertical_hit.u, vertical_hit.v, &pixel);
            pixel.color.R = u8(clamp(dim_factor * f32(pixel.color.R), 0, MAX_COLOR_VALUE));
            pixel.color.G = u8(clamp(dim_factor * f32(pixel.color.G), 0, MAX_COLOR_VALUE));
            pixel.color.B = u8(clamp(dim_factor * f32(pixel.color.B), 0, MAX_COLOR_VALUE));
            all_pixels[ceiling_pixel_offset + i32(x)] = pixel;
        }

        floor_pixel_offset   -= width;
        ceiling_pixel_offset += width;
    }

    for ray, x in &rays {
        using ray;

        texture = &textures[hit.tile.texture_id];

        distance = dot((hit.position - position), forward_direction^);
        if distance < 0 do distance = -distance;
        
        dim_factor = 1 - distance * distance_factor + MIN_DIM_FACTOR;

        column_height = i32(max_distance / distance);

        top    = column_height < height ? (height - column_height) / 2 : 0;
        bottom = column_height < height ? (height + column_height) / 2 : height;

        texel_height = 1 / f32(column_height);
        v = column_height > height ? f32((column_height - height) / 2) * texel_height : 0;
        u = hit.tile_fraction;
        
        pixel_offset = top * width + i32(x);
        for y in top..<bottom {            
            sampleBitmap(texture, u, v, &pixel);

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

drawWallTilesTexture :: proc(using tm: ^TileMap) {
    clearBitmap(&wall_tiles_texture.bitmap, true);
    
    for row in &tiles do
        for tile in &row do if tile.is_full do
            drawBitmap(&textures[tile.texture_id], &wall_tiles_texture.bitmap, tile.bounds.min * TEXTURE_WIDTH);
}

drawFloorTilesTexture :: proc(using tm: ^TileMap) {
    clearBitmap(&floor_tiles_texture.bitmap);

    for row in &tiles do
        for tile in &row do
            drawBitmap(floor_texture, &floor_tiles_texture.bitmap, tile.bounds.min * TEXTURE_WIDTH);
}

drawCeilingTilesTexture :: proc(using tm: ^TileMap) {
    clearBitmap(&ceiling_tiles_texture.bitmap);

    for row in &tiles do
        for tile in &row do
            drawBitmap(ceiling_texture, &ceiling_tiles_texture.bitmap, tile.bounds.min * TEXTURE_WIDTH);
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
