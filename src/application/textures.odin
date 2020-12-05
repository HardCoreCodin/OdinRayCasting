package application

Sample :: [4]Pixel;
Samples :: Grid(Sample);

Texture :: struct {
	bitmaps: []^Bitmap
	samples: []^Samples
}
initTexture :: proc(using texture: ^Texture, mip_count: u8) {
	bitmaps = make_slice([]^Bitmap, mip_count);
	samples = make_slice([]^Samples, mip_count);
}

TextureSet :: struct {
	bitmaps: [][]Bitmap,
	samples: [][]Samples,
	textures: []Texture
}
initTextureSet :: proc(using ts: ^TextureSet, count, width, height: i32) {
	mip_count := getMipCount(width);
	textures = make_slice([]Texture, count);
	for texture in &textures do initTexture(&texture, mip_count);

	o, os: i32;
	w := width;
	h := height;
	s := w * h;
	ss := (w + 1) * (h + 1);

	bitmaps = make_slice([][]Bitmap , mip_count);
	samples = make_slice([][]Samples, mip_count);

	for m in 0..<mip_count {
		bitmaps[m] = make_slice([]Bitmap , count);
		samples[m] = make_slice([]Samples, count);

		all_pixels  := make_slice([]Pixel , count * s);
		all_samples := make_slice([]Sample, count * ss);

		o = 0;
		os = 0;

		for t in 0..<count {
			initGrid(&bitmaps[m][t], w, h, all_pixels[ o:o+s]);
			initGrid(&samples[m][t], w+1, h+1, all_samples[os:os+ss]);

			textures[t].bitmaps[m] = &bitmaps[m][t];
			textures[t].samples[m] = &samples[m][t];

			o += s;
			os += ss;
		}

		w >>= 1;
		h >>= 1;
		s = w*h;
		ss = (w + 1) * (h + 1);
	}
}
getMipCount :: proc(width: i32) -> u8 {
	mip_count: u8  = 1;
	mip_width: i32 = 1;

	for mip_width < width {
		mip_width *= 2;
		mip_count += 1;
	}

	return mip_count;
}

generateMipMaps :: proc(mipmaps: ^[]^Bitmap) {
	src := mipmaps[0];
	trg := mipmaps[1];
	pixel, temp: vec4;

	for i in 1..<len(mipmaps) {
		trg = mipmaps[i];
		
		for y in 0..<trg.height do
			for x in 0..<trg.width {
				setPixel(&pixel, &src.cells[2*y    ][2*x    ]);
				setPixel(&temp , &src.cells[2*y    ][2*x + 1]); pixel += temp;
				setPixel(&temp , &src.cells[2*y + 1][2*x    ]); pixel += temp;
				setPixel(&temp , &src.cells[2*y + 1][2*x + 1]); pixel += temp;
				
				pixel /= 4;
				setPixel(&trg.cells[y][x], &pixel);
			}

		src = trg;
	}
}

