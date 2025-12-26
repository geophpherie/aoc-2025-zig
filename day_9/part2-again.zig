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

    std.debug.print("Part 2 answer : {d}\n", .{result});
    std.debug.print("Elapsed time: {d} ms\n", .{timer.read() / 1000 / 1000});
    // 17411151 too low
    // 1578115935 correct but 970 seconds!
    // with cache - 39 sec (print), 37 (no print) 
    // 27 sec checking edge in rectangle, 1.7 sec checking bounding first
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
    x: u64,
    y: u64,
};

const Rectangle = struct {
    coordinates: [2]Coordinate,
    area: u64,
    corners: [4]Coordinate,
    edges: [4]Edge,
    minX: u64,
    maxX: u64,
    minY: u64,
    maxY: u64,

    fn init(coordinates: [2]Coordinate) @This() {
        const maxY = @max(coordinates[0].y, coordinates[1].y);
        const minY = @min(coordinates[0].y, coordinates[1].y);

        const maxX = @max(coordinates[0].x, coordinates[1].x);
        const minX = @min(coordinates[0].x, coordinates[1].x);

        const x = maxX - minX + 1;
        const y = maxY - minY + 1;

        const area = x * y;

        const corner1 = coordinates[0];
        const corner3 = coordinates[1];
        const corner2 = Coordinate{ .x = coordinates[0].x, .y = coordinates[1].y };
        const corner4 = Coordinate{ .x = coordinates[1].x, .y = coordinates[0].y };

        const edge1 = Edge.init(.{ corner1, corner2 });
        const edge2 = Edge.init(.{ corner2, corner3 });
        const edge3 = Edge.init(.{ corner3, corner4 });
        const edge4 = Edge.init(.{ corner4, corner1 });

        return .{
            .coordinates = coordinates,
            .area = area,
            .corners = .{ corner1, corner2, corner3, corner4 },
            .edges = .{ edge1, edge2, edge3, edge4 },
            .minX = minX,
            .minY = minY,
            .maxX = maxX,
            .maxY = maxY,
        };
    }
};

const Edge = struct {
    coordinates: [2]Coordinate,
    minX: u64,
    maxX: u64,
    minY: u64,
    maxY: u64,

    fn init(coordinates: [2]Coordinate) @This() {
        const maxY = @max(coordinates[0].y, coordinates[1].y);
        const minY = @min(coordinates[0].y, coordinates[1].y);

        const maxX = @max(coordinates[0].x, coordinates[1].x);
        const minX = @min(coordinates[0].x, coordinates[1].x);
        return .{
            .coordinates = coordinates,
            .minX = minX,
            .maxX = maxX,
            .minY = minY,
            .maxY = maxY,
        };
    }
};

// lessThanFn = comes before fn i.e. must be true when a comes before b
fn compareRectangle(_: void, a: Rectangle, b: Rectangle) bool {
    return a.area > b.area;
}

fn puzzle(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const trimmed = std.mem.trimEnd(u8, input, "\r\n");
    var split_lines = std.mem.splitScalar(u8, trimmed, '\n');

    // these are reversed intentionally
    var gridMax = Coordinate{ .x = 0, .y = 0 };
    var gridMin = Coordinate{ .x = std.math.maxInt(u64), .y = std.math.maxInt(u64) };

    // define coordinates
    var _coordinates = std.ArrayList(Coordinate){};
    var index: usize = 0;
    while (split_lines.next()) |line| {
        if (line.len == 0) continue;

        var coords = std.mem.splitScalar(u8, line, ',');

        const coordinate = Coordinate{
            .x = try std.fmt.parseInt(u64, coords.next().?, 10),
            .y = try std.fmt.parseInt(u64, coords.next().?, 10),
        };

        try _coordinates.append(allocator, coordinate);

        gridMax.x = @max(gridMax.x, coordinate.x);
        gridMax.y = @max(gridMax.y, coordinate.y);

        gridMin.x = @min(gridMin.x, coordinate.x);
        gridMin.y = @min(gridMin.y, coordinate.y);

        index += 1;
    }
    const coordinates = try _coordinates.toOwnedSlice(allocator);

    std.debug.print("Grid Size:\n\tmin: {any}\n\tmax: {any}\n", .{ gridMin, gridMax });

    // // cache grid checks
    // const gridWidth = gridMax.x - gridMin.x + 1;
    // const gridHeight = gridMax.y - gridMin.y + 1;
    //
    // // cached value of if in or not
    // const gridCache = try allocator.alloc(bool, gridWidth * gridHeight);
    //
    // // indicator of where we have cached values
    // const gridCacheCheck = try allocator.alloc(bool, gridWidth * gridHeight);
    // @memset(gridCacheCheck, false);
    //
    // define edges of polygon
    var _edges = std.ArrayList(Edge){};
    for (coordinates, 0..) |coord, i| {
        const coord1 = coord;
        const coord2 = coordinates[(i + 1) % coordinates.len];

        const edge = Edge.init([_]Coordinate{ coord1, coord2 });

        try _edges.append(allocator, edge);
    }
    const edges = try _edges.toOwnedSlice(allocator);

    var _rectangles = std.ArrayList(Rectangle){};
    // define all rectangles by area
    for (coordinates, 0..) |coord, i| {
        for (coordinates[i + 1 ..]) |next_coord| {
            const rectangle = Rectangle.init(.{ coord, next_coord });
            try _rectangles.append(allocator, rectangle);
        }
    }
    const rectangles = try _rectangles.toOwnedSlice(allocator);
    print("num rects: {any}\n", .{rectangles[0]});

    std.mem.sort(Rectangle, rectangles, {}, compareRectangle);

    print("num rects: {any}\n", .{rectangles[0]});

    // we have largest rectangles
    // - check if any edge vertex is inside the rectangle.
    var maxArea: u64 = 0;
    rectangle: for (rectangles) |rectangle| {
        // for each coordinate of polygon, check if inside rect
        std.debug.print("{d}\n", .{rectangle.area});
        for (edges) |edge| {

            if (edge.minX >= rectangle.maxX or 
                edge.maxX <= rectangle.minX or 
                edge.minY >= rectangle.maxY or 
                edge.maxY <= rectangle.minY) {
                continue;
            }


            for (edge.minX..edge.maxX + 1) |x| {
                for (edge.minY..edge.maxY + 1) |y| {
                    if (x < rectangle.maxX and
                        x > rectangle.minX and
                        y < rectangle.maxY and
                        y > rectangle.minY)
                    {
                        // point in rect, rect doesn't count
                        continue :rectangle;
                    }
                }
            }
        }

        print("rectangle wins {d} {d} {d} {d}\n", .{ rectangle.minX, rectangle.maxX, rectangle.minY, rectangle.maxY });
        maxArea = rectangle.area;
        break;
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

    try std.testing.expectEqual(24, result);
}
