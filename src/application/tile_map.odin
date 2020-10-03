package application

MAX_TILE_MAP_VIEW_DISTANCE :: 50;
MAX_TILE_MAP_WIDTH :: 32;
MAX_TILE_MAP_HEIGHT :: 32;
MAX_TILE_MAP_SIZE :: MAX_TILE_MAP_WIDTH * MAX_TILE_MAP_HEIGHT;
MAX_TILE_MAP_VERTICES :: (MAX_TILE_MAP_WIDTH + 1) * (MAX_TILE_MAP_HEIGHT + 1);
MAX_TILE_MAP_EDGES :: MAX_TILE_MAP_WIDTH * (MAX_TILE_MAP_HEIGHT + 1) + MAX_TILE_MAP_HEIGHT * (MAX_TILE_MAP_WIDTH + 1);

Tile :: struct {
	minimap_space : struct {
		bounds: Bounds2Df,
		x_range, 
		y_range: RangeI 
	},

	top_edge, 
	bottom_edge, 
	left_edge, 
	right_edge: ^TileEdge,	

	bounds: Bounds2Di,
	
	is_full,
	has_left_edge,
	has_right_edge,
	has_top_edge,
	has_bottom_edge: bool,
	
	texture_id: u8
}
TileRow :: []Tile;

TileEdge :: struct { 
	local: struct {
		from, to: ^vec2,
		is_above,
		is_below,
		is_left,
		is_right: bool	
	},
	minimap: struct {
		from, to: ^vec2	
	},
	from, to: ^vec2i,
	length: i32,

	is_visible,
    is_vertical,
    is_horizontal,
    is_facing_up,
    is_facing_down,
    is_facing_left,
    is_facing_right,
	is_facing_forward: bool
}

TileMap :: struct {
	using size: Size2Di,
	tiles: []TileRow,
	edges: []TileEdge,
	edge_count,
	vertex_count: i32,
	vertices: []vec2i,
	vertices_in_local_space: []vec2,
	vertices_in_minimap_space: []vec2,

	all_rows: [MAX_TILE_MAP_HEIGHT]TileRow,
	all_tiles: [MAX_TILE_MAP_SIZE]Tile,
	all_edges: [MAX_TILE_MAP_EDGES]TileEdge,
	all_vertices: [MAX_TILE_MAP_VERTICES]vec2i,
	all_vertices_in_local_space: [MAX_TILE_MAP_VERTICES]vec2,
	all_vertices_in_minimap_space: [MAX_TILE_MAP_VERTICES]vec2
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

	texture_id = 0;

	bounds.min.x = 0;
	bounds.min.y = 0;
	bounds.max.x = 0;
	bounds.max.y = 0;

	minimap_space.bounds.min.x = 0;
	minimap_space.bounds.min.y = 0;
	minimap_space.bounds.max.x = 0;
	minimap_space.bounds.max.y = 0;

	minimap_space.x_range.min = 0;
	minimap_space.x_range.max = 0;
	minimap_space.y_range.max = 0;
	minimap_space.y_range.max = 0;
	minimap_space.x_range.range = 0;
	minimap_space.y_range.range = 0;
}

initTileEdge :: inline proc(using te: ^TileEdge) {
	local.from = nil;
	local.to = nil;
	local.is_above = false;
	local.is_below = false;
	local.is_left = false;
	local.is_right = false;

	length = 0;

	minimap.from = nil;
	minimap.to = nil;

	from = nil;
	to = nil;

	is_visible = false;
	is_vertical = false;

	is_facing_left = false;
	is_facing_right = false;
	is_facing_up = false;
	is_facing_down = false;
	is_facing_forward = false;
}

initTileMap :: proc(using tm: ^TileMap, Width: i32 = MAX_TILE_MAP_WIDTH, Height: i32 = MAX_TILE_MAP_HEIGHT) {
	width = Width;
	height = Height;

	edges = all_edges[:];
	vertices = all_vertices[:];
	vertices_in_local_space = all_vertices_in_local_space[:];
	vertices_in_minimap_space = all_vertices_in_minimap_space[:];

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
    bottom = 1;
    left = 1;

    for row, y in &tiles {
        for tile, x in &row {
        	character = ascii_grid[offset];
        	
        	initTile(&tile);
        	using tile;
        	bounds = current_bounds;
        	is_full = character != EMPTY_TILE_CHARACTER;
        	texture_id = is_full ? character - NUMBER_ASCII_OFFSET : 0;

            left += 1;
			right += 1;
            offset += 1;
        }

        left = 0;
		right = 1;
		top += 1;
		bottom += 1;

        offset += 1;
    }
}

