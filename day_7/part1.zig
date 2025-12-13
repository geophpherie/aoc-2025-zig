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

    std.debug.print("Part 1 answer : {d}\n", .{result});
    std.debug.print("Elapsed time: {d} ms\n", .{timer.read() / 1000 / 1000});
}

fn puzzle(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const trimmed = std.mem.trimEnd(u8, input, "\r\n");
    var splitLines = std.mem.splitScalar(u8, trimmed, '\n');

    // keep each line as list of strings
    var lines = std.ArrayList([]const u8){};

    while (splitLines.next()) |line| {
        if (line.len == 0) continue;

        try lines.append(allocator, line);
    }

    std.debug.print("signs: {any}\n", .{signs.items});


    const numSplits : u64 = 0;
    return numSplits;
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
    const allocator = std.testing.allocator;

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

    try std.testing.expectEqual(21, result);
}
