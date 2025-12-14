const std = @import("std");
const wave = @import("wave.zig");

pub const Audio = struct {
    channels: []?wave.Wave,
    channels_hasChanged: []bool,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, channel_count: usize) !Audio {
        const buf1 = try allocator.alloc(?wave.Wave, channel_count);
        const buf2 = try allocator.alloc(bool, channel_count);

        // 初期化
        for (buf1) |*ch| {
            ch.* = undefined;
        }
        for (buf2) |*ch| {
            ch.* = true;
        }

        return .{
            .channels = buf1,
            .channels_hasChanged = buf2,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Audio) void {
        self.allocator.free(self.channels);
        self.allocator.free(self.channels_hasChanged);
        self.channels = &.{};
    }

    pub fn tick(self: *Audio) void {
        for (self.channels) |*ch| {
            switch (ch.*) {
                .sign => |*s| s.age += 1,
                .pulse => |*p| p.age += 1,
                .triangle => |*t| t.age += 1,
                .noise => |*n| n.age += 1,
                .memory => |*m| m.age += 1,
                .dpcm => |*d| d.age += 1,
            }
        }
    }

    pub fn update(self: *Audio) !void {
        for (self.channels, 0..) |ch, i| {
            if (!self.channels_hasChanged[i]) continue;
            self.channels_hasChanged[i] = false;

            var filename_buf: [64]u8 = undefined;
            const filename = try std.fmt.bufPrint(
                &filename_buf,
                ".channel/{d}",
                .{i},
            );

            // ファイルの削除
            if (ch == null) {
                std.fs.cwd().deleteFile(filename) catch |err| switch (err) {
                    error.FileNotFound => {},
                    else => return err,
                };
                return;
            }

            // 波形 → バイト列
            const bytes = try ch.?.toBytes(self.allocator);
            defer self.allocator.free(bytes);

            // ファイルへ保存
            var file = try std.fs.cwd().createFile(filename, .{});
            defer file.close();

            try file.writeAll(bytes);
        }
    }

    pub fn setSignWave(
        self: *Audio,
        channel: usize,
        freq: f32,
        life: ?u32,
        volume: ?u8,
        envelope: ?u8,
    ) void {
        self.channels_hasChanged[channel] = true;
        self.channels[channel] = .{
            .sign = .{
                .age = 0,
                .life = life orelse 0,
                .volume = volume orelse 100,
                .envelope = envelope orelse 0,
                .freq = freq,
            },
        };
    }

    pub fn removeWave(
        self: *Audio,
        channel: usize,
    ) void {
        self.channels_hasChanged[channel] = true;
        self.channels[channel] = null;
    }

    pub fn isChannelUnused(
        self: *Audio,
        channel: usize,
    ) bool {
        return (self.channels[channel] == null);
    }
};
