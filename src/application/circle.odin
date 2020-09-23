package application

_drawCircle2Di :: inline proc(using bitmap: ^Bitmap, Px, Py, R: i32, color: Color, opacity: u8 = 255) {
	x, y, y2: i32;
	r2 := R * R;
	x2 := r2;
	x = R;
	c := color;
	
	Sx1 := Px - R;
	Ex1 := Px + R;
	Sy1 := Py * width;
	Ey1 := Sy1;
	
	Sx2 := Px;
	Ex2 := Px;
	Sy2 := (Py - R) * width;
	Ey2 := (Py + R) * width;

	for y <= x {
		if Sy1 >= 0 && Sy1 < size {
			if Sx1 >= 0 && Sx1 < width do all_pixels[Sy1 + Sx1].color = c; 
			if Ex1 >= 0 && Ex1 < width do all_pixels[Sy1 + Ex1].color = c;
		}
		if Ey1 >= 0 && Ey1 < size {
			if Sx1 >= 0 && Sx1 < width do all_pixels[Ey1 + Sx1].color = c;
			if Ex1 >= 0 && Ex1 < width do all_pixels[Ey1 + Ex1].color = c; 
		}

		if Sy2 >= 0 && Sy2 < size {
			if Sx2 >= 0 && Sx2 < width do all_pixels[Sy2 + Sx2].color = c; 
			if Ex2 >= 0 && Ex2 < width do all_pixels[Sy2 + Ex2].color = c; 
		}
		if Ey2 >= 0 && Ey2 < size {
			if Sx2 >= 0 && Sx2 < width do all_pixels[Ey2 + Sx2].color = c; 
			if Ex2 >= 0 && Ex2 < width do all_pixels[Ey2 + Ex2].color = c;
		}

		if (x2 + y2) > r2 {
			x -= 1;
			x2 = x * x;

			Sx1 += 1;
			Ex1 -= 1;

			Sy2 += width;
			Ey2 -= width;
		}

		y += 1;
		y2 = y * y;

		Sy1 -= width;
		Ey1 += width;
		
		Sx2 -= 1;
		Ex2 += 1;
	}
}
_drawCircle2Df :: inline proc(bitmap: ^Bitmap, Px, Py, R: f32, color: Color, opacity: u8 = 255) do _drawCircle2Di(bitmap, i32(Px), i32(Py), i32(R), color, opacity);
_drawCircle2DVec2i :: inline proc(bitmap: ^Bitmap, pos: vec2i, R: i32, color: Color, opacity: u8 = 255) do _drawCircle2Di(bitmap, pos.x, pos.y, R, color, opacity);
_drawCircle2DVec2f :: inline proc(bitmap: ^Bitmap, pos: vec2,  R: f32, color: Color, opacity: u8 = 255) do _drawCircle2Df(bitmap, pos.x, pos.y, R, color, opacity);
drawCircle :: proc{_drawCircle2Di, _drawCircle2Df, _drawCircle2DVec2i, _drawCircle2DVec2f};

_fillCircle2Di :: inline proc(using bitmap: ^Bitmap, Px, Py, R: i32, color: Color, opacity: u8 = 255) {
	pixel: Pixel = {color = color, opacity = opacity};

	if R == 1 {
		if inRange(0, Px, width-1) &&
		   inRange(0, Py, height-1) do
		   pixels[Py][Px] = pixel;
		return;
	}

	x, y, y2: i32;
	r2 := R * R;
	x2 := r2;
	x = R;

	Sx1 := Px - R;
	Ex1 := Px + R;
	Sy1 := Py * width;
	Ey1 := Sy1;
	
	Sx2 := Px;
	Ex2 := Px;
	Sy2 := (Py - R) * width;
	Ey2 := (Py + R) * width;
	
	for y <= x {
		if Sy1 >= 0 && Sy1 < size do for x1 in max(Sx1, 0)..min(Ex1, width-1) do all_pixels[Sy1 + x1] = pixel;
		if Ey1 >= 0 && Ey1 < size do for x1 in max(Sx1, 0)..min(Ex1, width-1) do all_pixels[Ey1 + x1] = pixel;
		
		if Sy2 >= 0 && Sy2 < size do for x2 in max(Sx2, 0)..min(Ex2, width-1) do all_pixels[Sy2 + x2] = pixel;
		if Ey2 >= 0 && Ey2 < size do for x2 in max(Sx2, 0)..min(Ex2, width-1) do all_pixels[Ey2 + x2] = pixel; 

		if (x2 + y2) > r2 {
			x -= 1;
			x2 = x * x;

			Sx1 += 1;
			Ex1 -= 1;

			Sy2 += width;
			Ey2 -= width;
		}

		y += 1;
		y2 = y * y;

		Sy1 -= width;
		Ey1 += width;
		
		Sx2 -= 1;
		Ex2 += 1;
	}
}
_fillCircle2Df :: inline proc(bitmap: ^Bitmap, Px, Py, R: f32, color: Color, opacity: u8 = 255) do _fillCircle2Di(bitmap, i32(Px), i32(Py), i32(R), color, opacity);
_fillCircle2DVec2i :: inline proc(bitmap: ^Bitmap, pos: vec2i, R: i32, color: Color, opacity: u8 = 255) do _fillCircle2Di(bitmap, pos.x, pos.y, R, color, opacity);
_fillCircle2DVec2f :: inline proc(bitmap: ^Bitmap, pos: vec2,  R: f32, color: Color, opacity: u8 = 255) do _fillCircle2Df(bitmap, pos.x, pos.y, R, color, opacity);
fillCircle :: proc{_fillCircle2Di, _fillCircle2Df, _fillCircle2DVec2i, _fillCircle2DVec2f};

