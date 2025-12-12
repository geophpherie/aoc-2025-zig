const std = @import("std");

pub fn main() !void {
    var timer = try std.time.Timer.start(); // Get the current instant
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        if (gpa.deinit() != .ok) std.debug.print("leak detected\n", .{});
    }

    const input = try readFile(allocator, "./input.txt");
    defer allocator.free(input);

    const result = try puzzle(allocator, input);

    std.debug.print("Part 1 answer : {d}\n", .{result});

    std.debug.print("Elapsed time: {d} ms\n", .{timer.read() / 1000 / 1000});
}

const Range = struct { left: u64, right: u64 };

fn puzzle(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const trimmed = std.mem.trimEnd(u8, input, "\r\n");
    var splitLines = std.mem.splitScalar(u8, trimmed, '\n');

    var lines = std.ArrayList(std.ArrayList([]const u8)){};

    defer {
        for (lines.items) |*numbers| {
            for (numbers.items) |token| {
                allocator.free(token);
            }
            numbers.deinit(allocator);
        }
        lines.deinit(allocator);
    }

    while (splitLines.next()) |line| {
        if (line.len == 0) continue;

        var numbers = std.ArrayList([]const u8){};

        var splitNumbers = std.mem.tokenizeScalar(u8, line, ' ');
        while (splitNumbers.next()) |number| {
            const n = try allocator.dupe(u8, number);
            try numbers.append(allocator, n);
        }

        try lines.append(allocator, numbers);
    }

    std.debug.print("line count : {d}\n", .{lines.items.len});

    const numRows = lines.items.len;
    const numNumberRows = lines.items.len - 1;
    // use first row to determine num cols
    const numCols = lines.items[0].items.len;

    var totalValue: u64 = 0;

    var numbers = try allocator.alloc(i16, numNumberRows);
    defer allocator.free(numbers);
    // index into a row
    for (0..numCols) |col| {
        // track all values in this column
        // number rows
        const sign = lines.items[numRows - 1].items[col];

        var problemValue: u64 = undefined;
        if (std.mem.eql(u8, sign, "*")) {
            problemValue = 1;
        } else {
            problemValue = 0;
        }
        for (0..numNumberRows) |row| {
            numbers[row] = try std.fmt.parseInt(i16, lines.items[row].items[col], 10);
            std.debug.print("values {s} {d}\n", .{ sign, numbers[row] });

            if (std.mem.eql(u8, sign, "*")) {
                problemValue *= @intCast(numbers[row]);
            } else {
                problemValue += @intCast(numbers[row]);
            }
        }

        totalValue += problemValue;
    }
    
    std.debug.print("tot value {d}\n", .{totalValue });

    return totalValue;
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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input =
        \\123 328  51 64 
        \\45 64  387 23 
        \\6 98  215 314
        \\*   +   *   + 
    ;

    const result = try puzzle(allocator, input);

    try std.testing.expectEqual(4277556, result);
}
