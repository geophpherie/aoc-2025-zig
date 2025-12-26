const std = @import("std");

const PRINT = false;

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

fn rectanglePoints(allocator: std.mem.Allocator, coordinates: [2]Coordinate) !std.ArrayList(Coordinate) {
    const maxY = @max(coordinates[0].y, coordinates[1].y);
    const minY = @min(coordinates[0].y, coordinates[1].y);

    const maxX = @max(coordinates[0].x, coordinates[1].x);
    const minX = @min(coordinates[0].x, coordinates[1].x);

    var points = std.ArrayList(Coordinate){};

    for (minX..maxX + 1) |x| {
        for (minY..maxY + 1) |y| {
            const point = Coordinate{ .x = x, .y = y };

            try points.append(allocator, point);
        }
    }

    return points;
}

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

    // cache grid checks
    const gridWidth = gridMax.x - gridMin.x + 1;
    const gridHeight = gridMax.y - gridMin.y + 1;

    // cached value of if in or not
    const gridCache = try allocator.alloc(bool, gridWidth * gridHeight);

    // indicator of where we have cached values
    const gridCacheCheck = try allocator.alloc(bool, gridWidth * gridHeight);
    @memset(gridCacheCheck, false);

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
    // - check if all corners are in polygon - worthless b/c corners define polygon
    // - check if all edges are in polygon
    // - check if all points in polygon?
    var maxArea: u64 = 0;
    rectangle: for (rectangles) |rectangle| {
        // std.debug.print("rarea : {d}\n", .{rectangle.area});
        for (rectangle.edges) |redge| {
            for (redge.minX..redge.maxX + 1) |x| {
                for (redge.minY..redge.maxY + 1) |y| {
                    // checking if it is in the polygon
                    var isInside = false;

                    // this is a point on an edge
                    const point = Coordinate{ .x = x, .y = y };

                    const cacheIndex = (point.y - gridMin.y) * gridWidth + (point.x - gridMin.x);
                    if (gridCacheCheck[cacheIndex]) {
                        // have cache;
                        const cachedValue = gridCache[cacheIndex];

                        if (cachedValue) {
                            // cachedIsInside is true
                            continue;
                        }
                    }

                    // print(
                    //     "POINT: {d}, {d}\n",
                    //     .{
                    //         point.x,
                    //         point.y,
                    //     },
                    // );

                    // check all edges of the polygon
                    for (edges) |edge| {
                        // print(
                        //     "checking edge:\n\t1: {d}, {d}\n\t2: {d}, {d}\n",
                        //     .{
                        //         edge.coordinates[0].x,
                        //         edge.coordinates[0].y,
                        //         edge.coordinates[1].x,
                        //         edge.coordinates[1].y,
                        //     },
                        // );
                        // Skip horizontal edges: minY == maxY
                        if (edge.minY == edge.maxY) continue;

                        // Skip points exactly at the upper endpoint to avoid double-counting
                        if (point.y == edge.coordinates[1].y) continue;

                        // Vertical edges: toggle parity if point is left and within vertical bounds
                        if (point.y >= edge.minY and point.y < edge.maxY and point.x < edge.minX) {
                            isInside = !isInside;
                        }
                    }
                    gridCache[cacheIndex] = isInside;
                    gridCacheCheck[cacheIndex] = true;
                    // if a point is not inside polygon, add it to _outside_grid list
                    if (!isInside) {
                        print("point is not inside, skipping point: {any}\n", .{point});
                        continue :rectangle;
                    } else {
                        // if a point is inside polygon, continue inner
                        print("point is inside!: {any}\n", .{point});
                    }
                }
            }
        }

        print("rectangle wins {any}\n", .{rectangle});
        maxArea = rectangle.area;
        break;
    }

    // var maxArea: u64 = 0;
    // rectangle: for (rectangles) |rectangle| {
    //     point: for (rectangle.corners) |point| {
    //         // checking if it is in the polygon
    //         var isInside = false;
    //         // check all edges,
    //         for (edges) |edge| {
    //             print("edge : {any}\n", .{edge});
    //             // if above or below or to the right, continue edges
    //             if (point.y > edge.maxY or
    //                 point.y < edge.minY or
    //                 point.x > edge.maxX) continue;
    //
    //             const onHorizontalEdge = (point.y == edge.maxY and
    //                 point.y == edge.minY and
    //                 point.x <= edge.maxX and
    //                 point.x >= edge.minX);
    //
    //             const onVerticalEdge = (point.y <= edge.maxY and
    //                 point.y >= edge.minY and
    //                 point.x == edge.maxX and
    //                 point.x == edge.minX);
    //
    //             // if on an edge, point is in polygon, check next point
    //             if (onHorizontalEdge or onVerticalEdge) continue :point;
    //
    //             // not on an edge, and to the left of the edge
    //             // if it crosses the same vertex as y, don't count cross
    //             if (point.y == edge.minY or point.y == edge.maxY) continue;
    //
    //             // if within an edge range, flip isInside
    //             print("flip\n", .{});
    //             isInside = !isInside;
    //         }
    //         // if a point is inside polygon, continue inner
    //         // if a point is not inside polygon, add it to _outside_grid list
    //         if (!isInside) {
    //             print("point is not inside, skipping rectangle: {any}\n", .{point});
    //             continue :rectangle;
    //         } else {
    //             print("point is inside!: {any}\n", .{point});
    //         }
    //     }
    //
    //     print("rectangle wins {any}\n", .{rectangle});
    //     maxArea = rectangle.area;
    //     break;
    // }

    // edges define polygon, go through whole grid to determine points in the grid that are in or out of polygon
    // once we have "out" points, check them against each rectangles extent.
    // Sort all possible rectangles by size, go largest to smallest,
    // first rectangle that doesn't contain any out points wins!

    // var _outside_grid = std.ArrayList(Coordinate){};
    // // go through all points in the grid
    // for (gridMin.x..gridMax.x + 1) |x| {
    //     point: for (gridMin.y..gridMax.y + 1) |y| {
    //         // this is a point in the grid
    //         const point = Coordinate{ .x = x, .y = y };
    //         print("grid point : {any}\n", .{point});
    //
    //         // checking if it is in the polygon
    //         var isInside = false;
    //         // check all edges,
    //         for (edges) |edge| {
    //             print("edge : {any}\n", .{edge});
    //             // if above or below or to the right, continue edges
    //             if (point.y > edge.maxY or
    //                 point.y < edge.minY or
    //                 point.x > edge.maxX) continue;
    //
    //             const onHorizontalEdge = (point.y == edge.maxY and
    //                 point.y == edge.minY and
    //                 point.x <= edge.maxX and
    //                 point.x >= edge.minX);
    //
    //             const onVerticalEdge = (point.y <= edge.maxY and
    //                 point.y >= edge.minY and
    //                 point.x == edge.maxX and
    //                 point.x == edge.minX);
    //
    //             // if on an edge, point is in polygon, check next point
    //             if (onHorizontalEdge or onVerticalEdge) continue :point;
    //
    //             // not on an edge, and to the left of the edge
    //             // if it crosses the same vertex as y, don't count cross
    //             if (point.y == edge.minY or point.y == edge.maxY) continue;
    //
    //             // if within an edge range, flip isInside
    //             print("flip\n", .{});
    //             isInside = !isInside;
    //         }
    //         // if a point is inside polygon, continue inner
    //         // if a point is not inside polygon, add it to _outside_grid list
    //         if (!isInside) {
    //             print("point is not inside: {any}\n", .{point});
    //             try _outside_grid.append(allocator, point);
    //         } else {
    //             print("point is inside!: {any}\n", .{point});
    //         }
    //     }
    // }
    // const not_grid = try _outside_grid.toOwnedSlice(allocator);
    // std.debug.print("not grid point count: {d}\n", .{not_grid.len});
    // print("not grid points: {any}\n", .{not_grid});
    //
    // for (coordinates, 0..) |coord, i| {
    //     diagonal: for (coordinates[i + 1 ..]) |next_coord| {
    //         const maxY = @max(coord.y, next_coord.y);
    //         const minY = @min(coord.y, next_coord.y);
    //
    //         const maxX = @max(coord.x, next_coord.x);
    //         const minX = @min(coord.x, next_coord.x);
    //
    //         std.debug.print("diag : {any} {any}\n", .{ coord, next_coord });
    //         // go through all points in this rectangle
    //         for (minX..maxX + 1) |x| {
    //             point: for (minY..maxY + 1) |y| {
    //                 // this is a point in the rectangle
    //                 const point = Coordinate{ .x = x, .y = y };
    //                 print("point : {any}\n", .{point});
    //
    //                 // checking if it is in the polygon
    //                 var isInside = false;
    //                 // check all edges,
    //                 for (edges) |edge| {
    //                     print("edge : {any}\n", .{edge});
    //                     // if above or below or to the right, continue edges
    //                     if (point.y > edge.maxY or
    //                         point.y < edge.minY or
    //                         point.x > edge.maxX) continue;
    //
    //                     const onEdgeX = (point.y == edge.maxY and
    //                         point.y == edge.minY and
    //                         point.x <= edge.maxX and
    //                         point.x >= edge.minX);
    //
    //                     const onEdgeY = (point.y <= edge.maxY and
    //                         point.y >= edge.minY and
    //                         point.x == edge.maxX and
    //                         point.x == edge.minX);
    //
    //                     // if on an edge, point is in polygon, continue point loop
    //                     if (onEdgeX or onEdgeY) continue :point;
    //
    //                     // if within an edge range, flip isInside
    //                     print("flip\n", .{});
    //                     isInside = !isInside;
    //                 }
    //                 // if a point is inside polygon, continue inner
    //                 if (isInside) {
    //                     continue :point;
    //                 } else {
    //                     // if a point is outside polygon, continue "diagonal"
    //                     continue :diagonal;
    //                 }
    //             }
    //         }
    //         // valid rectangle
    //         const area = (maxX - minX + 1) * (maxY - minY + 1);
    //
    //         print("diag : {any} {any} area {d}\n", .{ coord, next_coord, area });
    //         maxArea = @max(maxArea, area);
    //     }
    // }

    // for each point in a rect
    // check if it is inside or outside polygon
    // check y position, xmax, slopes
    // if outside bail

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
