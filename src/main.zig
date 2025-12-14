const std = @import("std");
const gui = @import("gui");
const key = @import("key");
const audio = @import("audio");

pub fn main() !void {
    var my_gui = try gui.Gui.init(64, 32);
    defer my_gui.deinit();

    var input = key.Input.init();
    var allocator = std.heap.page_allocator;

    var my_audio = try audio.Audio.init(std.heap.page_allocator, 1);
    defer my_audio.deinit();

    var x: u8 = 32;
    var y: u8 = 16;

    while (true) {
        my_gui.drawPoint(
            x,
            y,
            0,
            0,
            0,
        );

        const keys = try input.readWithTTL(1, &allocator);
        defer allocator.free(keys);

        for (keys) |item| {
            std.debug.print("{}", .{item});
            switch (item) {
                key.Key.arrow_up => {
                    y -= 1;
                    my_audio.setSignWave(0, 440.0 * @as(f32, @floatFromInt(32 - y)) / 16.0, null, null, null);
                },
                key.Key.arrow_down => {
                    y += 1;
                    my_audio.setSignWave(0, 440.0 * @as(f32, @floatFromInt(32 - y)) / 16.0, null, null, null);
                },
                key.Key.arrow_right => {
                    x += 1;
                },
                key.Key.arrow_left => {
                    x -= 1;
                },
                else => {},
            }
        }

        my_gui.drawPoint(
            x,
            y,
            255,
            255,
            255,
        );

        try my_gui.update();
        try my_audio.update();
        input.incTTL();
        std.time.sleep(16_00_000); // 60Hz
    }
}
