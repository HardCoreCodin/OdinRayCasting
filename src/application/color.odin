package application

Color :: struct #packed {B, G, R: u8}

BLACK: Color;
GREY: Color = {
	R = 0x88,
	G = 0x88,
	B = 0x88
};
WHITE: Color = {
	R = 0xFF,
	G = 0xFF,
	B = 0xFF
};
RED: Color = {R = 0xFF};
GREEN: Color = {G = 0xFF};
BLUE: Color = {B = 0xFF};
YELLOW: Color = {R = 0xFF, G = 0xFF};

RED_PIXEL: Pixel = {color = RED, opacity=255};
BLUE_PIXEL: Pixel = {color = BLUE, opacity=255};
GREEN_PIXEL: Pixel = {color = GREEN, opacity=255};
YELLOW_PIXEL: Pixel = {color = YELLOW, opacity=255};
