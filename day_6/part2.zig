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

    std.debug.print("Part 2 answer : {d}\n", .{result});

    std.debug.print("Elapsed time: {d} ms\n", .{timer.read() / 1000 / 1000});
}

const Range = struct { left: u64, right: u64 };

fn puzzle(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const trimmed = std.mem.trimEnd(u8, input, "\r\n");
    var splitLines = std.mem.splitScalar(u8, trimmed, '\n');

    // keep each line as list of strings
    var lines = std.ArrayList([]const u8){};
    defer lines.deinit(allocator);

    while (splitLines.next()) |line| {
        if (line.len == 0) continue;

        try lines.append(allocator, line);
    }

    const numRows = lines.items.len;

    var splitSigns = std.mem.tokenizeScalar(u8, lines.items[numRows - 1], ' ');

    var signs = std.ArrayList([]const u8){};
    defer signs.deinit(allocator);
    while (splitSigns.next()) |sign| {
        try signs.append(allocator, sign);
    }

    const numNumericRows = lines.items.len - 1;
    const rowLength = lines.items[0].len;

    var total: u64 = 0;
    var problemTotal: u64 = undefined;
    for (0..rowLength) |ind| {
        const rev_ind = rowLength - 1 - ind;
        std.debug.print("col : {d}\n", .{rev_ind});

        const sign = signs.items[rev_ind];

        if (std.mem.eql(u8, sign, "*")) {
            problemTotal = 1;
        } else {
            problemTotal = 0;
        }

        var numBuff = try allocator.alloc(u8, numNumericRows);
        for (0..numNumericRows) |row| {
            std.debug.print("char : {c}\n", .{lines.items[row][rev_ind]});
            numBuff[row] = lines.items[row][rev_ind];
        }

        const trimmedNumBuff = std.mem.trim(u8, numBuff, " ");
        if (trimmedNumBuff.len == 0) {
            total += problemTotal;
            continue;
        }

        const number = try std.fmt.parseInt(u64, trimmedNumBuff, 10);
        if (std.mem.eql(u8, sign, "*")) {
            problemTotal *= number;
        } else {
            problemTotal += number;
        }


        std.debug.print("number : {d}\n", .{number});
    }

    std.debug.print("line count : {d}\n", .{lines.items.len});
    std.debug.print("signs: {any}\n", .{signs.items});

    return problemTotal;
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
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   + 
    ;

    const result = try puzzle(allocator, input);

    try std.testing.expectEqual(3263827, result);
}
