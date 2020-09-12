package application

Size2Df :: struct {width, height: f32}
Size2Di :: struct {width, height: i32}

_inRangeI :: inline proc(value, end: i32, start: i32 = 0) -> bool do return value >= start && value <= end;
_inRangeF :: inline proc(value, end: f32, start: f32 = 0) -> bool do return value >= start && value <= end;
inRange :: proc{_inRangeI, _inRangeF};

_subRangeI :: inline proc(from, to, end: i32, start: i32 = 0) -> (first, last: i32) {
	first = from; 
	last  = to;
	if to < from do first, last = last, first;
	return max(first, start), min(last, end) - 1;
}
_subRangeF :: inline proc(from, to, end: f32, start: f32 = 0) -> (first, last: f32) {
	first = from; 
	last  = to;
	if to < from do first, last = last, first;
	return max(first, start), min(last, end);
}
subRange :: proc{_subRangeF, _subRangeI};