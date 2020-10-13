package application

FLOOR_TEXTURE_ID :: 7;
CEILING_TEXTURE_ID :: 3;

MIN_DIM_FACTOR :: 0.1;
MAX_DIM_FACTOR :: 2;
DIM_FACTOR_RANGE :: MAX_DIM_FACTOR - MIN_DIM_FACTOR;

MAX_COLOR_VALUE :: 0xFF;
// TEXTURE_COUNT :: 8;
TEXTURE_WIDTH :: 64;
TEXTURE_HEIGHT :: 64;

texture_files: [][]u8 = {
	#load("../../assets/bluestone.bmp"),
	#load("../../assets/colorstone.bmp"),
	#load("../../assets/eagle.bmp"),
	#load("../../assets/graystone.bmp"),
	#load("../../assets/mossystone.bmp"),
	#load("../../assets/purplestone.bmp"),
	#load("../../assets/redbrick.bmp"),
	#load("../../assets/wood.bmp")
};

texture_set,
map_texture_set: TextureSet;

walls_map_texture,
floor_map_texture,
ceiling_map_texture: ^Texture;

textures: ^[]Texture;

initRender :: proc() {
	initTextureSet(&map_texture_set, 3, MAX_TILE_MAP_HEIGHT * TEXTURE_HEIGHT, MAX_TILE_MAP_WIDTH * TEXTURE_WIDTH);
    loadTextureSet(&texture_set, &texture_files, TEXTURE_WIDTH, TEXTURE_HEIGHT);
    
	walls_map_texture = &map_texture_set.textures[0];
	floor_map_texture = &map_texture_set.textures[1];
	ceiling_map_texture = &map_texture_set.textures[2];

	textures = &texture_set.textures;
}

