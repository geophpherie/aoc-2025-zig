const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const result = gpa.deinit();
        if (result == .leak) std.debug.print("leak detected\n", .{});
    }

    const input = try readFile(allocator, "./input.txt");
    defer allocator.free(input);

    var grid = try ConvertToGrid(allocator, input);
    defer grid.deinit(allocator);

    const result = try puzzle(allocator, grid);

    std.debug.print("Part 2 answer : {d}\n", .{result});
}

fn puzzle(allocator: std.mem.Allocator, grid: std.ArrayList([]const u8)) !i16 {
    var grid_copy = std.ArrayList([]u8){};

    for (grid.items) |row| {
        const new_row = try allocator.alloc(u8, row.len);
        std.mem.copyForwards(u8, new_row, row);
        try grid_copy.append(allocator, new_row);
    }
    var total_removed: i16 = 0;
    // need to iterate this until none can be removed
    // track total removed
    var CoordList = std.ArrayList(Coord){};
    defer CoordList.deinit(allocator);
    while (true) {
        var to_remove: i16 = 0;
        for (grid_copy.items, 0..) |row, ri| {
            for (row, 0..) |col, ci| {
                _ = grid_copy.items[ri][ci];
                if (col == '@') {
                    // check the 8
                    std.debug.print("towel at {d}x{d}\n", .{ ri, ci });
                    if (canBeAccessed(grid_copy, ri, ci)) {
                        to_remove += 1;
                        // save coords for update
                        try CoordList.append(allocator, .{ .row = ri, .col = ci });
                    }
                }
            }
        }

        if (to_remove == 0) break;

        // update grid with removed ones
        for (CoordList.items) |coords| {
            grid_copy.items[coords.row][coords.col] = '.';
        }

        std.debug.assert(to_remove == CoordList.items.len);
        total_removed += to_remove;

        CoordList.clearRetainingCapacity();
    }
    for (grid_copy.items) |row| {
        allocator.free(row);
    }

    grid_copy.deinit(allocator);

    return total_removed;
}

const Coord = struct {
    row: usize,
    col: usize,
};

/// see if a roll of paper can be accessed by checking the 8 surrounding spaces
/// only can be accessed if there are < 4 other rolls
fn canBeAccessed(grid: std.ArrayList([] u8), ri: usize, ci: usize) bool {
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

    const result = try puzzle(allocator, grid);

    try std.testing.expectEqual(43, result);
}
