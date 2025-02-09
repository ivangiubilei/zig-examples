const rl = @import("raylib");
const std = @import("std");

const World = struct {
    allocator: std.mem.Allocator,
    grid: []bool,
    width: i32,
    height: i32,
    cell_size: i32,

    pub fn init(allocator: std.mem.Allocator, w: i32, h: i32, size: i32) !World {
        return World{
            .allocator = allocator,
            .grid = try allocator.alloc(bool, @intCast(w * h)),
            .width = w,
            .height = h,
            .cell_size = size,
        };
    }

    pub fn reset(self: *World) void {
        for (0..@intCast(self.grid.len)) |i| {
            self.grid[i] = false;
        }
    }

    pub fn changeCell(self: *World, cell: usize, status: bool) void {
        self.grid[cell] = status;
    }

    pub fn draw(self: World) void {
        const width: usize = @intCast(self.width);
        const height: usize = @intCast(self.height);
        const size: usize = @intCast(self.cell_size);

        for (0..width) |row| {
            for (0..height) |col| {
                const index = row * height + col;
                const x = @as(i32, @intCast(col * size));
                const y = @as(i32, @intCast(row * size));

                if (self.grid[index]) {
                    rl.drawRectangle(x, y, self.cell_size, self.cell_size, World.hexColor(0x5B913B));
                } else {
                    rl.drawRectangle(x, y, self.cell_size, self.cell_size, World.hexColor(0xFFFDF0));
                }
            }
        }
    }

    pub fn drawGrid(rows: usize, cell_width: usize) void {
        for (0.., rows) |i, _| {
            for (0.., rows) |j, _| {
                rl.drawRectangleLines(@intCast(i * cell_width), @intCast(j * cell_width), @intCast(cell_width), @intCast(cell_width), rl.Color.black);
            }
        }
    }

    pub fn randomConfiguration(self: *World, number: usize) !void {
        var prng = std.rand.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            try std.posix.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });
        const rand = prng.random();

        for (0..number) |_| {
            const random = rand.intRangeAtMost(usize, 0, self.grid.len - 1);
            self.changeCell(random, true);
        }
    }

    fn coordinateToIndex(width: i32, x: i32, y: i32) i32 {
        const pos = y * width + x;
        return pos;
    }

    pub fn countNeighbours(self: *World, x: i32, y: i32) i32 {
        var count: i32 = 0;
        const position = coordinateToIndex(self.width, x, y);

        const pos_n = position - self.width;
        const pos_p = position + self.width;

        const possible_positions = [_]i32{ position - 1, position + 1, pos_n, pos_n - 1, pos_n + 1, pos_p, pos_p - 1, pos_p + 1 };

        for (possible_positions) |el| {
            if (el >= 0 and el < self.grid.len and self.grid[@intCast(el)]) {
                count += 1;
            }
        }
        return count;
    }

    fn hexColor(hex: u32) rl.Color {
        return rl.Color{
            .r = @intCast((hex >> 16) & 0xFF),
            .g = @intCast((hex >> 8) & 0xFF),
            .b = @intCast(hex & 0xFF),
            .a = 255,
        };
    }

    pub fn simulate(self: *World) !void {
        var copied_world = try World.init(self.allocator, self.width, self.height, self.cell_size);
        defer self.allocator.free(copied_world.grid);

        const wi32: usize = @intCast(self.width);
        const hi32: usize = @intCast(self.height);

        for (0..wi32) |w| {
            for (0..hi32) |h| {
                const coor: usize = @intCast(coordinateToIndex(self.width, @intCast(w), @intCast(h)));
                const count_n = self.countNeighbours(@intCast(w), @intCast(h));
                const cell_value = self.grid[coor];
                if (cell_value) {
                    if (count_n > 3 or count_n < 2) {
                        copied_world.changeCell(coor, false);
                    } else {
                        copied_world.changeCell(coor, true);
                    }
                } else {
                    if (count_n == 3) {
                        copied_world.changeCell(coor, true);
                    } else {
                        copied_world.changeCell(coor, false);
                    }
                }
            }
        }

        // copy to the original world
        std.mem.copyForwards(bool, self.grid, copied_world.grid);
    }
};

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 800;

    const cell_width: i32 = 20;
    const rows: i32 = screenHeight / cell_width;

    rl.initWindow(screenWidth, screenHeight, "Conway's game of life");
    defer rl.closeWindow();

    rl.setTargetFPS(6);

    // allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer std.debug.print("{any}\n", .{gpa.deinit()});
    const allocator = gpa.allocator();

    // create world
    var world = try World.init(allocator, rows, rows, cell_width);
    defer world.allocator.free(world.grid);

    world.reset();
    try world.randomConfiguration(screenWidth * screenHeight / 2100);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        try world.simulate();

        world.draw();
        World.drawGrid(rows, cell_width);

        rl.clearBackground(World.hexColor(0xC4D9FF));
    }
}
