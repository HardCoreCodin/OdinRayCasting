package application

TopLeft2Df :: struct {left, top: f32}
TopLeft2Di :: struct {left, top: i32}
BottomRight2Df :: struct {right, bottom: f32}
BottomRight2Di :: struct {right, bottom: i32}

TopLeft2DfMin :: struct #raw_union {min: vec2, using top_left: TopLeft2Df};
TopLeft2DiMin :: struct #raw_union {min: vec2i, using top_left: TopLeft2Di};
BottomRight2DfMax :: struct #raw_union {max: vec2, using bottom_right: BottomRight2Df};
BottomRight2DiMax :: struct #raw_union {max: vec2i, using bottom_right: BottomRight2Di};

Bounds2Df :: struct {using tl: TopLeft2DfMin, using br: BottomRight2DfMax}
Bounds2Di :: struct {using tl: TopLeft2DiMin, using br: BottomRight2DiMax}

Rect2Df :: struct {using bounds: Bounds2Df, using size: Size2Df,  position: vec2}
Rect2Di :: struct {using bounds: Bounds2Di, using size: Size2Di, position: vec2i}

_drawRect2Di :: inline proc(X0, Y0, X1, Y1: i32, color: Color, using bitmap: ^Bitmap) {
	_drawHLine2Di(X0, X1, Y0, color, bitmap);
	_drawHLine2Di(X0, X1, Y1, color, bitmap);
	_drawHLine2Di(Y0, Y1, X0, color, bitmap);
	_drawHLine2Di(Y0, Y1, X0, color, bitmap);
}
_drawRect2Df :: inline proc(X0, Y0, X1, Y1: f32, color: Color, using bitmap: ^Bitmap) do
	_drawRect2Di(i32(X0), i32(Y0), i32(X1), i32(Y1), color, bitmap);

drawBounds2Df :: inline proc(using b: ^Bounds2Df, color: Color, using bitmap: ^Bitmap) do _drawRect2Df(left, top, right, bottom, color, bitmap);
drawBounds2Di :: inline proc(using b: ^Bounds2Di, color: Color, using bitmap: ^Bitmap) do _drawRect2Di(left, top, right, bottom, color, bitmap);
drawRect2Df :: inline proc(using r: ^Rect2Df, color: Color, bitmap: ^Bitmap) do _drawRect2Df(left, top, right, bottom, color, bitmap);
drawRect2Di :: inline proc(using r: ^Rect2Di, color: Color, bitmap: ^Bitmap) do _drawRect2Di(left, top, right, bottom, color, bitmap);
drawRectByVec2fPair :: inline proc(a, b: vec2,  color: Color, using bitmap: ^Bitmap) do _drawRect2Df(a.x, a.y, b.x, b.y, color, bitmap);
drawRectByVec2iPair :: inline proc(a, b: vec2i, color: Color, using bitmap: ^Bitmap) do _drawRect2Di(a.x, a.y, b.x, b.y, color, bitmap);
drawRect :: proc{_drawRect2Di, _drawRect2Df, drawRect2Df, drawRect2Di, drawBounds2Df, drawBounds2Di, drawRectByVec2fPair, drawRectByVec2iPair};

_fillRect2Di :: inline proc(X0, Y0, X1, Y1: i32, color: Color, using bitmap: ^Bitmap) {
	if Y0 >= height || Y1 < 0 || 
	   X0 >= width  || X1 < 0 do 
	   return;
	
	x0, x1 := subRange(X0, X1, width);
	y0, y1 := subRange(Y0, Y1, height);
	
	offset := y0 * width;
	for y in y0..y1 {
		for i in x0+offset..x1+offset do all_pixels[i].color = color;
		offset += width;
	}	
}
_fillRect2Df :: inline proc(X0, Y0, X1, Y1: f32, color: Color, using bitmap: ^Bitmap) do
	_fillRect2Di(i32(X0), i32(Y0), i32(X1), i32(Y1), color, bitmap);

fillBounds2Df :: inline proc(using b: ^Bounds2Df, color: Color, using bitmap: ^Bitmap) do _fillRect2Df(left, top, right, bottom, color, bitmap);
fillBounds2Di :: inline proc(using b: ^Bounds2Di, color: Color, using bitmap: ^Bitmap) do _fillRect2Di(left, top, right, bottom, color, bitmap);
fillRect2Df :: inline proc(using r: ^Rect2Df, color: Color, bitmap: ^Bitmap) do _fillRect2Df(left, top, right, bottom, color, bitmap);
fillRect2Di :: inline proc(using r: ^Rect2Di, color: Color, bitmap: ^Bitmap) do _fillRect2Di(left, top, right, bottom, color, bitmap);
fillRectByVec2fPair :: inline proc(a, b: vec2,  color: Color, using bitmap: ^Bitmap) do _fillRect2Df(a.x, a.y, b.x, b.y, color, bitmap);
fillRectByVec2iPair :: inline proc(a, b: vec2i, color: Color, using bitmap: ^Bitmap) do _fillRect2Di(a.x, a.y, b.x, b.y, color, bitmap);
fillRect :: proc{_fillRect2Di, _fillRect2Df, fillRect2Df, fillRect2Di, fillBounds2Df, fillBounds2Di, fillRectByVec2fPair, fillRectByVec2iPair};

_areCompRectBoundsOverlappingF :: inline proc(
	a_min_x, a_min_y, a_max_x, a_max_y,
	b_min_x, b_min_y, b_max_x, b_max_y: f32
) -> bool do return !(
	a_min_x < b_max_x || a_max_x > b_min_x ||
	a_min_y < b_max_y || a_max_y > b_min_y	
);
_areCompRectBoundsOverlappingI :: inline proc(
	a_min_x, a_min_y, a_max_x, a_max_y,
	b_min_x, b_min_y, b_max_x, b_max_y: i32
) -> bool do return !(
	a_min_x < b_max_x || a_max_x > b_min_x ||
	a_min_y < b_max_y || a_max_y > b_min_y	
);
_areBoundsOverlappingVec2i :: inline proc(a_min, a_max, b_min, b_max: vec2i) -> bool do 
	return _areCompRectBoundsOverlappingI(a_min.x, a_min.y, a_max.x, a_max.y,
		                                  b_min.x, b_min.y, b_max.x, b_max.y);
_areBoundsOverlappingVec2f :: inline proc(a_min, a_max, b_min, b_max: vec2) -> bool do 
	return _areCompRectBoundsOverlappingF(a_min.x, a_min.y, a_max.x, a_max.y,
		                                  b_min.x, b_min.y, b_max.x, b_max.y);
areBoundsOverlappingI :: inline proc(a, b: Bounds2Di) -> bool do return _areBoundsOverlappingVec2i(a.min, a.max, b.min, b.max);
areBoundsOverlappingF :: inline proc(a, b: Bounds2Df) -> bool do return _areBoundsOverlappingVec2f(a.min, a.max, b.min, b.max);
areRectsOverlappingI  :: inline proc(a, b: Rect2Di  ) -> bool do return _areBoundsOverlappingVec2i(a.min, a.max, b.min, b.max);
areRectsOverlappingF  :: inline proc(a, b: Rect2Df  ) -> bool do return _areBoundsOverlappingVec2f(a.min, a.max, b.min, b.max);
areRectsOverlapping :: proc{
	_areCompRectBoundsOverlappingF,
	_areCompRectBoundsOverlappingI,
	_areBoundsOverlappingVec2i,
	_areBoundsOverlappingVec2f,
	areBoundsOverlappingI,
	areBoundsOverlappingF,
	areRectsOverlappingI,
	areRectsOverlappingF
};