const std = @import("std");

const FD = 3;
pub const BUFFER_LENGTH = 2048;

pub const Audio = struct {
    buffer: [BUFFER_LENGTH]i16,
    write_head: usize,
    out_head: usize,

    pub fn init() Audio {
        return .{
            .buffer = [_]i16{0} ** BUFFER_LENGTH,
            .write_head = 0,
            .out_head = 0,
        };
    }

    /// 256 * N を入れること！
    pub fn update(self: *Audio, size: usize) !void {
        const audio = std.fs.File{ .handle = FD };
        const out = audio.writer();
        const first = @min(size, BUFFER_LENGTH - self.out_head);

        try out.writeAll(std.mem.sliceAsBytes(self.buffer[self.out_head .. self.out_head + first]));

        const rest = size - first;
        if (rest > 0) {
            try out.writeAll(std.mem.sliceAsBytes(self.buffer[0..rest]));
        }

        self.out_head = (self.out_head + size) % BUFFER_LENGTH;
    }
};
