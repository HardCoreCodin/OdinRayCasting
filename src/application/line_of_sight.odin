package application

MAP_WIDTH :: 40;
MAP_HEIGHT :: 30;
TILE_SIZE :: 10;

tile_map: [MAP_HEIGHT][MAP_WIDTH]Tile;

Tile :: struct {
	is_full: bool,

	has_left_edge,
	has_right_edge,
	has_top_edge,
	has_bottom_edge: bool,

	top_edge, 
	bottom_edge, 
	left_edge, 
	right_edge: u32,

	texture_id: u8,

	bounds: Bounds2Di
}
Edge :: struct #packed{
	length: i32,
	from, to, t_from, t_to: vec2i,

	color: ^Color,

	is_visible,
	is_horizontal,
	is_facing_left,
	is_facing_right,
	is_facing_up,
	is_facing_down,
	is_facing_forward: bool
}

edges: [dynamic]Edge;

transformEdges :: proc(origin: vec2i) {
	for edge in &edges {
		using edge;
		t_from = from - origin;
		t_to = to - origin;
		is_facing_forward = is_horizontal ? (
			is_facing_down && t_from.y > 0 || is_facing_up    && t_from.y < 0) : (
			is_facing_left && t_from.x < 0 || is_facing_right && t_from.x > 0);
		color = is_facing_forward ? &RED : &WHITE;	
	}
}

generateEdges :: proc() {
	clear(&edges);

	above_tile, 
	below_tile, 
	left_tile, 
	right_tile: ^Tile;

	above_exists,
	below_exists,
	left_exists,
	right_exists: bool;

	row_above,
	row_below: ^[MAP_WIDTH]Tile;

	current: vec2i; 

	for row, y in &tile_map {
		above_exists = y > 0;
		below_exists = y < MAP_HEIGHT - 1;

		if above_exists do row_above = &tile_map[y - 1];
		if below_exists do row_below = &tile_map[y + 1];

        for tile, x in &row {
        	left_exists  = x > 0;
        	right_exists = x < MAP_WIDTH - 1;

        	if left_exists  do left_tile  = &row[x - 1];
        	if right_exists do right_tile = &row[x + 1]; 
        	if above_exists do above_tile = &row_above[x]; 
        	if below_exists do below_tile = &row_below[x];

        	using tile;
        	if is_full {
	        	has_left_edge   = left_exists  && !left_tile.is_full;
	        	has_right_edge  = right_exists && !right_tile.is_full; 
	        	has_top_edge    = above_exists && !above_tile.is_full; 
	        	has_bottom_edge = below_exists && !below_tile.is_full;
	        } else {
	        	has_left_edge   = false;
	        	has_right_edge  = false;
	        	has_top_edge    = false;
	        	has_bottom_edge = false;
	        }

        	if has_left_edge { // Create/extend left edge:
	        	if above_exists && above_tile.has_left_edge { // Tile above has a left edge, extend it:
	        		edge := &edges[above_tile.left_edge];
	        		edge.length += TILE_SIZE;
	        		edge.to.y += TILE_SIZE;
	        		left_edge = above_tile.left_edge;
	        	} else { // No left edge above - create new one:
	        		left_edge = u32(len(edges));
	        		edge: Edge;
	        		edge.color = &WHITE;
	        		edge.length = TILE_SIZE;
	        		edge.from = current;
	        		edge.to = edge.from;
	        		edge.to.y += TILE_SIZE;
	        		edge.is_facing_left = true;
	        		append(&edges, edge);
	        	}
	        }

			if tile.has_right_edge { // Create/extend right edge:
	        	if above_exists && above_tile.has_right_edge { // Tile above has a right edge, extend it:
	        		edge := &edges[above_tile.right_edge];
	        		edge.length += TILE_SIZE;
	        		edge.to.y += TILE_SIZE;
	        		tile.right_edge = above_tile.right_edge;
	        	} else { // No right edge above - create new one:
	        		tile.right_edge = u32(len(edges));
	        		edge: Edge;
	        		edge.color = &WHITE;
	        		edge.length = TILE_SIZE;
	        		edge.from = current;
	        		edge.from.x += TILE_SIZE;
	        		edge.to = edge.from;
	        		edge.to.y += TILE_SIZE;
	        		edge.is_facing_right = true;
	        		append(&edges, edge);
	        	}
	        }

	        if tile.has_top_edge { // Create/extend top edge:
	        	if left_exists && left_tile.has_top_edge { // Tile on the left has a top edge, extend it:
	        		edge := &edges[left_tile.top_edge];
	        		edge.length += TILE_SIZE;
	        		edge.to.x += TILE_SIZE;
	        		tile.top_edge = left_tile.top_edge;
	        	} else { // No top edge on the left - create new one:
	        		tile.top_edge = u32(len(edges));
	        		edge: Edge;
	        		edge.color = &WHITE;
	        		edge.length = TILE_SIZE;
	        		edge.from = current;
	        		edge.to = edge.from;
	        		edge.to.x += TILE_SIZE;
	        		edge.is_facing_up = true;
	        		edge.is_horizontal = true;
	        		append(&edges, edge);
	        	}
	        }

	        if tile.has_bottom_edge { // Create/extend bottom edge:
	        	if left_exists && left_tile.has_bottom_edge {// Tile on the left has a bottom edge, extend it:
	        		edge := &edges[left_tile.bottom_edge];
	        		edge.length += TILE_SIZE;
	        		edge.to.x += TILE_SIZE;
	        		tile.bottom_edge = left_tile.bottom_edge;
	        	} else { // No bottom edge on the left - create new one:
	        		tile.bottom_edge = u32(len(edges));
	        		edge: Edge;
	        		edge.color = &WHITE;
	        		edge.length = TILE_SIZE;
	        		edge.from = current;
	        		edge.from.y += TILE_SIZE;
	        		edge.to = edge.from;
	        		edge.to.x += TILE_SIZE;
	        		edge.is_facing_down = true;
	        		edge.is_horizontal = true;
	        		append(&edges, edge);
	        	}
	        }

	        tile.bounds.min.x = current.x;
	        tile.bounds.max.x = current.x + TILE_SIZE;

	        tile.bounds.min.y = current.y;
	        tile.bounds.max.y = current.y + TILE_SIZE;

			current.x += TILE_SIZE;
        }

        current.x  = 0;
        current.y += TILE_SIZE;
    }
}

