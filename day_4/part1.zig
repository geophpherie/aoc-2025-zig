const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        if (gpa.deinit() != .ok) std.debug.print("leak detected\n", .{});
    }

    const input = try readFile(allocator, "./input.txt");
    defer allocator.free(input);

    var grid = try ConvertToGrid(allocator, input);
    defer grid.deinit(allocator);

    const result = try puzzle(grid);

    std.debug.print("Part 1 answer : {d}\n", .{result});
}

fn puzzle(grid: std.ArrayList([]const u8)) !i16 {
    var count: i16 = 0;
    for (grid.items, 0..) |row, ri| {
        for (row, 0..) |col, ci| {
            _ = grid.items[ri][ci];
            if (col == '@') {
                // check the 8
                std.debug.print("towel at {d}x{d}\n", .{ ri, ci });
                if (canBeAccessed(grid, ri, ci)) count += 1;
            }
        }
    }

    return count;
}

/// see if a roll of paper can be accessed by checking the 8 surrounding spaces
/// only can be accessed if there are < 4 other rolls
fn canBeAccessed(grid: std.ArrayList([]const u8), ri: usize, ci: usize) bool {
    const num_rows = grid.items.len;

    var num_towels: u16 = 0;

    // bounds check so it needs to be able to be negative (usize doesn't work)
    var r = @as(i16, @intCast(ri)) - 1;
    while (r <= ri + 1) : (r += 1) {
        if ((r < 0) or (r > num_rows - 1)) {
            // out of bounds rows
            // std.debug.print("row {d} is OOB\n", .{r});
            continue;
        }

        // convert back to be usable
        const ur: usize = @intCast(r);

        // same thing, bounds check
        var c = @as(i16, @intCast(ci)) - 1;
        while (c <= ci + 1) : (c += 1) {
            const num_cols = grid.items[ur].len;
            if ((c < 0) or (c > num_cols - 1)) {
                // out of bounds col
                // std.debug.print("col {d} is OOB\n", .{c});
                continue;
            }

            // convert back to be usable
            const uc: usize = @intCast(c);

            // don't count ourself
            if (ur == ri and uc == ci) {
                continue;
            }

            // can check for other towels
            if (grid.items[ur][uc] == '@') {
                num_towels += 1;
                // std.debug.print("found at {d} {d} count is {d}\n", .{ur, uc, num_towels});
            }
        }
    }

    return num_towels < 4;
}

fn ConvertToGrid(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList([]const u8) {
    var grid = std.ArrayList([]const u8){};

    const trimmed = std.mem.trimEnd(u8, input, "\r\n");
    var rows = std.mem.splitScalar(u8, trimmed, '\n');

    while (rows.next()) |row| {
        try grid.append(allocator, row);
    }

    return grid;
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
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
    ;

    var grid = try ConvertToGrid(allocator, input);
    defer grid.deinit(allocator);

    const result = try puzzle(grid);

    try std.testing.expectEqual(13, result);
}
