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

Rect2Df :: struct {using bounds: Bounds2Df, using size: Size2Df, position: vec2}
Rect2Di :: struct {using bounds: Bounds2Di, using size: Size2Di, position: vec2i}

_inBounds2Df :: inline proc(using b: Bounds2Df, p: vec2) -> bool do return _inRangeF(min.x, p.x, max.x) && _inRangeF(min.y, p.y, max.y);
_inBounds2Di :: inline proc(using b: Bounds2Di, p: vec2i) -> bool do return _inRangeI(min.x, p.x, max.x) && _inRangeI(min.y, p.y, max.y);
inBounds :: proc{_inBounds2Df, _inBounds2Di};

_inRect2Df :: inline proc(using r: Rect2Df, p: vec2) -> bool do return _inBounds2Df(bounds, p);
_inRect2Di :: inline proc(using r: Rect2Di, p: vec2i) -> bool do return _inBounds2Di(bounds, p);
inRect :: proc{_inRect2Df, _inRect2Di};

_drawRect2Di :: inline proc(using bitmap: ^$T/Grid, X0, Y0, X1, Y1: i32, pixel: ^$PixelType) {
	_drawHLine2Di(bitmap, X0, X1, Y0,pixel);
	_drawHLine2Di(bitmap, X0, X1, Y1,pixel);
	_drawVLine2Di(bitmap, Y0, Y1, X0,pixel);
	_drawVLine2Di(bitmap, Y0, Y1, X1,pixel);
}
_drawRect2Df :: inline proc(using bitmap: ^$T/Grid, X0, Y0, X1, Y1: f32, pixel: ^$PixelType) do _drawRect2Di(bitmap, i32(X0), i32(Y0), i32(X1), i32(Y1),pixel);
drawBounds2Df :: inline proc(using bitmap: ^$T/Grid, using b: ^Bounds2Df, pixel: ^$PixelType) do _drawRect2Df(bitmap, left, top, right, bottom,pixel);
drawBounds2Di :: inline proc(using bitmap: ^$T/Grid, using b: ^Bounds2Di, pixel: ^$PixelType) do _drawRect2Di(bitmap, left, top, right, bottom,pixel);
drawRect2Df :: inline proc(bitmap: ^$T/Grid, using r: ^Rect2Df, pixel: ^$PixelType) do _drawRect2Df(bitmap, left, top, right, bottom,pixel);
drawRect2Di :: inline proc(bitmap: ^$T/Grid, using r: ^Rect2Di, pixel: ^$PixelType) do _drawRect2Di(bitmap, left, top, right, bottom,pixel);
drawRectByVec2fPair :: inline proc(using bitmap: ^$T/Grid, a, b: vec2,  pixel: ^$PixelType) do _drawRect2Df(bitmap, a.x, a.y, b.x, b.y,pixel);
drawRectByVec2iPair :: inline proc(using bitmap: ^$T/Grid, a, b: vec2i, pixel: ^$PixelType) do _drawRect2Di(bitmap, a.x, a.y, b.x, b.y,pixel);
drawRect :: proc{_drawRect2Di, _drawRect2Df, drawRect2Df, drawRect2Di, drawBounds2Df, drawBounds2Di, drawRectByVec2fPair, drawRectByVec2iPair};

_fillRect2Di :: inline proc(using bitmap: ^$T/Grid, X0, Y0, X1, Y1: i32, pixel: ^$PixelType) {
	if Y0 >= height || Y1 < 0 || 
	   X0 >= width  || X1 < 0 do 
	   return;
	
	x0, x1 := subRange(X0, X1, width);
	y0, y1 := subRange(Y0, Y1, height);
	
	offset := y0 * width;
	for y in y0..y1 {
		for i in x0+offset..x1+offset do setPixel(&_cells[i], pixel);
		offset += width;
	}	
}
_fillRect2Df :: inline proc(bitmap: ^$T/Grid, X0, Y0, X1, Y1: f32, pixel: ^$PixelType) do _fillRect2Di(bitmap, i32(X0), i32(Y0), i32(X1), i32(Y1),pixel);
fillBounds2Df :: inline proc(bitmap: ^$T/Grid, using b: ^Bounds2Df, pixel: ^$PixelType) do _fillRect2Df(bitmap, left, top, right, bottom,pixel);
fillBounds2Di :: inline proc(bitmap: ^$T/Grid, using b: ^Bounds2Di, pixel: ^$PixelType) do _fillRect2Di(bitmap, left, top, right, bottom,pixel);
fillRect2Df :: inline proc(bitmap: ^$T/Grid, using r: ^Rect2Df, pixel: ^$PixelType) do _fillRect2Df(bitmap, left, top, right, bottom,pixel);
fillRect2Di :: inline proc(bitmap: ^$T/Grid, using r: ^Rect2Di, pixel: ^$PixelType) do _fillRect2Di(bitmap, left, top, right, bottom,pixel);
fillRectByVec2fPair :: inline proc(bitmap: ^$T/Grid, a, b: vec2,  pixel: ^$PixelType) do _fillRect2Df(bitmap, a.x, a.y, b.x, b.y,pixel);
fillRectByVec2iPair :: inline proc(bitmap: ^$T/Grid, a, b: vec2i, pixel: ^$PixelType) do _fillRect2Di(bitmap, a.x, a.y, b.x, b.y,pixel);
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