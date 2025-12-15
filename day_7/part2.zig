const std = @import("std");

pub fn main() !void {
    var timer = try std.time.Timer.start(); // Get the current instant

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() != .ok) std.debug.print("leak detected\n", .{});
    }

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const allocator = arena.allocator();

    const input = try readFile(allocator, "./input.txt");

    const result = try puzzle(allocator, input);

    std.debug.print("Part 2 answer : {d}\n", .{result});
    // 3084 too low
    // 10000 too low
    // 3223365367809
    std.debug.print("Elapsed time: {d} ms\n", .{timer.read() / 1000 / 1000});
}

fn puzzle(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const trimmed = std.mem.trimEnd(u8, input, "\r\n");
    var splitLines = std.mem.splitScalar(u8, trimmed, '\n');

    // keep each line as an array of chars
    var lines = std.ArrayList([]u8).empty;
    while (splitLines.next()) |line| {
        if (line.len == 0) continue;

        const mutArray = try allocator.dupe(u8, line);
        try lines.append(allocator, mutArray);
    }
    const grid = try lines.toOwnedSlice(allocator);

    const gridLength = grid.len;

    // var numTimelines: u64 = 0;

    var prevRowCounts = try allocator.alloc(u64, grid[0].len);
    @memset(prevRowCounts, 0);

    for (1..gridLength) |r| {
        for (grid[r], 0..) |char, col| {
            if (char == '^' and grid[r - 1][col] == '|') {
                // this is a split
                grid[r][col - 1] = '|';
                grid[r][col + 1] = '|';

                // count the num of beams in each course
                prevRowCounts[col - 1] += prevRowCounts[col];
                prevRowCounts[col + 1] += prevRowCounts[col];

                // this col dies here then
                prevRowCounts[col] = 0;
            } else if (grid[r - 1][col] == 'S') {
                prevRowCounts[col] += 1;
                grid[r][col] = '|';
            } else if (grid[r - 1][col] == '|') {
                grid[r][col] = '|';
            }
        }
        // std.debug.print("line: {s} __{d}^ __{d} timelines\n", .{ grid[r], numCarr, numTimelines });
        std.debug.print("line: {s} -- {d}\n", .{ grid[r], r });
        std.debug.print("counts: {any}\n", .{prevRowCounts});
    }
    // 2, 4, 8, 12, 17, 20, 25
    // total :  1, 2, 4, 8, 13

    var sum: u64 = 0;
    for (prevRowCounts) |item| {
        sum += item;
    }
    return sum;
}

fn dupeGrid(
    allocator: std.mem.Allocator,
    grid: [][]u8,
) ![][]u8 {
    var copy = try allocator.alloc([]u8, grid.len);

    for (grid, 0..) |row, i| {
        copy[i] = try allocator.dupe(u8, row);
    }

    return copy;
}

fn readFile(allocator: std.mem.Allocator, filename: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(
        filename,
        std.fs.File.OpenFlags{ .mode = .read_only },
    );
    defer file.close();

    const stat = try file.stat();
    return try file.readToEndAlloc(allocator, stat.size);
}

test "test input" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const input =
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
    ;

    const result = try puzzle(allocator, input);

    try std.testing.expectEqual(40, result);
}
