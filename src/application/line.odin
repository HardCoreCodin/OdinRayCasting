package application

_drawHLine2Di :: inline proc(from, to, at: i32, color: ^Color, using bitmap: ^Bitmap) {
	if !_inRangeI(at, height) do return;
	offset := at * width;
	first, last := _subRangeI(from, to, width);
	first += offset;
	last += offset;
	for i in first..last do all_pixels[i].color = color^;
};
_drawHLine2Df :: inline proc(from, to, at: f32, color: ^Color, using bitmap: ^Bitmap) do _drawHLine2Di(i32(from), i32(to), i32(at), color, bitmap);
drawHLine2D :: proc{_drawHLine2Di, _drawHLine2Df};

_drawVLine2Di :: inline proc(from, to, at: i32, color: ^Color, using bitmap: ^Bitmap) {
	if !inRange(at, width) do return;
	first, last := _subRangeI(from, to, height);
	first *= width; first += at;
	last  *= width; last  += at;
	for i := first; i <= last; i += width do all_pixels[i].color = color^;
}
_drawVLine2Df :: inline proc(from, to, at: f32, color: ^Color, using bitmap: ^Bitmap) do _drawVLine2Di(i32(from), i32(to), i32(at), color, bitmap);
drawVLine2D :: proc{_drawVLine2Di, _drawVLine2Df};

_drawLine2Di :: inline proc(x0, y0, x1, y1: i32, color: ^Color, using bitmap: ^Bitmap) {
	if x0 == x1 {
		_drawVLine2Di(y0, y1, x1, color, bitmap);
		return;
	} 
	if y0 == y1 {
		_drawHLine2Di(x0, x1, y1, color, bitmap);
		return;
	}
	
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
        	if _inRangeI(current1, height) && _inRangeI(current2, width) do
        		all_pixels[index].color = color^;
        } else
        	if _inRangeI(current2, height) && _inRangeI(current1, width) do
        		all_pixels[index].color = color^;
        
        index += index_inc1;
        error += error_inc;
        if error > threshold {
            error -= error_dec;
            index += index_inc2;
            current2 += inc2;
        }
    }
}
_drawLine2Df :: inline proc(x0, y0, x1, y1: f32, color: ^Color, using bitmap: ^Bitmap) do _drawLine2Di(i32(x0), i32(y0), i32(x1), i32(y1), color, bitmap);
_drawLineVec2i :: inline proc(from, to: vec2i, color: ^Color, using bitmap: ^Bitmap) do _drawLine2Di(from.x, from.y, to.x, to.y, color, bitmap);
_drawLineVec2f :: inline proc(from, to: vec2,  color: ^Color, using bitmap: ^Bitmap) do _drawLine2Df(from.x, from.y, to.x, to.y, color, bitmap);

drawLine :: proc{_drawLine2Di, _drawLine2Df, _drawLineVec2i, _drawLineVec2f};