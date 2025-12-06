const std = @import("std");
const file_io = @import("./file_io.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const result = gpa.deinit();
        if (result == .leak) std.debug.print("leak detected\n", .{});
    }

    const contents = try file_io.readFile(allocator, "./input.txt");
    defer allocator.free(contents);

    const result = try puzzle(contents);
    std.debug.print("Part 2 answer : {d}\n", .{result});
}

fn puzzle(input: []const u8) !u64 {
    const trimmed = std.mem.trimEnd(u8, input, "\r\n");

    var lines = std.mem.splitScalar(u8, trimmed, '\n');

    const num_digits = 12;

    var joltage: u64 = 0;

    while (lines.next()) |line| {
        std.debug.print("LINE: {s} {d}\n", .{ line, line.len });

        var str_num: [num_digits]u8 = .{0} ** num_digits;
        var str_ind: [num_digits]usize = .{0} ** num_digits;

        for (0..num_digits) |digit| {
            for ("987654321") |c| {
                // check in decreasing order
                var start_ind: usize = undefined;
                if (digit == 0) {
                    start_ind = 0;
                } else {
                    start_ind = str_ind[digit - 1] + 1;
                }

                const end_ind = line.len - (num_digits - digit) + 1;
                std.debug.print("Checking for {c} in {s} for digit {d} between {d} and {d}\n", .{ c, line, digit, start_ind, end_ind });
                const idx = std.mem.indexOfScalarPos(
                    u8,
                    line[0..end_ind],
                    start_ind,
                    c,
                );
                if (idx) |i| {
                    std.debug.print("Found index: {}\n", .{i});
                    str_num[digit] = c;
                    str_ind[digit] = i;
                    break;
                }
            }
        }
        std.debug.print("{s}\n", .{str_num});

        const new_joltage = try std.fmt.parseInt(u64, &str_num, 10);

        joltage += new_joltage;

        std.debug.print("new joltage {d}\n", .{new_joltage});
    }

    return joltage;
}

test "test input" {
    const input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;

    const result = try puzzle(input);

    try std.testing.expectEqual(3121910778619, result);
}
