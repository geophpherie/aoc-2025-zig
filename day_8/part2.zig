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
    std.debug.print("Elapsed time: {d} ms\n", .{timer.read() / 1000 / 1000});
}

const Coordinate = struct {
    x: i64,
    y: i64,
    z: i64,
    id: usize,
};

const Pair = struct {
    coordinates: [2]Coordinate,
    distance: f64,

    fn init(coordinates: [2]Coordinate) @This() {
        const distance = calcDistance(coordinates[0], coordinates[1]);

        return .{ .coordinates = coordinates, .distance = distance };
    }

    fn calcDistance(a: Coordinate, b: Coordinate) f64 {
        const dx = a.x - b.x;
        const dy = a.y - b.y;
        const dz = a.z - b.z;

        const sum: f64 = @floatFromInt(dx * dx + dy * dy + dz * dz);

        return std.math.sqrt(sum);
    }
};

fn puzzle(allocator: std.mem.Allocator, input: []const u8) !i64 {
    const trimmed = std.mem.trimEnd(u8, input, "\r\n");
    var split_lines = std.mem.splitScalar(u8, trimmed, '\n');

    // keep each line as an array of chars
    var coordinates = std.ArrayList(Coordinate){};

    var index: usize = 0;

    while (split_lines.next()) |line| {
        if (line.len == 0) continue;

        var coords = std.mem.splitScalar(u8, line, ',');

        const coordinate = Coordinate{
            .x = try std.fmt.parseInt(i64, coords.next().?, 10),
            .y = try std.fmt.parseInt(i64, coords.next().?, 10),
            .z = try std.fmt.parseInt(i64, coords.next().?, 10),
            .id = index,
        };

        try coordinates.append(allocator, coordinate);

        index += 1;
    }
    const coords = try coordinates.toOwnedSlice(allocator);

    var pairs = std.ArrayList(Pair){};
    for (coords, 0..) |coord, i| {
        for (coords[i + 1 ..]) |next_coord| {
            const pair = Pair.init([_]Coordinate{ coord, next_coord });

            try pairs.append(allocator, pair);
        }
    }

    std.mem.sort(Pair, pairs.items, {}, comparePair);

    const elements = try allocator.alloc(usize, coords.len);
    for (elements, 0..) |_, i| {
        elements[i] = i;
    }

    const sizes = try allocator.alloc(usize, coords.len);
    @memset(sizes, 1);

    var length: i64 = undefined;
    for (pairs.items) |pair| {
        // std.debug.print("pair: {any} {d}\n", .{ pair.coordinates, pair.distance });
        _union(elements, sizes, pair.coordinates[0].id, pair.coordinates[1].id);
        // std.debug.print("{any}\n", .{elements});

        // if max of sizes is the number of elements
        const max = std.mem.max(usize, sizes);
        if (max == elements.len) {
            // std.debug.print("max {d}\n", .{max});
            length = pair.coordinates[0].x * pair.coordinates[1].x;
            break;
        }
    }

    return length;
}

fn root(elements: []usize, index: usize) usize {
    // to find the root of an element, follow until the index equals the value
    // for initial array, i.e. e[4] = 4, so it is its own root
    // later, e[4] might be 2 so check e[2]. if e[2] = 2, then the root is 2
    var i = index;
    while (elements[i] != i) {
        i = elements[i];
    }
    // while (elements[i] != i) {
    //     elements[i] = elements[elements[i]];
    //     i = elements[i];
    // }

    return i;
}

fn _union(elements: []usize, sizes: []usize, a: usize, b: usize) void {
    // unioning two elements
    // find the root of a (root of 0 is 0 for initialized)
    // find the root of b (root of 19 is 19 for initialized)
    // set root of 0 to be root of 19 (aka e[0] now is 19)
    const aRoot = root(elements, a);
    const bRoot = root(elements, b);

    if (aRoot == bRoot) {
        return;
    }
    // elements[aRoot] = bRoot;
    //
    if (sizes[aRoot] < sizes[bRoot]) {
        elements[aRoot] = elements[bRoot];
        sizes[bRoot] += sizes[aRoot];
    } else {
        elements[bRoot] = elements[aRoot];
        sizes[aRoot] += sizes[bRoot];
    }
}

fn comparePair(_: void, a: Pair, b: Pair) bool {
    return a.distance < b.distance;
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
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
    ;

    const result = try puzzle(allocator, input);

    try std.testing.expectEqual(25272, result);
}
