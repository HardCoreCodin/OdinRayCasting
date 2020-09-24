package application

Size2Df :: struct {width, height: f32}
Size2Di :: struct {width, height: i32}

_inRangeI :: inline proc(start, value, end: i32) -> bool do return value >= start && value <= end;
_inRangeF :: inline proc(start, value, end: f32) -> bool do return value >= start && value <= end;
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

remap :: inline proc(value, src_start, src_end, trg_start, trg_end: f32) -> f32 do
	return (min(max(value, src_start), src_end) / (src_end - src_start)) * (trg_end - trg_start) + trg_start;

Range :: struct {min, max, range: f32}
AmountAndFactor :: struct {
	amount, factor: f32,
	src, trg: Range,
	changed: bool
}

initAmountAndFactor :: inline proc(using aaf: ^AmountAndFactor, trg_min, trg_max: f32, initial_factor: f32 = 1, src_range: f32 = 16.0) {
	src.range = src_range;
	src.max = src.range / 2;
	src.min = -src.max;
	
	trg.min = trg_min;
	trg.max = trg_max;
	trg.range = trg_max - trg_min;

	factor = initial_factor;
	amount = src.max * (((2 * (initial_factor - trg_min)) / trg.range) - 1);
	changed = false;
}

updateAmountAndFactor :: inline proc(using aaf: ^AmountAndFactor) {
	amount = clamp(amount, src.min, src.max);
    factor = ((((amount / src.max) + 1) / 2) * trg.range) + trg.min;
	changed = true;
}