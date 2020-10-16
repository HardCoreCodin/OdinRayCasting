package application

MIN_DIM_FACTOR :: 0.1;
MAX_DIM_FACTOR :: 2;
DIM_FACTOR_RANGE :: MAX_DIM_FACTOR - MIN_DIM_FACTOR;

MAX_COLOR_VALUE :: 0xFF;
TEXTURE_COUNT :: 8;
TEXTURE_WIDTH :: 64;
TEXTURE_HEIGHT :: 64;
TEXTURE_SIZE :: TEXTURE_WIDTH * TEXTURE_HEIGHT;
MIP_COUNT :: 7;

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

textures: [TEXTURE_COUNT]Texture;

all_texture_bitmaps        : [MIP_COUNT * TEXTURE_COUNT]Bitmap;
all_texture_samples        : [MIP_COUNT * TEXTURE_COUNT]Samples;
all_texture_sample_pointers: [MIP_COUNT * TEXTURE_COUNT]^Samples;
all_texture_bitmap_pointers: [MIP_COUNT * TEXTURE_COUNT]^Bitmap;
all_texture_bitmap_samples : [TEXTURE_COUNT * (TEXTURE_SIZE + TEXTURE_SIZE/2)]Sample;
all_texture_bitmap_pixels  : [TEXTURE_COUNT * (TEXTURE_SIZE + TEXTURE_SIZE/2)]Pixel;

initRender :: proc() {
    o: i32;
    for texture in &textures {
        texture.bitmaps = all_texture_bitmap_pointers[o: o + MIP_COUNT];
        texture.samples = all_texture_sample_pointers[o: o + MIP_COUNT];
        o += MIP_COUNT;
    }

    w := i32(TEXTURE_WIDTH);
    h := i32(TEXTURE_HEIGHT);
    s := w * h;

    for m in 0..<MIP_COUNT {
        o = 0;

        for t in 0..<TEXTURE_COUNT {
            initGrid(&all_texture_bitmaps[m*TEXTURE_COUNT + t], w, h, all_texture_bitmap_pixels[ o:o+s]);
            initGrid(&all_texture_samples[m*TEXTURE_COUNT + t], w, h, all_texture_bitmap_samples[o:o+s]);

            textures[t].bitmaps[m] = &all_texture_bitmaps[m*TEXTURE_COUNT + t];
            textures[t].samples[m] = &all_texture_samples[m*TEXTURE_COUNT + t];
            
            o += s;
        }

        w >>= 1;
        h >>= 1;
        s = w*h;
    }

    for texture, texture_id in &textures do
        loadTexture(&texture, &texture_files[texture_id], true, false);
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
    
    floor_pixel_offset := size - width;
    ceiling_pixel_offset: i32;

	mip_level: u8;
	mip_count := u8(len(textures[0].samples));
	last_mip := mip_count - 1;
	initial_mip := f32(mip_count) * 0.9;
	other_mip_level: u8 = 1;

	current_mip_factor,
	next_mip_factor: f32;
	
    tile_width  := textures[0].bitmaps[0].width;
    tile_height := textures[0].bitmaps[0].height;

    wall_texture,
    floor_texture,
    ceiling_texture: ^Texture;

    wall_bitmap: ^Bitmap;
    wall_samples, 
    floor_samples,
    ceiling_samples,
    other_wall_samples,
    other_floor_samples,
    other_ceiling_samples: ^Samples;

    // pixel,
    other_wall_pixel, wall_pixel,
    other_floor_pixel, floor_pixel, 
    other_ceiling_pixel, ceiling_pixel: vec4;

    texture_ids: ^TileTextureIDs;
    texture_id: u8;
    texture_height_ratio,
    current_mip_levelf: f32;  
    current_mip_levelI: i32;

    for vertical_hit_row, y in &vertical_hits {
        mip_level = min(vertical_hit_infos[y].mip_level, last_mip);
        current_mip_factor = vertical_hit_infos[y].mip_factor;        

        if filter_mode == FilterMode.TriLinear {
            other_mip_level = mip_level == 0 ? 0 : max(mip_level - 1, 0);
            next_mip_factor = 1 - current_mip_factor;
        }
		
        for vertical_hit, x in &vertical_hit_row {
            if !vertical_hit.found do continue;

            texture_ids = &tile_map.texture_ids.cells[vertical_hit.tile_coords.y][vertical_hit.tile_coords.x];
            
            floor_texture = &textures[texture_ids.floor];
            ceiling_texture = &textures[texture_ids.ceiling];

            if filter_mode == FilterMode.None {
                sampleGrid(floor_texture.bitmaps[mip_level], vertical_hit.u, vertical_hit.v, &floor_pixel);
                sampleGrid(ceiling_texture.bitmaps[mip_level], vertical_hit.u, vertical_hit.v, &ceiling_pixel);
            } else {
                sample(floor_texture.samples[mip_level], vertical_hit.u, vertical_hit.v, &floor_pixel);
                sample(ceiling_texture.samples[mip_level], vertical_hit.u, vertical_hit.v, &ceiling_pixel);

                if filter_mode == FilterMode.TriLinear {
                    sample(floor_texture.samples[other_mip_level], vertical_hit.u, vertical_hit.v, &other_floor_pixel);
                    sample(ceiling_texture.samples[other_mip_level], vertical_hit.u, vertical_hit.v, &other_ceiling_pixel);

                    floor_pixel = current_mip_factor*floor_pixel + next_mip_factor*other_floor_pixel;
                    ceiling_pixel = current_mip_factor*ceiling_pixel + next_mip_factor*other_ceiling_pixel;
                }
            }

            dim_factor = vertical_hit.info.dim_factor;

            floor_pixel   *= dim_factor;
            ceiling_pixel *= dim_factor;
            
            for i in 0..3 {
                if floor_pixel[i] < 0 do floor_pixel[i] = 0;
                if ceiling_pixel[i] < 0 do ceiling_pixel[i] = 0;                
            } 

            setPixel(&_cells[floor_pixel_offset + i32(x)], &floor_pixel);
            setPixel(&_cells[ceiling_pixel_offset + i32(x)], &ceiling_pixel);
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

    	top    = column_height < height ? (height - column_height) / 2 : 0;
        bottom = column_height < height ? (height + column_height) / 2 : height;

        texture_id = tile_map.texture_ids.cells[hit.tile_coords.y][hit.tile_coords.x].wall;
        if texture_id > 7 do print(hit);
        wall_texture = &textures[texture_id];

        texel_height = 1 / f32(column_height);
        v = column_height > height ? f32((column_height - height) / 2) * texel_height : 0;
        u = hit.tile_fraction;

        if filter_mode == FilterMode.None {
            wall_bitmap = wall_texture.bitmaps[0];
        } else {
            texture_height_ratio = texel_height * TEXTURE_HEIGHT / 14;
            
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
            wall_pixel *= dim_factor;
            for i in 0..3 do if wall_pixel[i] < 0 do wall_pixel[i] = 0;
            setPixel(&_cells[pixel_offset], &wall_pixel);

            pixel_offset += width;
            v += texel_height;
        }
    }
}