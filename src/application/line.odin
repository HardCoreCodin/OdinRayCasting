package application

_drawHLine2Di :: inline proc(using bitmap: ^Bitmap, from, to, at: i32, color: Color, opacity: u8 = 255) {
	if !_inRangeI(0, at, height - 1) do return;
	offset := at * width;
	first, last := _subRangeI(from, to, width);
	first += offset;
	last += offset;
    pixel: Pixel = {color = color, opacity = opacity};
	for i in first..last do all_pixels[i] = pixel;
};
_drawVLine2Di :: inline proc(using bitmap: ^Bitmap, from, to, at: i32, color: Color, opacity: u8 = 255) {
	if !inRange(0, at, width - 1) do return;
	first, last := _subRangeI(from, to, height);
	first *= width; first += at;
	last  *= width; last  += at;
    pixel: Pixel = {color = color, opacity = opacity};
	for i := first; i <= last; i += width do all_pixels[i] = pixel;
}
_drawHLine2Df :: inline proc(using bitmap: ^Bitmap, from, to, at: f32, color: Color, opacity: u8 = 255) do _drawHLine2Di(bitmap, i32(from), i32(to), i32(at), color, opacity);
_drawVLine2Df :: inline proc(using bitmap: ^Bitmap, from, to, at: f32, color: Color, opacity: u8 = 255) do _drawVLine2Di(bitmap, i32(from), i32(to), i32(at), color, opacity);
drawVLine2D :: proc{_drawVLine2Di, _drawVLine2Df};
drawHLine2D :: proc{_drawHLine2Di, _drawHLine2Df};

_drawLine2Di :: inline proc(using bitmap: ^Bitmap, x0, y0, x1, y1: i32, color: Color, opacity: u8 = 255) {
	if x0 == x1 {
		_drawVLine2Di(bitmap, y0, y1, x1, color, opacity);
		return;
	} 
	if y0 == y1 {
		_drawHLine2Di(bitmap, x0, x1, y1, color, opacity);
		return;
	}

    pixel: Pixel = {color = color, opacity = opacity};
	
    pitch := width;
	index := x0 + y0 * width;
    run : = x1 - x0;
    rise: = y1 - y0;
	dx: i32 = 1;
    dy: i32 = 1;
    if run < 0 {
        dx = -dx;
        run = -run;
    }
    if rise < 0 {
        dy = -dy;
        rise = -rise;
        pitch = -pitch;
    }

    // Configure for a shallow line:
    end := x1 + dx;
    start1 := x0;  inc1 := dx;  index_inc1 := dx;
    start2 := y0;  inc2 := dy;  index_inc2 := pitch;
    rise_twice := rise + rise; 
    run_twice := run + run;
    threshold := run;
    error_dec := run_twice;
    error_inc := rise_twice;
    is_steap := rise > run;
    if is_steap { // Reconfigure for a steep line:
        inc1, inc2 = inc2, inc1;
        start1, start2 = start2, start1;
        index_inc1, index_inc2 = index_inc2, index_inc1;
        error_dec, error_inc = error_inc, error_dec;
        end = y1 + dy;
        threshold = rise;
    }

    error: i32 = 0;
    current1 := start1;
    current2 := start2;
    for current1 != end {
        current1 += inc1;
        if is_steap {
        	if index > 0 && _inRangeI(0, current1, height-1) && _inRangeI(0, current2, width-1) do
        		all_pixels[index] = pixel;
        } else
        	if index > 0 &&_inRangeI(0, current2, height-1) && _inRangeI(0, current1, width-1) do
        		all_pixels[index] = pixel;
        
        index += index_inc1;
        error += error_inc;
        if error > threshold {
            error -= error_dec;
            index += index_inc2;
            current2 += inc2;
        }
    }
}
_drawLine2Df :: inline proc(using bitmap: ^Bitmap, x0, y0, x1, y1: f32, color: Color, opacity: u8 = 255) do _drawLine2Di(bitmap, i32(x0), i32(y0), i32(x1), i32(y1), color, opacity);
_drawLineVec2i :: inline proc(using bitmap: ^Bitmap, from, to: vec2i, color: Color, opacity: u8 = 255) do _drawLine2Di(bitmap, from.x, from.y, to.x, to.y, color, opacity);
_drawLineVec2f :: inline proc(using bitmap: ^Bitmap, from, to: vec2,  color: Color, opacity: u8 = 255) do _drawLine2Df(bitmap, from.x, from.y, to.x, to.y, color, opacity);
drawLine :: proc{_drawLine2Di, _drawLine2Df, _drawLineVec2i, _drawLineVec2f};

lineSegmentsIntersect :: proc(A, B, C, D: vec2, P: ^vec2) -> bool {
    CD := D - C;
    AB := B - A;
    AB_ := perp(AB);
    ABxCD := dot(CD, AB_); 
    
    start, end: f32;
         if ABxCD > 0 do   end = ABxCD; 
    else if ABxCD < 0 do start = ABxCD; 
    else do return false; 
    
    CA := A - C;
    s := dot(CA, AB_); 
    if !inRange(start, s, end) do return false;
    
    CD_ := perp(CD);
    t := dot(CA, CD_); 
    if !inRange(start, t, end) do return false;

    P^ = A + AB*t/ABxCD;
    return true;
}