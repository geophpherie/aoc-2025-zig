const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "./input.txt",
        std.fs.File.OpenFlags{ .mode = .read_only },
    );
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

    const result = try puzzle(contents);
    std.debug.print("Part 1 answer : {d}\n", .{result});
}

fn puzzle(input: []const u8) !u64 {
    const trimmed = std.mem.trimEnd(u8, input, "\r\n");

    var ranges = std.mem.splitScalar(u8, trimmed, ',');

    var invalid_id_sum: u64 = 0;

    while (ranges.next()) |range| {
        var bounds = std.mem.splitScalar(u8, range, '-');

        const idRange = .{ bounds.next().?, bounds.next().? };

        std.debug.print("parsing {s} - {s}\n", .{ idRange[0], idRange[1] });
        const left = try std.fmt.parseUnsigned(u64, idRange[0], 10);
        const right = try std.fmt.parseUnsigned(u64, idRange[1], 10);

        std.debug.print("{d} - {d}\n", .{ left, right });
        for (left..right + 1) |id| {
            // each iteration is an id
            // for even number lengths, check if first half of slice == second half

            // convert to string
            var buf: [64]u8 = undefined;
            const str = try std.fmt.bufPrint(&buf, "{}", .{id});

            const str_len = str.len;

            if (@mod(str_len, 2) != 0) {
                continue;
                // std.debug.print("{s} is odd\n", .{str});
            }

            const half_str_len = str_len / 2;

            const left_half = str[0..half_str_len];
            const right_half = str[half_str_len..];

            if (std.mem.eql(u8, left_half, right_half)) {
                std.debug.print("{d} is invalid\n", .{id});
                invalid_id_sum += id;
            }
        }
    }
    return invalid_id_sum;
}

test "test input" {
    const input = "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124";

    const result = try puzzle(input);

    try std.testing.expectEqual(1227775554, result);
}
