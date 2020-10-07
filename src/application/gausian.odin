package application

GausianFloats :: [9]f32;
gausianKernelColors,
gausianKernelWeights: GausianFloats;
gausianKernelBaseWeights: GausianFloats = {
	0.05, 0.1, 0.05,
	0.1 , 0.4, 0.1,
	0.05, 0.1, 0.05
};

ChannelRow :: []f32;
ChannelGrid :: []ChannelRow;
BitmapChannel :: struct {
	all_pixels: ChannelRow,
	all_rows: []ChannelRow,
	pixels: ChannelGrid
}
BitmapChannels :: struct #raw_union {
	array: [4]BitmapChannel,
	rgba: struct {R, G, B, A: BitmapChannel}
}
FloatBitmap :: struct {
	width, height, size: i32,
	channels: BitmapChannels
}

initFloatBitmap :: proc(using bitmap: ^FloatBitmap, new_width, new_height: i32, bits: []f32) {
	size = new_width * new_height;
	using channels.rgba;
	R.all_pixels = transmute(ChannelRow)(bits[:size]);
	G.all_pixels = transmute(ChannelRow)(bits[size:size*2]);
	B.all_pixels = transmute(ChannelRow)(bits[size*2:size*3]);
	A.all_pixels = transmute(ChannelRow)(bits[size*3:size*4]);
	
	resizeFloatBitmap(bitmap, new_width, new_height);
}
resizeFloatBitmap :: proc(using bitmap: ^FloatBitmap, new_width, new_height: i32) {
	width = new_width;
	height = new_height;
	size = width * height;

	for channel in &channels.array {
		using channel;
		start: i32;
		end := width;

		all_rows = make_slice([]ChannelRow, height);

		for y in 0..<height {
			all_rows[y] = all_pixels[start:end];
			start += width;
			end   += width;
		}

		pixels = all_rows[:height];
	}
}

setFloatBitmap :: proc(using to: ^FloatBitmap, from: ^Bitmap) {
	using channels.rgba;
	for from_pixel, i in &from.all_pixels {
		R.all_pixels[i] = f32(from_pixel.R) / 255;
		G.all_pixels[i] = f32(from_pixel.G) / 255;
		B.all_pixels[i] = f32(from_pixel.B) / 255;
		A.all_pixels[i] = f32(from_pixel.opacity) / 255;
	}
}

sampleBitmapBiLinear :: inline proc(using bitmap: ^FloatBitmap, u, v: f32, pixel: ^Pixel, factor: f32 = 1) {
	U := u * f32(width);
	V := v * f32(height);
	
	x := i32(U);
	y := i32(V);

	gausianKernelWeights[4] = 1; // center
	gausianKernelWeights[5] = U - f32(x); // right
	gausianKernelWeights[7] = V - f32(y); // bottom
	gausianKernelWeights[3] = 1 - gausianKernelWeights[5]; //left
	gausianKernelWeights[1] = 1 - gausianKernelWeights[7]; // top
	gausianKernelWeights[0] = gausianKernelWeights[1] * gausianKernelWeights[3]; // top left
	gausianKernelWeights[2] = gausianKernelWeights[1] * gausianKernelWeights[5]; // top right
	gausianKernelWeights[6] = gausianKernelWeights[7] * gausianKernelWeights[3]; // bottom left
	gausianKernelWeights[8] = gausianKernelWeights[7] * gausianKernelWeights[5]; // bottom right
	gausianKernelWeights *= gausianKernelBaseWeights;

	l := max(x - 1, 0);	
	t := max(y - 1, 0);	
	r := min(x + 1, width-1);
	b := min(y + 1, height-1);

	float_color: [4]f32;

	for channel, i in &channels.array {
		using channel;
		gausianKernelColors[0] = pixels[t][l]; // top left
		gausianKernelColors[1] = pixels[t][x]; // top
		gausianKernelColors[2] = pixels[t][r]; // top right
		gausianKernelColors[3] = pixels[y][l]; // left
		gausianKernelColors[4] = pixels[y][x]; // center
		gausianKernelColors[5] = pixels[y][r]; // right
		gausianKernelColors[6] = pixels[b][l]; // bottom left
		gausianKernelColors[7] = pixels[b][x]; // bottom
		gausianKernelColors[8] = pixels[b][r]; // bottom right
		gausianKernelColors *= gausianKernelWeights;
		float_color[i] = clamp((
			gausianKernelColors[0] + 
			gausianKernelColors[1] + 
			gausianKernelColors[2] + 
			gausianKernelColors[3] + 
			gausianKernelColors[4] + 
			gausianKernelColors[5] + 
			gausianKernelColors[6] + 
			gausianKernelColors[7] + 
			gausianKernelColors[8] 
		) * factor, 0, 1);
	}

	pixel.R = u8(float_color[0] * 255);
	pixel.G = u8(float_color[1] * 255);
	pixel.B = u8(float_color[2] * 255);
	pixel.opacity = u8(float_color[3]);
}
