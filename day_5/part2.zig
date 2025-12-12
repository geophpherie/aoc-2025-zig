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

    // 69383079856495 - TOO LOW
    // 358155203664116

    std.debug.print("Elapsed time: {d} nanoseconds\n", .{timer.read() / 1000 / 1000});
}

const Range = struct { left: u64, right: u64 };

fn puzzle(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const trimmed = std.mem.trimEnd(u8, input, "\r\n");
    var lines = std.mem.splitScalar(u8, trimmed, '\n');

    // parse lines into ranges and ids, either based on empty line or the presence of '-'
    var IdRanges = std.ArrayList(Range){};

    // initialize our ranges
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        // std.debug.print("{s}\n", .{ line});
        var bounds = std.mem.splitScalar(u8, line, '-');
        const idRange = .{ bounds.next().?, bounds.next().? };

        const left = try std.fmt.parseUnsigned(u64, idRange[0], 10);
        const right = try std.fmt.parseUnsigned(u64, idRange[1], 10);

        try IdRanges.append(allocator, .{ .left = left, .right = right });
    }

    main: while (true) {
        // go through them and check overlaps with the previous
        for (IdRanges.items[1..IdRanges.items.len], 1..) |range, i| {
            // std.debug.print("{d} - {d} {d}\n", .{ range.left, range.right, i });

            // std.debug.print("MAIN : {d}\n", .{i});
            //
            // if (i > 50) {
            //     break :main;
            // }
            var RevIdRanges = std.mem.reverseIterator(IdRanges.items[0..i]);

            var offset: usize = 1;
            while (RevIdRanges.next()) |prev_range| : (offset += 1) {
                const prev_i = i - offset;
                // std.debug.print("{d} - {d} {d}\n", .{ prev_range.left, prev_range.right, j });

                // check no overlap - continue
                if (range.left > prev_range.right or range.right < prev_range.left) {
                    // std.debug.print(
                    //     "no overlap -- {d}-{d} and {d}-{d}\n",
                    //     .{
                    //         range.left,
                    //         range.right,
                    //         prev_range.left,
                    //         prev_range.right,
                    //     },
                    // );
                    continue;
                }

                // check totally inside - range in prev, remove range
                if (range.left <= prev_range.right and
                    range.left >= prev_range.left and
                    range.right <= prev_range.right and
                    range.right >= prev_range.left)
                {
                    // std.debug.print(
                    //     "totally inside -- ({d}) {d}-{d} and ({d}) {d}-{d} removing ({d}) {d}-{d}\n",
                    //     .{
                    //         i,
                    //         range.left,
                    //         range.right,
                    //         prev_i,
                    //         prev_range.left,
                    //         prev_range.right,
                    //         i,
                    //         range.left,
                    //         range.right,
                    //     },
                    // );

                    _ = IdRanges.orderedRemove(i);
                    // std.debug.print("removed {d}-{d}\n", .{ removed.left, removed.right });
                    continue :main;
                }

                // check wholly encompassing - prev in range, remove prev
                if (prev_range.left <= range.right and
                    prev_range.left >= range.left and
                    prev_range.right <= range.right and
                    prev_range.right >= range.left)
                {
                    // std.debug.print(
                    //     "encompassing -- ({d}) {d}-{d} and ({d}) {d}-{d} removing ({d}) {d}-{d}\n",
                    //     .{
                    //         i,
                    //         range.left,
                    //         range.right,
                    //         prev_i,
                    //         prev_range.left,
                    //         prev_range.right,
                    //         prev_i,
                    //         prev_range.left,
                    //         prev_range.right,
                    //     },
                    // );

                    _ = IdRanges.orderedRemove(prev_i);
                    // std.debug.print("removed {d}-{d}\n", .{ removed.left, removed.right });
                    continue :main;
                }

                // check left overlap - this range overlaps lower bound, bump this upper bound down to lower -1
                if (range.left < prev_range.left and range.right < prev_range.right) {
                    // std.debug.print(
                    //     "left overlap -- {d}-{d} and {d}-{d} setting {d}-{d} to {d}-{d}\n",
                    //     .{
                    //         range.left,
                    //         range.right,
                    //         prev_range.left,
                    //         prev_range.right,
                    //         range.left,
                    //         range.right,
                    //         range.left,
                    //         prev_range.left - 1,
                    //     },
                    // );
                    IdRanges.items[i].right = prev_range.left - 1;
                    continue :main;
                }

                // check right overlap - this range overlaps upper bound, bump this lower bound up to upper + 1
                if (range.right > prev_range.right and range.left < prev_range.right) {
                    // std.debug.print(
                    //     "right overlap -- {d}-{d} and {d}-{d} setting {d}-{d} to {d}-{d}\n",
                    //     .{
                    //         range.left,
                    //         range.right,
                    //         prev_range.left,
                    //         prev_range.right,
                    //         range.left,
                    //         range.right,
                    //         prev_range.right + 1,
                    //         range.right,
                    //     },
                    // );
                    IdRanges.items[i].left = prev_range.right + 1;
                    continue :main;
                }
            }
        }
        break;
    }

    std.debug.print("ranges : {d}\n", .{IdRanges.items.len});

    var count: u64 = 0;
    for (IdRanges.items) |range| {
        count += range.right - range.left + 1;
    }

    IdRanges.deinit(allocator);

    return count;
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
        \\3-5
        \\10-14
        \\16-20
        \\12-18
    ;

    const result = try puzzle(allocator, input);

    try std.testing.expectEqual(14, result);
}
