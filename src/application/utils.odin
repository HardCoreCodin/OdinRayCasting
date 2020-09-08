package application

Size2Df :: struct {width, height: f32}
Size2Di :: struct {width, height: i32}

inRange :: inline proc(value, end: i32, start: i32 = 0) -> bool do return value >= start && value < end;
subRange :: inline proc(from, to, end: i32, start: i32 = 0) -> (first, last: i32) {
	first = from; 
	last  = to;
	if to < from do first, last = last, first;
	return max(first, start), min(last, end) - 1;
}