const std = @import("std");

const Direction = enum { left, right };

pub fn main() !void {
    const file = try std.fs.cwd().openFile("./input.txt", std.fs.File.OpenFlags{ .mode = .read_only });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const result = gpa.deinit();
        if (result == .leak) std.debug.print("leak detected\n", .{});
    }

    const stat = try file.stat();
    const contents = try file.readToEndAlloc(allocator, stat.size);
    defer allocator.free(contents);

    const num_zeros = try countZeros(contents);

    std.debug.print("Part 1  answer : {d}\n", .{num_zeros});
}

fn countZeros(rotations: []const u8) !u16 {
    var dial: i16 = 50;

    var num_zeros: u16 = 0;

    var lines = std.mem.splitScalar(u8, rotations, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        const distance = try std.fmt.parseInt(i16, line[1..], 10);

        const direction = line[0];

        switch (direction) {
            'L' => {
                const rem = @rem(dial - distance, 100);

                if (rem < 0) {
                    dial = 100 + rem;
                } else {
                    dial = rem;
                }
            },
            'R' => dial = @rem(dial + distance, 100),
            else => unreachable,
        }

        if (dial == 0) {
            num_zeros += 1;
        }

        std.debug.print("{c}, {d} - {d} -- {d}\n", .{
            direction,
            distance,
            dial,
            num_zeros,
        });
    }

    return num_zeros;
}

test "test input" {
    const rotations =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;

    const num_zeros = try countZeros(rotations);

    try std.testing.expectEqual(num_zeros, 3);
}
