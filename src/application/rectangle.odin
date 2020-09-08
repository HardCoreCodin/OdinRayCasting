package application

Rect2Df :: struct {using size: Size2Df,  position: vec2 }
Rect2Di :: struct {using size: Size2Di, position: vec2i}
Bounds2Df :: struct {min, max: vec2 }
Bounds2Di :: struct {min, max: vec2i}

_drawRect2Di :: inline proc(X0, Y0, X1, Y1: i32, color: ^Color, using bitmap: ^Bitmap) {
	_drawHLine2Di(X0, X1, Y0, color, bitmap);
	_drawHLine2Di(X0, X1, Y1, color, bitmap);
	_drawHLine2Di(Y0, Y1, X0, color, bitmap);
	_drawHLine2Di(Y0, Y1, X0, color, bitmap);
}
_drawRect2Df :: inline proc(X0, Y0, X1, Y1: f32, color: ^Color, using bitmap: ^Bitmap) do
	_drawRect2Di(i32(X0), i32(Y0), i32(X1), i32(Y1), color, bitmap);

drawRect2Df :: inline proc(using r: ^Rect2Df, color: ^Color, bitmap: ^Bitmap) do _drawRect2Df(position.x, position.y, position.x + f32(bitmap.width), position.y + f32(bitmap.height), color, bitmap);
drawRect2Di :: inline proc(using r: ^Rect2Di, color: ^Color, bitmap: ^Bitmap) do _drawRect2Di(position.x, position.y, position.x + bitmap.width, position.y + bitmap.height, color, bitmap);
drawBounds2Df :: inline proc(using b: ^Bounds2Df, color: ^Color, using bitmap: ^Bitmap) do _drawRect2Df(min.x, min.y, max.x, max.y, color, bitmap);
drawBounds2Di :: inline proc(using b: ^Bounds2Di, color: ^Color, using bitmap: ^Bitmap) do _drawRect2Di(min.x, min.y, max.x, max.y, color, bitmap);
drawRectByVec2fPair :: inline proc(a, b: vec2,  color: ^Color, using bitmap: ^Bitmap) do _drawRect2Df(a.x, a.y, b.x, b.y, color, bitmap);
drawRectByVec2iPair :: inline proc(a, b: vec2i, color: ^Color, using bitmap: ^Bitmap) do _drawRect2Di(a.x, a.y, b.x, b.y, color, bitmap);
drawRect :: proc{_drawRect2Di, _drawRect2Df, drawRect2Df, drawRect2Di, drawBounds2Df, drawBounds2Di, drawRectByVec2fPair, drawRectByVec2iPair};

_fillRect2Di :: inline proc(X0, Y0, X1, Y1: i32, color: ^Color, using bitmap: ^Bitmap) {
	if Y0 >= height || Y1 < 0 || 
	   X0 >= width  || X1 < 0 do 
	   return;
	
	x0, x1 := subRange(X0, X1, width);
	y0, y1 := subRange(Y0, Y1, height);
	
	offset := y0 * width;
	for y in y0..y1 {
		for i in x0+offset..x1+offset do all_pixels[i].color = color^;
		offset += width;
	}	
}
_fillRect2Df :: inline proc(X0, Y0, X1, Y1: f32, color: ^Color, using bitmap: ^Bitmap) do
	_fillRect2Di(i32(X0), i32(Y0), i32(X1), i32(Y1), color, bitmap);

fillRect2Df :: inline proc(using r: ^Rect2Df, color: ^Color, bitmap: ^Bitmap) do 
	_fillRect2Df(position.x, position.y, position.x + f32(bitmap.width), position.y + f32(bitmap.height), color, bitmap);
fillRect2Di :: inline proc(using r: ^Rect2Di, color: ^Color, bitmap: ^Bitmap) do 
	_fillRect2Di(position.x, position.y, position.x + bitmap.width, position.y + bitmap.height, color, bitmap);
fillBounds2Df :: inline proc(using b: ^Bounds2Df, color: ^Color, using bitmap: ^Bitmap) do _fillRect2Df(min.x, min.y, max.x, max.y, color, bitmap);
fillBounds2Di :: inline proc(using b: ^Bounds2Di, color: ^Color, using bitmap: ^Bitmap) do _fillRect2Di(min.x, min.y, max.x, max.y, color, bitmap);
fillRectByVec2fPair :: inline proc(a, b: vec2,  color: ^Color, using bitmap: ^Bitmap) do _fillRect2Df(a.x, a.y, b.x, b.y, color, bitmap);
fillRectByVec2iPair :: inline proc(a, b: vec2i, color: ^Color, using bitmap: ^Bitmap) do _fillRect2Di(a.x, a.y, b.x, b.y, color, bitmap);
fillRect :: proc{_fillRect2Di, _fillRect2Df, fillRect2Df, fillRect2Di, fillBounds2Df, fillBounds2Di, fillRectByVec2fPair, fillRectByVec2iPair};