drawCircleUnsafe :: proc(Px, Py, R: i32, color: Color, using bitmap: ^Bitmap) {
	x, y, y2: i32;
	r2 := R * R;
	x2 := r2;
	x = R;
	c := color;
	
	Sx1 := Px - R;
	Ex1 := Px + R;
	Sy1 := Py * width;
	Ey1 := Sy1;
	
	Sx2 := Px;
	Ex2 := Px;
	Sy2 := (Py - R) * width;
	Ey2 := (Py + R) * width;

	for y <= x {
		all_pixels[Sy1 + Sx1].color = c; 
		all_pixels[Ey1 + Sx1].color = c;

		all_pixels[Sy1 + Ex1].color = c;
		all_pixels[Ey1 + Ex1].color = c; 


		all_pixels[Sy2 + Sx2].color = c; 
		all_pixels[Sy2 + Ex2].color = c; 

		all_pixels[Ey2 + Sx2].color = c; 
		all_pixels[Ey2 + Ex2].color = c;

		if (x2 + y2) > r2 {
			x -= 1;
			x2 = x * x;

			Sx1 += 1;
			Ex1 -= 1;

			Sy2 += width;
			Ey2 -= width;
		}

		y += 1;
		y2 = y * y;

		Sy1 -= width;
		Ey1 += width;
		
		Sx2 -= 1;
		Ex2 += 1;
	}
}

fillCircleUnsafe :: proc(Px, Py, R: i32, color: Color, using bitmap: ^Bitmap) {
	x, y, y2: i32;
	r2 := R * R;
	x2 := r2;
	x = R;
	c := color;
	
	Sx1 := Px - R;
	Ex1 := Px + R;
	Sy1 := Py * width;
	Ey1 := Sy1;
	
	Sx2 := Px;
	Ex2 := Px;
	Sy2 := (Py - R) * width;
	Ey2 := (Py + R) * width;

	for y <= x {
		for x1 in Sx1..Ex1 {
			all_pixels[Sy1 + x1].color = c;
			all_pixels[Ey1 + x1].color = c; 
		}
		for x2 in Sx2..Ex2 {
			all_pixels[Sy2 + x2].color = c;
			all_pixels[Ey2 + x2].color = c; 
		}

		if (x2 + y2) > r2 {
			x -= 1;
			x2 = x * x;

			Sx1 += 1;
			Ex1 -= 1;

			Sy2 += width;
			Ey2 -= width;
		}

		y += 1;
		y2 = y * y;

		Sy1 -= width;
		Ey1 += width;
		
		Sx2 -= 1;
		Ex2 += 1;
	}
}


drawCircle2 :: proc(pos: vec2i, radius: i32, color: Color, using bitmap: ^Bitmap) {
	right := pos.x + radius;
	left  := pos.x - radius;

	top    := pos.y;
	bottom := pos.y;

	right_in_range,
	left_in_range,
	top_in_range,
	bottom_in_range: bool;

	x := radius;
	x2 := x * x;
	r2 := x2;

	r_top, r_bottom, r_left, r_right: i32;
	
	for y in 1..radius {
		if y > x do break;

		right_in_range  = right  >= 0 && right  < width;
		left_in_range   = left   >= 0 && left   < width;
		top_in_range    = top    >= 0 && top    < height;
		bottom_in_range = bottom >= 0 && bottom < height;

		if right_in_range {
	   		if top_in_range    do pixels[top   ][right].color = color;
	   		if bottom_in_range do pixels[bottom][right].color = color;
	   	}

		if left_in_range {
	   		if top_in_range    do pixels[top   ][left].color = color;
	   		if bottom_in_range do pixels[bottom][left].color = color;
	   	}

	   	// Rotate 90 deg.
	   	r_top    = pos.y - x;
	   	r_bottom = pos.y + x;
	   	r_right  = pos.x + y - 1;
	   	r_left   = pos.x - y + 1;

		right_in_range  = r_right  >= 0 && r_right  < width;
		left_in_range   = r_left   >= 0 && r_left   < width;
		top_in_range    = r_top    >= 0 && r_top    < height;
		bottom_in_range = r_bottom >= 0 && r_bottom < height;

		if top_in_range {
	   		if right_in_range do pixels[r_top][r_right].color = color;
	   		if left_in_range  do pixels[r_top][r_left ].color = color;
	   	}

		if bottom_in_range {
	   		if right_in_range do pixels[r_bottom][r_right].color = color;
	   		if left_in_range  do pixels[r_bottom][r_left ].color = color;
	   	}

		if x2 + y*y > r2 {
			x -= 1;
			x2 = x * x;
			right -= 1;
			left  += 1;
		}

		top    -= 1;
		bottom += 1;
	}
}