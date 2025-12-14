const std = @import("std");
pub const Key = @import("key.zig").Key;
const mapByteToKey = @import("key.zig").mapByteToKey;

pub const Input = struct {
    buf: [1024]u8,
    ttl_list: [@intFromEnum(Key.unknown) + 1]u16,

    pub fn init() Input {
        var input = Input{
            .buf = undefined,
            .ttl_list = undefined,
        };
        @memset(&input.ttl_list, 0xFFFF);
        return input;
    }

    pub fn read(self: *Input, allocator: *std.mem.Allocator) ![]Key {
        const reader = std.io.getStdIn().reader();
        const n = try reader.read(&self.buf);
        if (n == 0) return &[_]Key{};

        var pressed_flags: [@intFromEnum(Key.unknown)]bool = undefined;
        @memset(&pressed_flags, false);

        var i: usize = 0;
        while (i < n) : (i += 1) {
            const b = self.buf[i];

            var k: Key = Key.unknown;

            // ANSIエスケープシーケンス判定
            if (b == 0x1B and i + 2 < n and self.buf[i + 1] == '[') {
                const code = self.buf[i + 2];
                k = switch (code) {
                    'A' => Key.arrow_up,
                    'B' => Key.arrow_down,
                    'C' => Key.arrow_right,
                    'D' => Key.arrow_left,
                    else => Key.unknown,
                };
                i += 2;
            } else {
                k = mapByteToKey(b);
            }

            if (k != Key.unknown) {
                pressed_flags[@intFromEnum(k)] = true;
            }
        }

        // 押された Key の数を数える
        var total: usize = 0;
        for (pressed_flags) |v| {
            if (v) total += 1;
        }

        // 押された Key のみを返す配列を allocator で作成
        var keys = try allocator.alloc(Key, total);
        var idx: usize = 0;
        for (pressed_flags, 0..) |v, j| {
            if (v) {
                keys[idx] = @enumFromInt(j);
                idx += 1;
            }
        }

        return keys;
    }

    pub fn readWithTTL(self: *Input, life: u16, allocator: *std.mem.Allocator) ![]Key {
        const keys = try self.read(allocator);

        for (keys) |key| {
            self.ttl_list[@intFromEnum(key)] = 0;
        }

        var total: usize = 0;
        for (self.ttl_list) |ttl| {
            if (ttl < life) total += 1;
        }

        var result = try allocator.alloc(Key, total);
        var idx: usize = 0;
        for (self.ttl_list, 0..) |ttl, j| {
            if (ttl < life) {
                result[idx] = @enumFromInt(j);
                idx += 1;
            }
        }

        return result;
    }

    pub fn incTTL(self: *Input) void {
        for (0..self.ttl_list.len) |i| {
            if (self.ttl_list[i] != 0xFFFF) {
                self.ttl_list[i] += 1;
            }
        }
    }
};
