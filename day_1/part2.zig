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

    std.debug.print("Part 2  answer : {d}\n", .{num_zeros});
}

fn countZeros(rotations: []const u8) !i32 {
    var dial: i32 = 50;

    var num_zeros: i32 = 0;

    var lines = std.mem.splitScalar(u8, rotations, '\n');

    while (lines.next()) |line|{
        if (line.len == 0) {
            continue;
        }

        const distance = try std.fmt.parseInt(i32, line[1..], 10);

        const laps = @divTrunc(distance, 100);
        const adj_distance = @mod(distance, 100);

        num_zeros += laps;

        const direction = line[0];

        switch (direction) {
            'L' => {
                if (adj_distance > dial and dial != 0) {
                    // has to cross once
                    num_zeros += 1;
                }

                const rem = @rem(dial - adj_distance, 100);

                if (rem < 0) {
                    dial = 100 + rem;
                } else {
                    dial = rem;
                }
            },
            'R' => {
                if (adj_distance > (100 - dial) and dial != 0) {
                    // has to cross once
                    num_zeros += 1;
                }
                const rem = @rem(dial + adj_distance, 100);

                if (rem > 99) {
                    dial = 0 + rem;
                } else {
                    dial = rem;
                }
            },
            else => unreachable,
        }

        if (dial == 0) {
            num_zeros += 1;
        }

        std.debug.print("{c}, {d} {d} - {d} -- {d} --- {d}\n", .{
            direction,
            distance,
            adj_distance,
            dial,
            laps,
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

    try std.testing.expectEqual(6, num_zeros);
}
