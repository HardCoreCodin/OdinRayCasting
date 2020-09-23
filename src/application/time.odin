package application

GetTicks :: proc() -> u64;
getTicks: GetTicks;

ticks_per_second,
ticks_of_last_report: u64;

seconds_per_tick,
milliseconds_per_tick,
microseconds_per_tick: f64;

Timer :: struct {
	delta_time: f32,

	ticks_before, 
	ticks_after, 
	ticks_diff,
	accumulated_ticks,
	accumulated_frame_count,
	ticks_of_last_report,
	seconds,
	milliseconds,
	microseconds: u64
}
render_timer,
update_timer: Timer;

accumulateTimer :: proc(using time: ^Timer) {
	ticks_diff = ticks_after - ticks_before;
	accumulated_ticks += ticks_diff;

	seconds      = u64(seconds_per_tick      * f64(ticks_diff));
	milliseconds = u64(milliseconds_per_tick * f64(ticks_diff));
	microseconds = u64(microseconds_per_tick * f64(ticks_diff));

	accumulated_frame_count += 1;
}

initTimers :: proc(platformGetTicks: GetTicks, platformTicksPerSecond: u64) {
	getTicks = platformGetTicks;
	ticks_per_second = platformTicksPerSecond;

	seconds_per_tick      = 1         / f64(ticks_per_second);
	milliseconds_per_tick = 1_000     / f64(ticks_per_second);
	microseconds_per_tick = 1_000_000 / f64(ticks_per_second);

	ticks_of_last_report = getTicks();
	update_timer.ticks_before = getTicks();
}