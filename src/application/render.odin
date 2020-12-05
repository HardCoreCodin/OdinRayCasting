package application

MIN_DIM_FACTOR :: 0.1;
MAX_DIM_FACTOR :: 1;
DIM_FACTOR_RANGE :: MAX_DIM_FACTOR - MIN_DIM_FACTOR;

MAX_COLOR_VALUE :: 0xFF;

// texture_files: [][]u8 = {
//     #load("../../assets/bluestone.bmp"),
//     #load("../../assets/colorstone.bmp"),
//     #load("../../assets/eagle.bmp"),
//     #load("../../assets/graystone.bmp"),
//     #load("../../assets/mossystone.bmp"),
//     #load("../../assets/purplestone.bmp"),
//     #load("../../assets/redbrick.bmp"),
//     #load("../../assets/wood.bmp")
// };

floor_and_ceiling_texture_files: [][]u8 = {
    #load("../../assets/256/walls/colored_stone.bmp"),
    #load("../../assets/256/walls/purple_stone.bmp")
};
wall_texture_files: [][]u8 = {
	#load("../../assets/256/walls/cobblestone2.bmp"),
    #load("../../assets/256/walls/red_stone.bmp"),
    #load("../../assets/256/walls/colored_stone.bmp"),
	// #load("../../assets/128/walls/colored_stone.bmp"),
	// #load("../../assets/128/walls/red_stone.bmp")
};

floor_and_ceiling_texture_set,
wall_texture_set: TextureSet;
wall_textures: ^[]Texture;
floor_texture, 
ceiling_texture: ^Texture;

texture_width,
texture_height: i32;
mip_count: u8;

initRender :: proc() {
    temp_bitmap: Bitmap;
    readBitmapFromFile(&temp_bitmap, &wall_texture_files[0]);
    texture_width  = temp_bitmap.width;
    texture_height = temp_bitmap.height;

    loadTextureSet(
        &floor_and_ceiling_texture_set, 
        &floor_and_ceiling_texture_files, 
        texture_width, 
        texture_height
    );
    floor_texture   = &floor_and_ceiling_texture_set.textures[0];
    ceiling_texture = &floor_and_ceiling_texture_set.textures[1];

	loadTextureSet(
        &wall_texture_set, 
        &wall_texture_files, 
        texture_width, 
        texture_height
    );
	wall_textures = &wall_texture_set.textures;

    mip_count = u8(len(floor_texture.bitmaps));

    print(mip_count);
}

