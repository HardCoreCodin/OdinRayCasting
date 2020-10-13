package application

fillTriangle :: proc(using bitmap: ^$T/Grid, X, Y: [3]f32, pixel: ^$PixelType) {
    dx1, x1, y1, xs,
    dx2, x2, y2, xe,
    dx3, x3, y3, dy: f32;
    offset,
	x, x1i, y1i, x2i, xsi, ysi,
    y, y2i, x3i, y3i, xei, yei, i: i32;
    for i in 1..3 {
        if Y[i] < Y[ysi] do ysi = i32(i);
        if Y[i] > Y[yei] do yei = i32(i);
    }

    id: [3]u8 = (ysi == 0) ? {0, 1, 2}: (
    		    (ysi == 1) ? {1, 2, 0}: 
    		               {2, 0, 1}  );

    x1 = X[id[0]]; y1 = Y[id[0]]; x1i = i32(x1); y1i = i32(y1);
    x2 = X[id[1]]; y2 = Y[id[1]]; x2i = i32(x2); y2i = i32(y2);
    x3 = X[id[2]]; y3 = Y[id[2]]; x3i = i32(x3); y3i = i32(y3);
    dx1 = x1i == x2i || y1i == y2i ? 0 : (x2 - x1) / (y2 - y1);
    dx2 = x2i == x3i || y2i == y3i ? 0 : (x3 - x2) / (y3 - y2);
    dx3 = x1i == x3i || y1i == y3i ? 0 : (x3 - x1) / (y3 - y1);
    dy = 1 - (y1 - f32(y1));
    xs = (dx3 != 0) ? x1 + dx3 * dy : x1; ysi = i32(Y[ysi]);
    xe = (dx1 != 0) ? x1 + dx1 * dy : x1; yei = i32(Y[yei]);
    offset = width * y1i;
    for y in ysi..<yei {
        if y == y3i do xs = (dx2 != 0) ? (x3 + dx2 * (1 - (y3 - f32(y3i)))) : x3;
        if y == y2i do xe = (dx2 != 0) ? (x2 + dx2 * (1 - (y2 - f32(y2i)))) : x2;
        xsi = i32(xs);
        xei = i32(xe);
        for x in xsi..<xei do setPixel(&_cells[offset + x], pixel);
        offset += width;
        xs += y < y3i ? dx3 : dx2;
        xe += y < y2i ? dx1 : dx2;
    }
}