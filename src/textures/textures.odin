package textures

TEXTURE_COUNT :: 8;
TEXTURE_WIDTH :: 64;
TEXTURE_HEIGHT :: 64;
TEXTURE_SIZE :: TEXTURE_WIDTH * TEXTURE_HEIGHT;

Color :: struct #packed {B, G, R: u8}
Texture :: [TEXTURE_SIZE]Color;

all: [TEXTURE_COUNT]^Texture = {
	&texture_1,
	&texture_2,
	&texture_3,
	&texture_4,
	&texture_5,
	&texture_6,
	&texture_7,
	&texture_8
};

sample :: proc(texture_id: u8, u, v: f32) -> Color {
	return all[texture_id]^[TEXTURE_WIDTH * i32(v * f32(TEXTURE_WIDTH)) + i32(u * f32(TEXTURE_WIDTH))];
}