drawWalls :: proc(using cam: ^Camera2D) {
    using xform;
    using frame_buffer;

    top, bottom, 
    pixel_offset,
    column_height: i32;

    texel_height,
    distance, dim_factor, u, v: f32;   
    half_max_distance := half_width * focal_length * 0.5;

    vertical_hit: ^VerticalHit;
    
    floor_pixel_offset := size - width;
    ceiling_pixel_offset: i32;

	mip_level: u8;
	last_mip := mip_count - 1;
	initial_mip := f32(mip_count) * 0.9;
	other_mip_level: u8 = 1;

	current_mip_factor,
	next_mip_factor: f32;

    wall_texture: ^Texture;

    wall_bitmap , floor_bitmap , ceiling_bitmap: ^Bitmap;
    wall_samples, floor_samples, ceiling_samples,
    other_wall_samples,
    other_floor_samples,
    other_ceiling_samples: ^Samples;
    
    other_wall_pixel, wall_pixel,
    other_floor_pixel, floor_pixel, 
    other_ceiling_pixel, ceiling_pixel: vec4;

    texture_id: u8;
    texture_height_ratio,
    current_mip_levelf: f32;  
    current_mip_levelI: i32;

    vertical_hit_level: ^VerticalHitLevel;

    for vertical_hit_row, y in &vertical_hits.cells {
        vertical_hit_level = &vertical_hit_levels[y];
        mip_level = min(vertical_hit_level.mip_level, last_mip);
        current_mip_factor = vertical_hit_level.mip_factor;

        if filter_mode == FilterMode.None {
            floor_bitmap = floor_texture.bitmaps[mip_level];
            ceiling_bitmap = ceiling_texture.bitmaps[mip_level];
        } else {
            floor_samples = floor_texture.samples[mip_level];
            ceiling_samples = ceiling_texture.samples[mip_level];

            if filter_mode == FilterMode.TriLinear {
                other_mip_level = mip_level == 0 ? 0 : max(mip_level - 1, 0);
                next_mip_factor = 1 - current_mip_factor;

                other_floor_samples = floor_texture.samples[other_mip_level];
                other_ceiling_samples = ceiling_texture.samples[other_mip_level];
            }
        }
        
        for vertical_hit, x in &vertical_hit_row {
            if !vertical_hit.found do continue;
        
            if filter_mode == FilterMode.None {
                sampleGrid(floor_bitmap, vertical_hit.u, vertical_hit.v, &floor_pixel);
                sampleGrid(ceiling_bitmap, vertical_hit.u, vertical_hit.v, &ceiling_pixel);
            } else {
                sample(floor_samples, vertical_hit.u, vertical_hit.v, &floor_pixel);
                sample(ceiling_samples, vertical_hit.u, vertical_hit.v, &ceiling_pixel);

                if filter_mode == FilterMode.TriLinear {
                    sample(other_floor_samples, vertical_hit.u, vertical_hit.v, &other_floor_pixel);
                    sample(other_ceiling_samples, vertical_hit.u, vertical_hit.v, &other_ceiling_pixel);

                    floor_pixel = current_mip_factor*floor_pixel + next_mip_factor*other_floor_pixel;
                    ceiling_pixel = current_mip_factor*ceiling_pixel + next_mip_factor*other_ceiling_pixel;
                }
            }

            floor_pixel   *= vertical_hit.dim_factor;
            ceiling_pixel *= vertical_hit.dim_factor;

            setPixel(&_cells[floor_pixel_offset + i32(x)], &floor_pixel);
            setPixel(&_cells[ceiling_pixel_offset + i32(x)], &ceiling_pixel);
        }

        floor_pixel_offset   -= width;
        ceiling_pixel_offset += width;
    }

    half_column_height,
    distance_squared,
    height_squared: f32;    

    for ray, x in &rays {
        using ray;

        distance = dot((hit.position - position), forward_direction^);
        if distance < 0 do distance = -distance;
        
        distance_squared = distance * distance;
        dim_factor = 1.1 / max(1, distance);
        
        half_column_height = half_max_distance / distance; 
        column_height = i32(half_column_height + half_column_height);

    	top    = column_height < height ? (height - column_height) / 2 : 0;
        bottom = column_height < height ? (height + column_height) / 2 : height;

        wall_texture = &wall_textures[hit.texture_id];

        texel_height = 1 / f32(column_height);
        v = column_height > height ? f32((column_height - height) / 2) * texel_height : 0;
        u = hit.tile_fraction;

        if filter_mode == FilterMode.None do wall_bitmap = wall_texture.bitmaps[0]; else {
            texture_height_ratio = texel_height * 256 / 18;
            
            current_mip_levelf = initial_mip;
            for (current_mip_levelf / f32(mip_count)) > texture_height_ratio do current_mip_levelf *= 0.9;

            current_mip_levelI = i32(current_mip_levelf);
            current_mip_factor = current_mip_levelf - f32(current_mip_levelI);
            
            mip_level = min(u8(current_mip_levelI), last_mip);
            wall_samples = wall_texture.samples[mip_level];

            if filter_mode == FilterMode.TriLinear {
                other_mip_level = mip_level == 0 ? 0 : max(mip_level - 1, 0);
                other_wall_samples = wall_texture.samples[other_mip_level];
                next_mip_factor = 1 - current_mip_factor;
            }
        }
        
		pixel_offset = top * width + i32(x);
        for y in top..<bottom {
            if filter_mode == FilterMode.None {
                sampleGrid(wall_bitmap, u, v, &wall_pixel);
            } else {
                sample(wall_samples, u, v, &wall_pixel);
                
                if filter_mode == FilterMode.TriLinear {
    	            sample(other_wall_samples, u, v, &other_wall_pixel);
    	            wall_pixel = current_mip_factor*wall_pixel + next_mip_factor*other_wall_pixel;
                }
            } 
            height_squared = (f32(y) - half_height) / half_column_height;
            height_squared *= height_squared;
            wall_pixel *= max(dim_factor, 1.5 / max(1, height_squared + distance_squared));

            setPixel(&_cells[pixel_offset], &wall_pixel);

            pixel_offset += width;
            v += texel_height;
        }
    }
}