drawMapTextures :: proc(using tm: ^TileMap, walls: bool = false, floor: bool = false, ceiling: bool = false) {
	if walls do for bitmap in &walls_map_texture.bitmaps do clearBitmap(bitmap, true);
	if floor do for bitmap in &floor_map_texture.bitmaps do clearBitmap(bitmap);
	if ceiling do for bitmap in &ceiling_map_texture.bitmaps do clearBitmap(bitmap);

    walls_bitmap := walls_map_texture.bitmaps[0];
    floor_bitmap := floor_map_texture.bitmaps[0];
    ceiling_bitmap := ceiling_map_texture.bitmaps[0];

    tile_width  := textures[0].bitmaps[0].width;
    tile_height := textures[0].bitmaps[0].height;

    column_id,
    current_row_is_full: u32;

    texture_ids_row: ^[]TileTextureIDs;
    tile_texture_ids: ^TileTextureIDs;

    pos: vec2i;

    for y in 0..<height {
    	pos.x = 0;

		column_id = 1;
		current_row_is_full = is_full[y]; 
		texture_ids_row = &texture_ids.cells[y];

		for x in 0..<width {
			tile_texture_ids = &texture_ids_row[x];

        	if walls && (current_row_is_full & column_id) != 0 do
        		drawBitmap(textures[tile_texture_ids.wall].bitmaps[0], walls_bitmap, pos.x, pos.y);

        	if floor do drawBitmap(textures[tile_texture_ids.floor].bitmaps[0], floor_bitmap, pos.x, pos.y);
        	if ceiling do drawBitmap(textures[tile_texture_ids.ceiling].bitmaps[0], ceiling_bitmap, pos.x, pos.y);

			column_id <<= 1;
			pos.x += tile_width;			
        }
        pos.y += tile_height;
    }

	if walls {
		generateMipMaps(&walls_map_texture.bitmaps);
    	generateTextureSamples(walls_map_texture);
	};
	if floor {
		generateMipMaps(&floor_map_texture.bitmaps);
    	generateTextureSamples(floor_map_texture);
	};
	if ceiling {
		generateMipMaps(&ceiling_map_texture.bitmaps);
    	generateTextureSamples(ceiling_map_texture);
	};
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
    pixel: Pixel;
    float_pixel, other_float_pixel: vec4;

    floor_pixel_offset := size - width;
    ceiling_pixel_offset: i32;

	mip_level: u8;
	mip_count := u8(len(textures[0].samples));
	last_mip := mip_count - 1;
	initial_mip := f32(mip_count) * 0.9;
	other_mip_level: u8 = 1;

	// last_map_textue_mip := u8(len(floor_map_texture.samples) - 1);

	current_mip_factor,
	next_mip_factor: f32;

    wall_samples, 
	other_wall_samples,
    other_floor_samples,
	other_ceiling_samples: ^Samples;
	
    tile_width  := textures[0].bitmaps[0].width;
    tile_height := textures[0].bitmaps[0].height;

    floor_samples   := &textures[7].samples;
    ceiling_samples := &textures[3].samples;
    other_floor, floor, 
    other_ceiling, ceiling: ^Samples;

    for vertical_hit_row, y in &vertical_hits {
    	// mip_level = min(vertical_hit_infos[y].mip_level, last_map_textue_mip);
        mip_level = min(vertical_hit_infos[y].mip_level, last_mip);

    	current_mip_factor = vertical_hit_infos[y].mip_factor;

		if toggle2 {		
            other_mip_level = mip_level == 0 ? 0 : max(mip_level - 1, 0);
            next_mip_factor = 1 - current_mip_factor;
			
            floor = floor_samples[mip_level];
            ceiling = ceiling_samples[mip_level];

            other_floor = floor_samples[other_mip_level];
            other_ceiling = ceiling_samples[other_mip_level];

            // floor_samples = floor_map_texture.samples[mip_level];
			// ceiling_samples = ceiling_map_texture.samples[mip_level];
		
			// other_floor_samples = floor_map_texture.samples[other_mip_level];
			// other_ceiling_samples = ceiling_map_texture.samples[other_mip_level];
		} else {
            floor = floor_samples[mip_level];
            ceiling = ceiling_samples[mip_level];

			// floor_samples = floor_map_texture.samples[mip_level];
			// ceiling_samples = ceiling_map_texture.samples[mip_level];
		}		
		
        for vertical_hit, x in &vertical_hit_row {
            if !vertical_hit.found do continue;

            dim_factor = vertical_hit.info.dim_factor;

            sample(floor, vertical_hit.u, vertical_hit.v, &float_pixel);

            if toggle2 {
	            sample(other_floor, vertical_hit.u, vertical_hit.v, &other_float_pixel);
	            float_pixel = current_mip_factor*float_pixel + next_mip_factor*other_float_pixel;
            }
            float_pixel *= dim_factor;
            for i in 0..3 do if float_pixel[i] < 0 do float_pixel[i] = 0;
            setPixel(&_cells[floor_pixel_offset + i32(x)], &float_pixel);

            sample(ceiling, vertical_hit.u, vertical_hit.v, &float_pixel);
            if toggle2 {
            	sample(other_ceiling, vertical_hit.u, vertical_hit.v, &other_float_pixel);	
            	float_pixel = current_mip_factor*float_pixel + next_mip_factor*other_float_pixel;
            }
            float_pixel *= dim_factor;
            for i in 0..3 do if float_pixel[i] < 0 do float_pixel[i] = 0; 
            setPixel(&_cells[ceiling_pixel_offset + i32(x)], &float_pixel);
        }

        floor_pixel_offset   -= width;
        ceiling_pixel_offset += width;
    }

    texture_id: u8;
    texture_height_ratio,
    current_mip_levelf: f32;  
    current_mip_levelI: i32;

    for ray, x in &rays {
        using ray;

        distance = dot((hit.position - position), forward_direction^);
        if distance < 0 do distance = -distance;
        
        dim_factor = 1 - distance * distance_factor + MIN_DIM_FACTOR;

        column_height = i32(max_distance / distance);

    	top    = column_height < height ? (height - column_height) / 2 : 0;
        bottom = column_height < height ? (height + column_height) / 2 : height;

        texel_height = 1 / f32(column_height);
        v = column_height > height ? f32((column_height - height) / 2) * texel_height : 0;
        u = hit.tile_fraction;

        texture_height_ratio = texel_height * TEXTURE_HEIGHT / 14;
		current_mip_levelf = initial_mip;
        for (current_mip_levelf / f32(mip_count)) > texture_height_ratio do current_mip_levelf *= 0.9;
        current_mip_levelI = i32(current_mip_levelf);
        current_mip_factor = current_mip_levelf - f32(current_mip_levelI);
        next_mip_factor = 1 - current_mip_factor;
		mip_level = min(u8(current_mip_levelI), last_mip);
    	other_mip_level = mip_level == 0 ? 0 : max(mip_level - 1, 0);

    	texture_id = tile_map.texture_ids.cells[hit.tile_coords.y][hit.tile_coords.x].wall;
	    wall_samples = textures[texture_id].samples[mip_level];
		if toggle2 do other_wall_samples = textures[texture_id].samples[other_mip_level];

        pixel_offset = top * width + i32(x);
        for y in top..<bottom {            
            sample(wall_samples, u, v, &float_pixel);
            
            if toggle2 {
	            sample(other_wall_samples, u, v, &other_float_pixel);
	            float_pixel = current_mip_factor * float_pixel + next_mip_factor * other_float_pixel;
            }
            float_pixel *= dim_factor;
            for i in 0..3 do if float_pixel[i] < 0 do float_pixel[i] = 0;
            setPixel(&_cells[pixel_offset], &float_pixel);

            pixel_offset += width;
            v += texel_height;
        }
    }
}


