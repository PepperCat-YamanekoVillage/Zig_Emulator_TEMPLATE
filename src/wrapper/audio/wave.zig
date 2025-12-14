const std = @import("std");

pub const WaveType = enum {
    sign, // 正弦波
    pulse, // パルス波(短形波)
    triangle, // 三角波
    noise, // ノイズ
    memory, // 波形メモリ
    dpcm, // DPCM
};

pub const Wave = union(WaveType) {
    sign: Sign,
    pulse: Pulse,
    triangle: Triangle,
    noise: Noise,
    memory: Memory,
    dpcm: Dpcm,

    pub fn toBytes(self: *const Wave, allocator: std.mem.Allocator) ![]u8 {
        return switch (self.*) {
            .sign => |v| v.toBytes(allocator),
            .pulse => |v| v.toBytes(allocator),
            .triangle => |v| v.toBytes(allocator),
            .noise => |v| v.toBytes(allocator),
            .memory => |v| v.toBytes(allocator),
            .dpcm => |v| v.toBytes(allocator),
        };
    }
};

// 正弦波
pub const Sign = struct {
    age: u32,
    life: u32,
    volume: u8,
    envelope: u8,
    freq: f32,

    pub fn toBytes(self: *const Sign, allocator: std.mem.Allocator) ![]u8 {
        const size = 1 + 4 + 4 + 1 + 1 + 4;
        var buf = try allocator.alloc(u8, size);
        var i: usize = 1;

        buf[0] = @intFromEnum(WaveType.sign);

        // u32
        std.mem.writeInt(u32, buf[i..][0..4], self.age, .little);
        i += 4;
        std.mem.writeInt(u32, buf[i..][0..4], self.life, .little);
        i += 4;

        // u8
        buf[i] = self.volume;
        i += 1;
        buf[i] = self.envelope;
        i += 1;

        // f32 → u32
        std.mem.writeInt(u32, buf[i..][0..4], @bitCast(self.freq), .little);

        return buf;
    }
};

// パルス波
pub const Pulse = struct {
    age: u32,
    life: u32,
    volume: u8,
    envelope: u8,
    duty: f32,
    sweep: f32,

    pub fn toBytes(self: *const Pulse, allocator: std.mem.Allocator) ![]u8 {
        const size = 1 + 4 + 4 + 1 + 1 + 4 + 4;
        var buf = try allocator.alloc(u8, size);
        var i: usize = 1;

        buf[0] = @intFromEnum(WaveType.sign);

        std.mem.writeInt(u32, buf[i..][0..4], self.age, .little);
        i += 4;
        std.mem.writeInt(u32, buf[i..][0..4], self.life, .little);
        i += 4;

        buf[i] = self.volume;
        i += 1;
        buf[i] = self.envelope;
        i += 1;

        std.mem.writeInt(u32, buf[i..][0..4], @bitCast(self.duty), .little);
        i += 4;
        std.mem.writeInt(u32, buf[i..][0..4], @bitCast(self.sweep), .little);

        return buf;
    }
};

// 三角波
pub const Triangle = struct {
    age: u32,
    life: u32,
    volume: u8,
    envelope: u8,
    freq: f32,

    pub fn toBytes(self: *const Triangle, allocator: std.mem.Allocator) ![]u8 {
        const size = 1 + 4 + 4 + 1 + 1 + 4;
        var buf = try allocator.alloc(u8, size);
        var i: usize = 1;

        buf[0] = @intFromEnum(WaveType.sign);

        std.mem.writeInt(u32, buf[i..][0..4], self.age, .little);
        i += 4;
        std.mem.writeInt(u32, buf[i..][0..4], self.life, .little);
        i += 4;

        buf[i] = self.volume;
        i += 1;
        buf[i] = self.envelope;
        i += 1;

        std.mem.writeInt(u32, buf[i..][0..4], @bitCast(self.freq), .little);

        return buf;
    }
};

// ノイズ
pub const Noise = struct {
    age: u32,
    life: u32,
    volume: u8,
    envelope: u8,
    short_mode: bool, // short/long → true = short, false = long

    pub fn toBytes(self: *const Noise, allocator: std.mem.Allocator) ![]u8 {
        const size = 1 + 4 + 4 + 1 + 1 + 1;
        var buf = try allocator.alloc(u8, size);
        var i: usize = 1;

        buf[0] = @intFromEnum(WaveType.sign);

        std.mem.writeInt(u32, buf[i..][0..4], self.age, .little);
        i += 4;
        std.mem.writeInt(u32, buf[i..][0..4], self.life, .little);
        i += 4;

        buf[i] = self.volume;
        i += 1;
        buf[i] = self.envelope;
        i += 1;

        buf[i] = @intFromBool(self.short_mode);

        return buf;
    }
};

// 波形メモリ
pub const Memory = struct {
    age: u32,
    life: u32,
    volume: u8,
    envelope: u8,
    data: []const u8,

    pub fn toBytes(self: *const Memory, allocator: std.mem.Allocator) ![]u8 {
        const size = 1 + 4 + 4 + 1 + 1 + 4 + self.data.len;
        var buf = try allocator.alloc(u8, size);
        var i: usize = 1;

        buf[0] = @intFromEnum(WaveType.sign);

        std.mem.writeInt(u32, buf[i..][0..4], self.age, .little);
        i += 4;
        std.mem.writeInt(u32, buf[i..][0..4], self.life, .little);
        i += 4;

        buf[i] = self.volume;
        i += 1;
        buf[i] = self.envelope;
        i += 1;

        std.mem.writeInt(u32, buf[i..][0..4], @as(u32, @intCast(self.data.len)), .little);
        i += 4;

        std.mem.copyForwards(u8, buf[i..][0..self.data.len], self.data);

        return buf;
    }
};

// DPCM
pub const Dpcm = struct {
    age: u32,
    life: u32,
    volume: u8,
    envelope: u8,
    data: []const u8,
    freq: f32,

    pub fn toBytes(self: *const Dpcm, allocator: std.mem.Allocator) ![]u8 {
        const size = 1 + 4 + 4 + 1 + 1 + 4 + self.data.len + 4;
        var buf = try allocator.alloc(u8, size);
        var i: usize = 1;

        buf[0] = @intFromEnum(WaveType.sign);

        std.mem.writeInt(u32, buf[i..][0..4], self.age, .little);
        i += 4;
        std.mem.writeInt(u32, buf[i..][0..4], self.life, .little);
        i += 4;

        buf[i] = self.volume;
        i += 1;
        buf[i] = self.envelope;
        i += 1;

        std.mem.writeInt(u32, buf[i..][0..4], @as(u32, @intCast(self.data.len)), .little);
        i += 4;

        std.mem.copyForwards(u8, buf[i..][0..self.data.len], self.data);
        i += self.data.len;

        std.mem.writeInt(u32, buf[i..][0..4], @bitCast(self.freq), .little);

        return buf;
    }
};