linesRayWithEdge :: proc(a, b, c, d, p: ^Coords2D) -> bool {
	ray_direction, edge_vector: Coords2D;

	u := b^ - a^;
	v := d^ - c^;

	det := u.x * v.y - 
	       v.x * u.y;

	if det != 0 {
		h := a.y - c.y;
		w := a.x - c.x;

		s := h*u.x - w*u.y;
	    t := f32(h*v.x - w*v.y);

	    if s >= 0 && s <= det && 
	       t >= 0 && t <= f32(det) {
	    	t /= f32(det);
	        
	        p.x = i32(f32(a.x) + t*f32(u.x));
	        p.y = i32(f32(a.y) + t*f32(u.y));

	        return true;
	    }
	}

    return false; // No collision
}



// linesRayWithEdge :: proc(a, b, c, d, p: Coords2D) -> bool {
// 	u := b - a;
// 	v := d - c;



// 	det := u.x * v.y - 
// 	       v.x * u.y;

// 	if det != 0 {
// 		h := a.y - c.y;
// 		w := a.x - c.x;

// 		s := h*u.x - w*u.y;
// 	    t := h*v.x - w*v.y;

// 	    if s >= 0 && s <= det && 
// 	       t >= 0 && t <= det {
// 	    	t /= det;
	        
// 	        p.x = a.x + t*u.x;
// 	        p.y = a.y + t*u.y;

// 	        return true;
// 	    }
// 	}

//     return false; // No collision
// }

EMPTY_TILE_CHARACTER := u8('_');
TILE_MAP := `
1111111111111111111111111111111111111111
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1___________22222223___________________1
1__________________3___________________1
1__________________3___________________1
1__________________3___________________1
1__________________34444444____________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1______________________________________1
1111111111111111111111111111111111111111
`;


NUMBER_ASCII_OFFSET :: 48;
readASCIIgrid :: proc() {
	character := EMPTY_TILE_CHARACTER;
    offset: u32 = 1;
    bounds: Bounds2Di = {{0, 0}, {MAP_WIDTH, MAP_HEIGHT}};

    for row, y in &tile_map {
        for tile, x in &row {
        	using tile;
        	character = TILE_MAP[offset];
        	is_full = character != EMPTY_TILE_CHARACTER;
        	texture_id = is_full ? 0 : character - NUMBER_ASCII_OFFSET;
        	tile.bounds = bounds;

            bounds.min.x += TILE_SIZE;
			bounds.max.x += TILE_SIZE;
            offset += 1;
        }

        bounds.min.x = 0;
		bounds.max.x = TILE_SIZE;
		bounds.min.y += TILE_SIZE;
		bounds.max.y += TILE_SIZE;

        offset += 1;
    }
}