// MIP_COUNT :: 7;
// TEXTURE_COUNT :: 8;
// TEXTURE_WIDTH :: 64;
// TEXTURE_HEIGHT :: 64;
// TEXTURE_SIZE :: TEXTURE_WIDTH * TEXTURE_HEIGHT;
// // MIPPED_TEXTURE_SIZE :: (TEXTURE_WIDTH + TEXTURE_WIDTH/2) * (TEXTURE_HEIGHT + TEXTURE_HEIGHT/2);
// // SAMPLES_BUFFER_SIZE :: TEXTURE_COUNT * MIPPED_TEXTURE_SIZE;


// _walls_texture_set: TextureSet(len(texture_files), TEXTURE_HEIGHT, TEXTURE_WIDTH, MIP_COUNT);
// _maps_texture_set: TextureSet(2, MAX_TILE_MAP_SIZE * TEXTURE_HEIGHT, MAX_TILE_MAP_SIZE * TEXTURE_WIDTH, MIP_COUNT);

// // all_texture_samples_buffer: [SAMPLES_BUFFER_SIZE]Sample;
// // all_texture_samples: [MIP_COUNT][TEXTURE_COUNT]Samples;
// // all_textures: [TEXTURE_COUNT]Texture;

// MapTextures :: struct (TextureType: typeid) #raw_union { 
// 	using textures: struct { 
// 		floor, 
// 		ceiling, 
// 		walls: TextureType
// 	},
// 	array: [3]TextureType
// };


// map_textures_buffer: [3 * MAX_TILE_MAP_SIZE * MIPPED_TEXTURE_SIZE]Texel;
// map_textures: [MIP_COUNT]TileMapTextures(Texture);

// map_samples_buffer: [3 * MAX_TILE_MAP_SIZE * MIPPED_TEXTURE_SIZE]Sample;
// map_samples: [MIP_COUNT]TileMapTextures(Samples);

// walls_mips,
// floor_mips,
// ceiling_mips: [MIP_COUNT]^Texture;

// initTextures :: proc() {
// 	initMipMap();
// 	initTextureSet(&texture_set);

// 	start  : i32;
// 	end    : i32 = TEXTURE_SIZE;
// 	size   : i32 = TEXTURE_SIZE;
// 	width  : i32 = TEXTURE_WIDTH;
// 	height : i32 = TEXTURE_HEIGHT;

// 	mip_levels: [TEXTURE_COUNT][MIP_COUNT]^Texture;

// 	for mip_level in 0..<MIP_COUNT {
// 		for bitmap, i in &bitmaps[mip_level] {
// 			bitmap_mips[i][mip_level] = &bitmap;

// 			if mip_level == 0 do
// 				readBitmapFromFile(&bitmap, bitmap_files[i], bitmaps_buffer[start:end]);
// 			else do
// 				initBitmap(&bitmap, width, height, bitmaps_buffer[start:end]);
			
// 			start += size;
// 			end   += i == (TEXTURE_COUNT - 1) ? size / 4 : size;
// 		}

// 		width /= 2;
// 		height /= 2;
// 		size /= 4;
// 	}
// 	for mips in &bitmap_mips do setMips(mips[:]);

// 	width = TEXTURE_WIDTH + 1;
// 	height = TEXTURE_HEIGHT + 1;
// 	size = width * height;
// 	start = 0;
// 	end = size;
// 	for mip_level in 0..<MIP_COUNT {
// 		for texture, texture_id in &textures[mip_level] {
// 			initBitmap(&texture, width, height, textures_buffer[start:end]);
// 			setTexture(&texture, &bitmaps[mip_level][texture_id]);
	
// 			start += size;
// 			end   += texture_id == (TEXTURE_COUNT - 1) ? (
// 				(((width  - 1) / 2) + 1) * 
// 				(((height - 1) / 2) + 1)				
// 			) : size;
// 		}

// 		width = ((width - 1) / 2) + 1;
// 		height = ((height - 1) / 2) + 1;
// 		size = width * height;
// 	}

// 	width = MAX_TILE_MAP_WIDTH * TEXTURE_WIDTH;
// 	height = MAX_TILE_MAP_HEIGHT * TEXTURE_HEIGHT;
// 	size = width * height;
// 	start = 0;
// 	end = size;
	
// 	for bitmaps, mip_level in &map_textures {
// 		for bitmap, texture_id in &bitmaps.array {
// 			initBitmap(&bitmap, width, height, map_textures_buffer[start:end]);
			
// 			start += size;
// 			end   += texture_id == 2 ? size / 4 : size;
// 		}

// 		walls_mips[mip_level] = &bitmaps.walls;
// 		floor_mips[mip_level] = &bitmaps.floor;
// 		ceiling_mips[mip_level] = &bitmaps.ceiling;

// 		width /= 2;
// 		height /= 2;
// 		size /= 4;
// 	}
// }