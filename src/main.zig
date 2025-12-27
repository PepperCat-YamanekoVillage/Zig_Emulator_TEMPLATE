const std = @import("std");
const gui = @import("gui");
const key = @import("key");
const audio = @import("audio");

const sample_rate: f32 = 44100.0;
const frequency: f32 = 440.0;
const amplitude: f32 = 0.2 * 32767.0;
const phase_step: f32 =
    2.0 * std.math.pi * frequency / sample_rate;

pub fn main() !void {
    var my_gui = try gui.Gui.init(64, 32);
    defer my_gui.deinit();

    var input = key.Input.init();
    var allocator = std.heap.page_allocator;

    var my_audio = audio.Audio.init();

    var x: u8 = 32;
    var y: u8 = 16;

    var phase: f32 = 0.0;

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
                },
                key.Key.arrow_down => {
                    y += 1;
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

        for (0..audio.BUFFER_LENGTH) |i| {
            const sample = std.math.sin(phase);
            my_audio.buffer[i] = @intFromFloat(sample * amplitude);
            phase += phase_step;
            if (phase >= 2.0 * std.math.pi) {
                phase -= 2.0 * std.math.pi;
            }
        }

        try my_gui.update();
        try my_audio.update(audio.BUFFER_LENGTH);
        input.incTTL();
        std.time.sleep(16_00_000); // 60Hz
    }
}