generateSamplesFromBitmap :: proc(samples: ^Samples, using bitmap: ^Bitmap, smear_edges: bool = true, wrap_edges: bool = false) {
	T, L: u32;
	B := u32(height - 1);
	R := u32(width  - 1);

	for y in T..<B do
		for x in L..<R do
			samples.cells[y+1][x+1] = {
				cells[y+0][x+0], cells[y+0][x+1],
				cells[y+1][x+0], cells[y+1][x+1]
			};

	sample: Sample;
	TL := cells[T][L];  TR := cells[T][R];
	BL := cells[B][L];  BR := cells[B][R];

	if wrap_edges {
		// Set corner sample (same for all 4 corners):
		sample = {
			BR, BL,
			TL, TR
		};
		
		samples.cells[T  ][L] = sample;  samples.cells[T  ][R+1] = sample;	
		samples.cells[B+1][L] = sample;  samples.cells[B+1][R+1] = sample;
		
		// Set first and last row (they are the same):
		for x in L..<R { // Note: Corners excluded as they were alreay set above 
			sample = {
				cells[B][x], cells[B][x+1],
				cells[T][x], cells[T][x+1]
			};

			samples.cells[T  ][x+1] = sample;
			samples.cells[B+1][x+1] = sample;
		}

		// Set first and last column (they are the same):
		for y in T..<B { // Note: Corners excluded as they were alreay set above 
			sample = {
				cells[y  ][R], cells[y  ][L],
				cells[y+1][R], cells[y+1][L]
			};

			samples.cells[y+1][L  ] = sample;
			samples.cells[y+1][R+1] = sample;
		}
	} else if smear_edges {
		// Set corner samples:
		// Note: They're all uniform blocks so they can get broadcasted into:
		samples.cells[T  ][L] = TL;  samples.cells[T  ][R+1] = TR;	
		samples.cells[B+1][L] = BL;  samples.cells[B+1][R+1] = BR;
		
		// Set first and last row:
		for x in L..<R { // Note: Corners excluded as they were alreay set above 
			TL = cells[T][x];  TR = cells[T][x+1];
			BL = cells[B][x];  BR = cells[B][x+1];
			
			samples.cells[T  ][x+1] = {
				TL, TR,
				TL, TR
			};
			samples.cells[B+1][x+1] = {
				BL, BR,
				BL, BR
			};
		}

		// Set first and last column:
		for y in T..<B { // Note: Corners excluded as they were alreay set above 
			TL = cells[y  ][L];  TR = cells[y  ][R];
			BL = cells[y+1][L];  BR = cells[y+1][R];

			samples.cells[y+1][L  ] = {
				TL, TL,
				BL, BL
			};
			samples.cells[y+1][R+1] = {
				TR, TR,
				BR, BR
			};
		}
	} else { // Set out-of-bound texel samples to trasnsparent black
		__ := cells[0][0];
		__.r = 0;
		__.g = 0;
		__.b = 0;
		__.a = 0;
		
		// Set corner samples:
		samples.cells[T][L] = {
			__, __,
			__, TL,
		};  
		samples.cells[T][R+1] = {
			__, __,
			TR, __,
		};
		
		samples.cells[B+1][L] = {
			__, BL,
			__, __,
		};  
		samples.cells[B+1][R+1] = {
			BR, __,
			__, __,
		};
		
		// Set first and last row:
		for x in L..<R { // Note: Corners excluded as they were alreay set above 
			TL = cells[T][x];  TR = cells[T][x+1];
			BL = cells[B][x];  BR = cells[B][x+1];

			samples.cells[T][x+1] = {
				__, __,
				TL, TR,
			};
			samples.cells[B+1][x+1] = {
				BL, BR,	
				__, __,
			};
		}

		// Set first and last column (they are the same):
		for y in T..<B { // Note: Corners excluded as they were alreay set above 
			TL = cells[y  ][L];  TR = cells[y  ][R];
			BL = cells[y+1][L];  BR = cells[y+1][R];

			samples.cells[y+1][L  ] = {
				__, TL,
				__, BL
			};
			samples.cells[y+1][R+1] = {
				TR, __,
				BR, __
			};
		}	
	}
}

generateTextureSamples :: proc(using texture: ^Texture, smear_edges: bool = true, wrap_edges: bool = false) do
	for bitmap, mip in &bitmaps do 
		generateSamplesFromBitmap(samples[mip], bitmap, smear_edges, wrap_edges);

sample :: inline proc(using samples: ^Samples, u, v: f32, out: ^$Out) {
	U := u * f32(width - 1) + 0.5; x := i32(U);
	V := v * f32(height - 1) + 0.5; y := i32(V);
	r := U - f32(x); l := 1 - r;
	b := V - f32(y); t := 1 - b;
	tl:= t * l; tr := t*r;
	bl:= b * l; br := b*r;

	samples := &cells[y][x];
	TL, TR, BL, BR: vec4;
	setPixel(&TL, &samples[0]);
	setPixel(&TR, &samples[1]);
	setPixel(&BL, &samples[2]);
	setPixel(&BR, &samples[3]);

	result := TL*tl + TR*tr + BL*bl + BR*br;
	setPixel(out, &result);
}

sampleTexture :: inline proc(texture: ^Texture, mip_level: u8, u, v: f32, out: ^$Out) do _sample(texture.samples[mip_level], u, v, out);

scaleTexture :: proc(from: ^Samples, to: ^$S/Grid) {
	for y in 0..<to.height do
		for x in 0..<to.width do
			sample(from, f32(x)/f32(to.width), f32(y)/f32(to.height), &to.cells[y][x]);
}

loadTexture :: proc(using texture: ^Texture, file: ^[]u8, smear_edges: bool = false, wrap_edges: bool = true) {
	readBitmapFromFile(bitmaps[0], file);
	generateMipMaps(&bitmaps);
	generateTextureSamples(texture, smear_edges, wrap_edges);
}

loadTextureSet :: proc(using texture_set: ^TextureSet, file_buffers: ^[][]u8, width, height: i32, smear_edges: bool = false, wrap_edges: bool = true) {
	if len(samples) == 0                 do initTextureSet(texture_set, i32(len(file_buffers)), width, height);
	for texture, texture_id in &textures do loadTexture(&texture, &file_buffers[texture_id], smear_edges, wrap_edges);
}