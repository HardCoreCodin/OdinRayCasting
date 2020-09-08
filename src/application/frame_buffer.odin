package application

MAX_WIDTH  :: 3840;
MAX_HEIGHT :: 2160;
MAX_SIZE   :: MAX_WIDTH * MAX_HEIGHT;

FrameBuffer :: struct {
	using bitmap: Bitmap,
	bits: ^[MAX_SIZE]u32
};

initFrameBuffer :: proc(using fb: ^FrameBuffer) {
	bits = new([MAX_SIZE]u32);
	resizeFrameBuffer(MAX_WIDTH, MAX_HEIGHT, fb);	
}

resizeFrameBuffer :: proc(new_width, new_height: i32, using fb: ^FrameBuffer) {
	initBitmap(&bitmap, new_width, new_height, bits^[:]);
}