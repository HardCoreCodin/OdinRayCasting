package application

FrameBuffer :: struct {
	using bitmap: Bitmap,
	bits: ^[MAX_BITMAP_SIZE]u32
};

initFrameBuffer :: proc(using fb: ^FrameBuffer) {
	bits = new([MAX_BITMAP_SIZE]u32);
	resizeFrameBuffer(MAX_BITMAP_WIDTH, MAX_BITMAP_HEIGHT, fb);	
}

resizeFrameBuffer :: proc(new_width, new_height: i32, using fb: ^FrameBuffer) {
	initBitmap(&bitmap, new_width, new_height, bits^[:]);
}