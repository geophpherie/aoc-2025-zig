const std = @import("std");

pub fn main() void {
    const idx = std.mem.indexOfScalar(u8, "12345678", '9');
    if (idx) |i| {
        std.debug.print("Index: {}\n", .{i});
    } else {
        std.debug.print("Index: nah\n", .{});
    }

}
