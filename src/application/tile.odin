package application

DEFAULT_TILE_SIZE :: 10;
MAX_TILE_MAP_WIDTH :: 40;
MAX_TILE_MAP_HEIGHT :: 30;
MAX_TILE_MAP_SIZE :: MAX_TILE_MAP_WIDTH * MAX_TILE_MAP_HEIGHT;
MAX_TILE_MAP_VERTICES :: (MAX_TILE_MAP_WIDTH + 1) * (MAX_TILE_MAP_HEIGHT + 1);
MAX_TILE_MAP_EDGES :: MAX_TILE_MAP_WIDTH * (MAX_TILE_MAP_HEIGHT + 1) + MAX_TILE_MAP_HEIGHT * (MAX_TILE_MAP_WIDTH + 1);

Tile :: struct {
	bounds: Bounds2Di,
	texture_id: u8,

	is_full,
	
	has_left_edge,
	has_right_edge,
	has_top_edge,
	has_bottom_edge: bool,

	top_edge, 
	bottom_edge, 
	left_edge, 
	right_edge: ^TileEdge
}
TileRow :: []Tile;

TileEdge :: struct {
	length: i32,
	
	local: struct {
		from, to: ^vec2,
		is_above,
		is_below,
		is_left,
		is_right: bool	
	},
	from, to: ^vec2i,
	color: Color,

	is_visible,
	is_horizontal,

	is_facing_left,
	is_facing_right,
	is_facing_up,
	is_facing_down,
	is_facing_forward: bool
}

TileMap :: struct {
	using size: Size2Di,
	tile_size: i32,
	tiles: []TileRow,
	edges: []TileEdge,
	edge_count,
	vertex_count: i32,
	vertices: []vec2i,
	vertices_transformed: []vec2,

	all_rows: [MAX_TILE_MAP_HEIGHT]TileRow,
	all_tiles: [MAX_TILE_MAP_SIZE]Tile,
	all_edges: [MAX_TILE_MAP_EDGES]TileEdge,
	all_vertices: [MAX_TILE_MAP_VERTICES]vec2i,
	all_vertices_transformed: [MAX_TILE_MAP_VERTICES]vec2
}

initTile :: inline proc(using t: ^Tile) {
	is_full = false;
	
	has_left_edge = false;
	has_right_edge = false;
	has_top_edge = false;
	has_bottom_edge = false;

	top_edge = nil;
	bottom_edge = nil;
	left_edge = nil;
	right_edge = nil;
}

initTileEdge :: inline proc(using te: ^TileEdge) {
	length = 0;
	
	local.from = nil;
	local.to = nil;
	local.is_above = false;
	local.is_below = false;
	local.is_left = false;
	local.is_right = false;

	from = nil;
	to = nil;
	color = WHITE;

	is_visible = false;
	is_horizontal = false;

	is_facing_left = false;
	is_facing_right = false;
	is_facing_up = false;
	is_facing_down = false;
	is_facing_forward = false;
}

initTileMap :: proc(using tm: ^TileMap, Width: i32 = MAX_TILE_MAP_WIDTH, Height: i32 = MAX_TILE_MAP_HEIGHT, TileSize: i32 = DEFAULT_TILE_SIZE) {
	width = Width;
	height = Height;
	tile_size = TileSize;

	edges = all_edges[:];
	vertices = all_vertices[:];
	vertices_transformed = all_vertices_transformed[:];

	for tile in &all_tiles do initTile(&tile);
	
	start: i32;
	end := width;

	for y in 0..<height {
		all_rows[y] = all_tiles[start:end];
		start += width;
		end   += width;
	}

	tiles = all_rows[:height];
}

NUMBER_ASCII_OFFSET :: 48;
EMPTY_TILE_CHARACTER :: u8('_');

readTileMapFromASCIIgrid :: proc(using tm: ^TileMap, ascii_grid: ^string) {
	character := EMPTY_TILE_CHARACTER;
    offset: u32 = 1;
    current_bounds: Bounds2Di;
    using current_bounds;
    bottom = tile_size;
    left = tile_size;

    for row, y in &tiles {
        for tile, x in &row {
        	character = ascii_grid[offset];
        	
        	initTile(&tile);
        	using tile;
        	bounds = current_bounds;
        	is_full = character != EMPTY_TILE_CHARACTER;
        	texture_id = is_full ? 0 : character - NUMBER_ASCII_OFFSET;

            left += tile_size;
			right += tile_size;
            offset += 1;
        }

        left = 0;
		right = tile_size;
		top += tile_size;
		bottom += tile_size;

        offset += 1;
    }
}



