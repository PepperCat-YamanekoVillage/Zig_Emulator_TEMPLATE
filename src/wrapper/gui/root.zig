const std = @import("std");

pub const Gui = struct {
    width: u32,
    height: u32,
    pixels: []u8,
    allocator: std.mem.Allocator,

    pub fn init(width: u32, height: u32) !Gui {
        const allocator = std.heap.page_allocator;
        const row_stride = (width * 3 + 3) & ~@as(u32, 3);
        const data_size = row_stride * height;
        const pixels = try allocator.alloc(u8, data_size);
        @memset(pixels, 0); // Black background

        return Gui{
            .width = width,
            .height = height,
            .pixels = pixels,
            .allocator = allocator,
        };
    }

    pub fn drawPoint(self: *Gui, x: u32, y: u32, r: u8, g: u8, b: u8) void {
        if (x >= self.width or y >= self.height) return;

        const row_stride = (self.width * 3 + 3) & ~@as(u32, 3);
        const offset = y * row_stride + x * 3;

        self.pixels[offset] = r;
        self.pixels[offset + 1] = g;
        self.pixels[offset + 2] = b;
    }

    pub fn update(self: *Gui) !void {
        const file = try std.fs.cwd().createFile(".screen", .{ .truncate = true });
        defer file.close();

        try file.writeAll(self.pixels);
    }

    pub fn deinit(self: *Gui) void {
        self.allocator.free(self.pixels);
    }
};
