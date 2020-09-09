package application





linesRayWithEdge :: proc(a, b, c, d, p: ^vec2i) -> bool {
	ray_direction, edge_vector: vec2i;

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