transformTileMapEdges :: proc(using tm: ^TileMap, origin: vec2i) {
	for vertex, i in &vertices {
		vertices_transformed[i].x = f32(vertex.x - origin.x);
		vertices_transformed[i].y = f32(vertex.y - origin.y);	
	}
	for edge in &edges {
		using edge.local;
		is_right = from.x > 0;
		is_below = from.y > 0;
		is_left  = to.x < 0;
		is_above = to.y < 0;

		edge.is_facing_forward = edge.is_horizontal ? 
			(edge.is_facing_down && is_above || edge.is_facing_up    && is_below):
			(edge.is_facing_left && is_right || edge.is_facing_right && is_left );
		edge.color = edge.is_facing_forward ? YELLOW : RED;
	}
}









generateTileMapEdges :: proc(using tm: ^TileMap) {
	TileCheck :: struct {exists: bool, tile: ^Tile, row: []Tile};
	above, below, left, right: TileCheck;
	position: vec2i; 
	vertex_id, edge_id: u16;

	for row, y in &tiles {
		above.exists = y > 0;
		below.exists = i32(y) < height - 1;

		if above.exists do above.row = tiles[y - 1];
		if below.exists do below.row = tiles[y + 1];

        for tile, x in &row {
        	left.exists  = x > 0;
        	right.exists = i32(x) < width - 1;

        	if left.exists  do left.tile  = &row[x - 1];
        	if right.exists do right.tile = &row[x + 1]; 
        	if above.exists do above.tile = &above.row[x]; 
        	if below.exists do below.tile = &below.row[x];

        	using tile;
        	if is_full {
				has_left_edge   = left.exists  && !left.tile.is_full;
	        	has_right_edge  = right.exists && !right.tile.is_full;
	        	has_top_edge    = above.exists && !above.tile.is_full;
	        	has_bottom_edge = below.exists && !below.tile.is_full;

	        	if has_left_edge { // Create/extend left edge:
		        	if above.exists && above.tile.has_left_edge { // Tile above has a left edge, extend it:
		        		left_edge = above.tile.left_edge;
		        		left_edge.length += tile_size;
		        		left_edge.to.y += tile_size;
		        	} else { // No left edge above - create new one:
		        		left_edge = &all_edges[edge_id];
		        		initTileEdge(left_edge);
						edge_id += 1;

						using left_edge;
		        		color = WHITE;
		        		length = tile_size;

		        		from = nil;
		        		local.from = nil;
		        		if left.exists && above.exists {
		        			top_left := &above.row[x-1];
		        			if top_left.is_full && 
		        			   top_left.has_right_edge && 
		        			   top_left.has_bottom_edge {
		        				from = top_left.bottom_edge.to;
		        				local.from = top_left.bottom_edge.local.to;
		        			}
		        		}

		        		if from == nil {
		        			from = &all_vertices[vertex_id];
		        			local.from = &all_vertices_transformed[vertex_id];
		        			vertex_id += 1;

		        			from^ = position;

		        			local.from.x = f32(from.x);
		        			local.from.y = f32(from.y);
		        		}

		        		to = &all_vertices[vertex_id];
		        		local.to = &all_vertices_transformed[vertex_id];
		        		vertex_id += 1;

		        		to^ = position;
		        		to.y += tile_size;

	        			local.to.x = f32(to.x);
	        			local.to.y = f32(to.y);
		        		
		        		is_facing_left = true;
		        	}
		        }

				if has_right_edge { // Create/extend right edge:
		        	if above.exists && above.tile.has_right_edge { // Tile above has a right edge, extend it:
		        		right_edge = above.tile.right_edge;
		        		right_edge.length += tile_size;
		        		right_edge.to.y += tile_size;
		        	} else { // No right edge above - create new one:
		        		right_edge = &all_edges[edge_id];
		        		initTileEdge(right_edge);
						edge_id += 1;

						using right_edge;
		        		color = WHITE;
		        		length = tile_size;

						from = nil;
		        		local.from = nil;
		        		if right.exists && above.exists {
		        			top_right := &above.row[x+1];
		        			if top_right.is_full &&
		        			   top_right.has_left_edge &&
		        			   top_right.has_bottom_edge {
		        				from = top_right.bottom_edge.from;
		        				local.from = top_right.bottom_edge.local.from;
		        			}
		        		}

		        		if from == nil {
		        			from = &all_vertices[vertex_id];
		        			local.from = &all_vertices_transformed[vertex_id];
		        			vertex_id += 1;

		        			from^ = position;
		        			from.x += tile_size;

		        			local.from.x = f32(from.x);
		        			local.from.y = f32(from.y);
		        		}

						to = &all_vertices[vertex_id];
		        		local.to = &all_vertices_transformed[vertex_id];
		        		vertex_id += 1;

		        		to^ = position;
		        		to.x += tile_size;
		        		to.y += tile_size;

	        			local.to.x = f32(to.x);
	        			local.to.y = f32(to.y);
		        		
		        		is_facing_right = true;
		        	}
		        }

		        if has_top_edge { // Create/extend top edge:
		        	if left.exists && left.tile.has_top_edge { // Tile on the left has a top edge, extend it:
		        		top_edge = left.tile.top_edge;
		        		top_edge.length += tile_size;
		        		top_edge.to.x += tile_size;
		        	} else { // No top edge on the left - create new one:
		        		top_edge = &all_edges[edge_id];
		        		initTileEdge(top_edge);
						edge_id += 1;

						using top_edge;
		        		color = WHITE;
		        		length = tile_size;

						from = nil;
		        		local.from = nil;
		        		if left.exists && above.exists {
		        			top_left := &above.row[x-1];
		        			if top_left.is_full && 
		        			   top_left.has_right_edge && 
		        			   top_left.has_bottom_edge {
		        				from = top_left.bottom_edge.to;
		        				local.from = top_left.bottom_edge.local.to;
		        			}
		        		}

						to = nil;
		        		local.to = nil;
		        		if right.exists && above.exists {
		        			top_right := &above.row[x+1];
		        			if top_right.is_full &&
		        			   top_right.has_left_edge &&
		        			   top_right.has_bottom_edge {
		        				to = top_right.bottom_edge.from;
		        				local.to = top_right.bottom_edge.local.from;
		        			}
		        		}

		        		if from == nil {
		        			from = &all_vertices[vertex_id];
		        			local.from = &all_vertices_transformed[vertex_id];
		        			vertex_id += 1;

		        			from^ = position;

		        			local.from.x = f32(from.x);
		        			local.from.y = f32(from.y);
		        		}

						if to == nil {
		        			to = &all_vertices[vertex_id];
		        			local.to = &all_vertices_transformed[vertex_id];
		        			vertex_id += 1;

		        			to^ = position;
		        			to.x += tile_size;

		        			local.to.x = f32(to.x);
		        			local.to.y = f32(to.y);
		        		}
		        		
		        		is_facing_up = true;
		        		is_horizontal = true;
		        	}
		        }

		        if has_bottom_edge { // Create/extend bottom edge:
		        	if left.exists && left.tile.has_bottom_edge {// Tile on the left has a bottom edge, extend it:
		        		bottom_edge = left.tile.bottom_edge;
		        		bottom_edge.length += tile_size;
		        		bottom_edge.to.x += tile_size;
		        	} else { // No bottom edge on the left - create new one:
		        		bottom_edge = &all_edges[edge_id];
		        		initTileEdge(bottom_edge);
						edge_id += 1;

						using bottom_edge;
		        		color = WHITE;
		        		length = tile_size;

	        			from = &all_vertices[vertex_id];
	        			local.from = &all_vertices_transformed[vertex_id];
	        			vertex_id += 1;

	        			from^ = position;
	        			from.y += tile_size;

	        			local.from.x = f32(from.x);
	        			local.from.y = f32(from.y);

	        			to = &all_vertices[vertex_id];
	        			local.to = &all_vertices_transformed[vertex_id];
	        			vertex_id += 1;

	        			to^ = position;
	        			to.x += tile_size;
	        			to.y += tile_size;

	        			local.to.x = f32(to.x);
	        			local.to.y = f32(to.y);

		        		is_facing_down = true;
		        		is_horizontal = true;
		        	}
		        }
        	} else {
        		has_left_edge   = false;
	        	has_right_edge  = false;
	        	has_top_edge    = false;
	        	has_bottom_edge = false;
        	}
        	

	        bounds.left = position.x;
	        bounds.right = position.x + tile_size;

	        bounds.top = position.y;
	        bounds.bottom = position.y + tile_size;

			position.x += tile_size;
        }

        position.x  = 0;
        position.y += tile_size;
    }

	edges = all_edges[:edge_id];
	vertices = all_vertices[:vertex_id];
	vertices_transformed = all_vertices_transformed[:vertex_id];
}