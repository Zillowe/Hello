const std = @import("std");

pub fn main() !void {
    const stdout_writer = std.io.getStdOut().writer();
    try stdout_writer.print("Hello, World!\n", .{});
}
