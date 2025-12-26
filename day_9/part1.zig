const std = @import("std");

const PRINT = true;

fn print(comptime fmt: []const u8, args: anytype) void {
    if (PRINT) std.debug.print(fmt, args);
}

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

fn readFile(allocator: std.mem.Allocator, filename: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(
        filename,
        std.fs.File.OpenFlags{ .mode = .read_only },
    );
    defer file.close();

    const stat = try file.stat();
    return try file.readToEndAlloc(allocator, stat.size);
}

const Coordinate = struct {
    x: i64,
    y: i64,
};

fn puzzle(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const trimmed = std.mem.trimEnd(u8, input, "\r\n");
    var split_lines = std.mem.splitScalar(u8, trimmed, '\n');
    //
    // keep each line as an array of chars
    var coordinates = std.ArrayList(Coordinate){};

    var index: usize = 0;

    while (split_lines.next()) |line| {
        if (line.len == 0) continue;

        var coords = std.mem.splitScalar(u8, line, ',');

        const coordinate = Coordinate{
            .x = try std.fmt.parseInt(i64, coords.next().?, 10),
            .y = try std.fmt.parseInt(i64, coords.next().?, 10),
        };

        try coordinates.append(allocator, coordinate);

        index += 1;
    }
    const coords = try coordinates.toOwnedSlice(allocator);

    // var  = std.ArrayList(Pair){};
    var maxArea : u64 = 0;
    for (coords, 0..) |coord, i| {
        for (coords[i + 1 ..]) |next_coord| {
            // const pair = Pair.init([_]Coordinate{ coord, next_coord });
            //
            // try pairs.append(allocator, pair);
            const x = @abs(coord.x - next_coord.x) + 1;
            const y = @abs(coord.y - next_coord.y) + 1;

            maxArea = @max(maxArea, (x * y));
        }
    }

    return maxArea;
}

test "test input" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const input =
        \\7,1
        \\11,1
        \\11,7
        \\9,7
        \\9,5
        \\2,5
        \\2,3
        \\7,3
    ;

    const result = try puzzle(allocator, input);

    try std.testing.expectEqual(50, result);
}
