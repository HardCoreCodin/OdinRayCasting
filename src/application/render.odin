package application

TEXTURE_COUNT :: 8;
TEXTURE_WIDTH :: 64;
TEXTURE_HEIGHT :: 64;
TEXTURE_SIZE :: TEXTURE_WIDTH * TEXTURE_HEIGHT;
MIPPED_TEXTURE_SIZE :: (TEXTURE_WIDTH + TEXTURE_WIDTH/2) * (TEXTURE_HEIGHT + TEXTURE_HEIGHT/2);

MIN_DIM_FACTOR :: 0.1;
MAX_DIM_FACTOR :: 2;
DIM_FACTOR_RANGE :: MAX_DIM_FACTOR - MIN_DIM_FACTOR;

MAX_COLOR_VALUE :: 0xFF;
MIP_COUNT :: 7;

FLOOR_TEXTURE_ID :: 7;
CEILING_TEXTURE_ID :: 3;

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

TileMapTexturesBitmaps :: struct { floor, ceiling, walls: Bitmap};
TileMapTextures :: struct #raw_union { array: [3]Bitmap, using bitmaps: TileMapTexturesBitmaps};

texture_files: [TEXTURE_COUNT][]u8= {
	#load("../../assets/bluestone.bmp"),
	#load("../../assets/colorstone.bmp"),
	#load("../../assets/eagle.bmp"),
	#load("../../assets/graystone.bmp"),
	#load("../../assets/mossystone.bmp"),
	#load("../../assets/purplestone.bmp"),
	#load("../../assets/redbrick.bmp"),
	#load("../../assets/wood.bmp")
};

textures_buffer: [TEXTURE_COUNT * MIPPED_TEXTURE_SIZE]u32;
textures: [MIP_COUNT][TEXTURE_COUNT]Bitmap;

map_textures_buffer: [3 * MAX_TILE_MAP_SIZE * MIPPED_TEXTURE_SIZE]u32;
map_textures: [MIP_COUNT]TileMapTextures;

walls_mips,
floor_mips,
ceiling_mips: [MIP_COUNT]^Bitmap;


initTextures :: proc() {
	start  : i32;
	end    : i32 = TEXTURE_SIZE;
	size   : i32 = TEXTURE_SIZE;
	width  : i32 = TEXTURE_WIDTH;
	height : i32 = TEXTURE_HEIGHT;

	texture_mips: [TEXTURE_COUNT][MIP_COUNT]^Bitmap;

	for mip_level in 0..<MIP_COUNT {
		for texture, texture_id in &textures[mip_level] {			
			texture_mips[texture_id][mip_level] = &texture;

			if mip_level == 0 do
				readBitmapFromFile(&texture, texture_files[texture_id], textures_buffer[start:end]);
			else do
				initBitmap(&texture, width, height, textures_buffer[start:end]);
			
			start += size;
			end   += texture_id == (TEXTURE_COUNT - 1) ? size / 4 : size;
		}

		width /= 2;
		height /= 2;
		size /= 4;
	}
	for mips in &texture_mips do setMips(mips[:]);

	width = MAX_TILE_MAP_WIDTH * TEXTURE_WIDTH;
	height = MAX_TILE_MAP_HEIGHT * TEXTURE_HEIGHT;
	size = width * height;
	start = 0;
	end = size;
	
	for bitmaps, mip_level in &map_textures {
		for bitmap, texture_id in &bitmaps.array {
			initBitmap(&bitmap, width, height, map_textures_buffer[start:end]);
			
			start += size;
			end   += texture_id == 2 ? size / 4 : size;
		}

		walls_mips[mip_level] = &bitmaps.walls;
		floor_mips[mip_level] = &bitmaps.floor;
		ceiling_mips[mip_level] = &bitmaps.ceiling;

		width /= 2;
		height /= 2;
		size /= 4;
	}
}

drawWallTilesTexture :: proc(using tm: ^TileMap) {
	for bitmap in &walls_mips do clearBitmap(bitmap, true);
    
    for row in &tile_map.tiles do
        for tile in &row do 
        	if tile.is_full do
        		for bitmap, mip_level in walls_mips do
		            drawBitmap(&textures[mip_level][tile.texture_id],
		            			bitmap, 
		            			tile.bounds.min.x * textures[mip_level][tile.texture_id].width, 
		            			tile.bounds.min.y * textures[mip_level][tile.texture_id].height);
}

drawFloorAndCeilingTilesTexture :: proc(using tm: ^TileMap) {
	for bitmap in &floor_mips do clearBitmap(bitmap);
	for bitmap in &ceiling_mips do clearBitmap(bitmap);
	
    pos: vec2i;
    
    for row in &tiles do
        for tile in &row do
			for mip_level in 0..<MIP_COUNT {
				pos = tile.bounds.min * textures[mip_level][FLOOR_TEXTURE_ID].width;
	            drawBitmap(&textures[mip_level][FLOOR_TEXTURE_ID],
	            			floor_mips[mip_level], 
	            			tile.bounds.min.x * textures[mip_level][FLOOR_TEXTURE_ID].width, 
	            			tile.bounds.min.y * textures[mip_level][FLOOR_TEXTURE_ID].height);
	            drawBitmap(&textures[mip_level][CEILING_TEXTURE_ID],
	            			ceiling_mips[mip_level], 
	            			tile.bounds.min.x * textures[mip_level][CEILING_TEXTURE_ID].width, 
	            			tile.bounds.min.y * textures[mip_level][CEILING_TEXTURE_ID].height);
			}

	// printBitmap();		
}

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

	mip_level: u8 = 0;
    floor_texture,
	ceiling_texture: ^Bitmap;

    for vertical_hit_row, y in &vertical_hits {
    	mip_level = vertical_hit_infos[y].mip_level;
		floor_texture := &textures[mip_level][FLOOR_TEXTURE_ID];
		ceiling_texture := &textures[mip_level][CEILING_TEXTURE_ID];

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


        distance = dot((hit.position - position), forward_direction^);
        if distance < 0 do distance = -distance;
        
        dim_factor = 1 - distance * distance_factor + MIN_DIM_FACTOR;

        column_height = i32(max_distance / distance);

    	mip_level = u8(min(f32(MIP_COUNT) * (f32(height / 32) / f32(column_height)), MIP_COUNT-1)); 
        texture = &textures[mip_level][hit.tile.texture_id];

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

// MAX_TILES_TEXTURE_SIZE :: MAX_TILE_MAP_SIZE * TEXTURE_SIZE;
// TileMapTexture :: struct {
//     using bitmap: Bitmap,
//     mipmap: MipMap,
//     bits: ^[MAX_TILES_TEXTURE_SIZE]u32
// };
// initTileMapTexture :: proc(using tmt: ^TileMapTexture) {
// 	bits := make_slice([]u32, MAX_TILES_TEXTURE_SIZE);
//     initBitmap(&bitmap, 
//         MAX_TILE_MAP_WIDTH  * TEXTURE_WIDTH, 
//         MAX_TILE_MAP_HEIGHT * TEXTURE_HEIGHT, 
//         bits^[:]
//     );
//     initMipMap(&mipmap, &bitmap);
// }
// initTextures :: proc() {	
// 	MIP_COUNT = textures[0].mip_count;;

//     initTileMapTexture(&wall_tiles_texture);
//     initTileMapTexture(&floor_tiles_texture);
//     initTileMapTexture(&ceiling_tiles_texture);
// }
