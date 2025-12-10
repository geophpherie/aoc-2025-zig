const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        if (gpa.deinit() != .ok) std.debug.print("leak detected\n", .{});
    }

    const input = try readFile(allocator, "./input.txt");
    defer allocator.free(input);

    const result = try puzzle(allocator, input);

    std.debug.print("Part 1 answer : {d}\n", .{result});
}

const Range = struct { left: u64, right: u64 };

fn puzzle(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const trimmed = std.mem.trimEnd(u8, input, "\r\n");
    var lines = std.mem.splitScalar(u8, trimmed, '\n');

    // parse lines into ranges and ids, either based on empty line or the presence of '-'
    var fresh_ids = std.ArrayList(Range){};

    var count: u64 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        std.debug.print("{s}\n", .{line});
        const hasDash = std.mem.indexOfScalar(u8, line, '-');
        if (hasDash) |_| {
            var bounds = std.mem.splitScalar(u8, line, '-');
            const idRange = .{ bounds.next().?, bounds.next().? };

            // std.debug.print("parsing {s} - {s}\n", .{ idRange[0], idRange[1] });
            const left = try std.fmt.parseUnsigned(u64, idRange[0], 10);
            const right = try std.fmt.parseUnsigned(u64, idRange[1], 10);

            try fresh_ids.append(allocator, .{ .left = left, .right = right });
            std.debug.print("{d} - {d}\n", .{ left, right });
        } else {
            const id = try std.fmt.parseUnsigned(u64, line, 10);
            for (fresh_ids.items) |range| {
                if (id >= range.left and id <= range.right) {
                    count += 1;
                    break;
                }
            }
        }
    }

    fresh_ids.deinit(allocator);

    std.debug.print("ranges : {d}\n", .{fresh_ids.items.len});
    // std.debug.print("ids : {d}\n", .{ids.items.len});
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
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    ;

    const result = try puzzle(allocator, input);

    try std.testing.expectEqual(3, result);
}