moveTileMap :: proc(using tm: ^TileMap, origin: vec2) {
	for vertex, i in &vertices {
		vertices_in_local_space[i].x = f32(vertex.x) - origin.x;
		vertices_in_local_space[i].y = f32(vertex.y) - origin.y;
	}

	for edge in &edges {
		using edge.local;
		is_right = from.x > 0;
		is_below = from.y > 0;
		is_left  = to.x < 0;
		is_above = to.y < 0;

		edge.is_facing_forward = edge.is_vertical ? 
			(edge.is_facing_left && is_right || edge.is_facing_right && is_left ):
			(edge.is_facing_down && is_above || edge.is_facing_up    && is_below);
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

        for current_tile, x in &row {
        	left.exists  = x > 0;
        	right.exists = i32(x) < width - 1;

        	if left.exists  do left.tile  = &row[x - 1];
        	if right.exists do right.tile = &row[x + 1]; 
        	if above.exists do above.tile = &above.row[x]; 
        	if below.exists do below.tile = &below.row[x];

        	if current_tile.is_full {
				current_tile.has_left_edge   = left.exists  && !left.tile.is_full;
	        	current_tile.has_right_edge  = right.exists && !right.tile.is_full;
	        	current_tile.has_top_edge    = above.exists && !above.tile.is_full;
	        	current_tile.has_bottom_edge = below.exists && !below.tile.is_full;

	        	if current_tile.has_left_edge { // Create/extend left edge:
		        	if above.exists && above.tile.has_left_edge { // Tile above has a left edge, extend it:
		        		current_tile.left_edge = above.tile.left_edge;
		        		current_tile.left_edge.length += 1;
		        		current_tile.left_edge.to.y += 1;
		        	} else { // No left edge above - create new one:
		        		current_tile.left_edge = &all_edges[edge_id];
		        		initTileEdge(current_tile.left_edge);
						edge_id += 1;

						using current_tile.left_edge;

		        		from = nil;
		        		local.from = nil;
		        		minimap.from = nil;
		        		if left.exists && above.exists {
		        			top_left := &above.row[x-1];
		        			if top_left.is_full && 
		        			   top_left.has_right_edge && 
		        			   top_left.has_bottom_edge {
		        				from = top_left.bottom_edge.to;
		        				local.from = top_left.bottom_edge.local.to;
		        				minimap.from = top_left.bottom_edge.minimap.to;
		        			}
		        		}

		        		if from == nil {
		        			from = &all_vertices[vertex_id];
		        			local.from = &all_vertices_in_local_space[vertex_id];
		        			minimap.from = &all_vertices_in_minimap_space[vertex_id];
		        			vertex_id += 1;

		        			from^ = position;
		        		}

		        		to = &all_vertices[vertex_id];
		        		local.to = &all_vertices_in_local_space[vertex_id];
		        		minimap.to = &all_vertices_in_minimap_space[vertex_id];
		        		vertex_id += 1;

		        		to^ = position;
		        		to.y += 1;
		        		
		        		is_vertical = true;
		        		is_facing_left = true;
			        }
			    }

				if current_tile.has_right_edge { // Create/extend right edge:
		        	if above.exists && above.tile.has_right_edge { // Tile above has a right edge, extend it:
		        		current_tile.right_edge = above.tile.right_edge;
		        		current_tile.right_edge.length += 1;
		        		current_tile.right_edge.to.y += 1;
		        	} else { // No right edge above - create new one:
		        		current_tile.right_edge = &all_edges[edge_id];
		        		initTileEdge(current_tile.right_edge);
						edge_id += 1;

						using current_tile.right_edge;

						from = nil;
		        		local.from = nil;
		        		minimap.from = nil;
		        		if right.exists && above.exists {
		        			top_right := &above.row[x+1];
		        			if top_right.is_full &&
		        			   top_right.has_left_edge &&
		        			   top_right.has_bottom_edge {
		        				from = top_right.bottom_edge.from;
		        				local.from = top_right.bottom_edge.local.from;
		        				minimap.from = top_right.bottom_edge.minimap.from;
		        			}
		        		}

		        		if from == nil {
		        			from = &all_vertices[vertex_id];
		        			local.from = &all_vertices_in_local_space[vertex_id];
		        			minimap.from = &all_vertices_in_minimap_space[vertex_id];
		        			vertex_id += 1;

		        			from^ = position;
		        			from.x += 1;
		        		}

						to = &all_vertices[vertex_id];
		        		local.to = &all_vertices_in_local_space[vertex_id];
		        		minimap.to = &all_vertices_in_minimap_space[vertex_id];
		        		vertex_id += 1;

		        		to^ = position;
		        		to.x += 1;
		        		to.y += 1;

		        		is_vertical = true;
		        		is_facing_right = true;
			        }
				}

		        if current_tile.has_top_edge { // Create/extend top edge:
		        	if left.exists && left.tile.has_top_edge { // Tile on the left has a top edge, extend it:
		        		current_tile.top_edge = left.tile.top_edge;
		        		current_tile.top_edge.length += 1;
		        		current_tile.top_edge.to.x += 1;
		        	} else { // No top edge on the left - create new one:
		        		current_tile.top_edge = &all_edges[edge_id];
		        		initTileEdge(current_tile.top_edge);
						edge_id += 1;

						using current_tile.top_edge;

						from = nil;
		        		local.from = nil;
		        		minimap.from = nil;
		        		if left.exists && above.exists {
		        			top_left := &above.row[x-1];
		        			if top_left.is_full && 
		        			   top_left.has_right_edge && 
		        			   top_left.has_bottom_edge {
		        				from = top_left.bottom_edge.to;
		        				local.from = top_left.bottom_edge.local.to;
		        				minimap.from = top_left.bottom_edge.minimap.to;
		        			}
		        		}

						to = nil;
		        		local.to = nil;
		        		minimap.to = nil;
		        		if right.exists && above.exists {
		        			top_right := &above.row[x+1];
		        			if top_right.is_full &&
		        			   top_right.has_left_edge &&
		        			   top_right.has_bottom_edge {
		        				to = top_right.bottom_edge.from;
		        				local.to = top_right.bottom_edge.local.from;
		        				minimap.to = top_right.bottom_edge.minimap.from;
		        			}
		        		}

		        		if from == nil {
		        			from = &all_vertices[vertex_id];
		        			local.from = &all_vertices_in_local_space[vertex_id];
		        			minimap.from = &all_vertices_in_minimap_space[vertex_id];
		        			vertex_id += 1;

		        			from^ = position;
		        		}

						if to == nil {
		        			to = &all_vertices[vertex_id];
		        			local.to = &all_vertices_in_local_space[vertex_id];
		        			minimap.to = &all_vertices_in_minimap_space[vertex_id];
		        			vertex_id += 1;

		        			to^ = position;
		        			to.x += 1;
		        		}
		        		
		        		is_vertical = false;
		        		is_facing_up = true;
			        }
		        }

		        if current_tile.has_bottom_edge { // Create/extend bottom edge:
		        	if left.exists && left.tile.has_bottom_edge {// Tile on the left has a bottom edge, extend it:
		        		current_tile.bottom_edge = left.tile.bottom_edge;
		        		current_tile.bottom_edge.length += 1;
		        		current_tile.bottom_edge.to.x += 1;
		        	} else { // No bottom edge on the left - create new one:
		        		current_tile.bottom_edge = &all_edges[edge_id];
		        		initTileEdge(current_tile.bottom_edge);
						edge_id += 1;

						using current_tile.bottom_edge;

	        			from = &all_vertices[vertex_id];
	        			local.from = &all_vertices_in_local_space[vertex_id];
	        			minimap.from = &all_vertices_in_minimap_space[vertex_id];
	        			vertex_id += 1;

	        			from^ = position;
	        			from.y += 1;

	        			to = &all_vertices[vertex_id];
	        			local.to = &all_vertices_in_local_space[vertex_id];
	        			minimap.to = &all_vertices_in_minimap_space[vertex_id];
	        			vertex_id += 1;

	        			to^ = position;
	        			to.x += 1;
	        			to.y += 1;

		        		is_vertical = false;
		        		is_facing_down = true;
			        }
	        	}
        	} else {
        		current_tile.has_left_edge   = false;
	        	current_tile.has_right_edge  = false;
	        	current_tile.has_top_edge    = false;
	        	current_tile.has_bottom_edge = false;
        	}

	        current_tile.bounds.left = position.x;
	        current_tile.bounds.right = position.x + 1;

	        current_tile.bounds.top = position.y;
	        current_tile.bounds.bottom = position.y + 1;

			position.x += 1;
        }

        position.x  = 0;
        position.y += 1;
    }

	edges = all_edges[:edge_id];
	vertices = all_vertices[:vertex_id];
	vertices_in_local_space = all_vertices_in_local_space[:vertex_id];
	vertices_in_minimap_space = all_vertices_in_minimap_space[:vertex_id];
}