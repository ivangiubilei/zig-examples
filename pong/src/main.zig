const rl = @import("raylib");
const std = @import("std");
const print = @import("std").debug.print;

const SCREENWIDTH = 800;
const SCREENHEIGHT = 450;

var player_score: u32 = 0;
var cpu_score: u32 = 0;

const Ball = struct {
    position: rl.Vector2,
    size: rl.Vector2,
    speed: rl.Vector2,

    pub fn init(x: f32, y: f32, size: f32, speed: f32) Ball {
        return .{
            .position = rl.Vector2.init(x, y),
            .size = rl.Vector2.init(size, size),
            .speed = rl.Vector2.init(speed, speed),
        };
    }

    pub fn update(self: *Ball) void {
        if (self.position.y <= 0 or self.position.y + self.size.y >= SCREENHEIGHT) {
            self.speed.y *= -1;
        }

        if (self.position.x <= 10) {
            cpu_score += 1;
            self.reset();
        }
        if (self.position.x + self.size.x >= SCREENWIDTH - 20) {
            player_score += 1;
            self.speed.x *= -1;
            self.reset();
        }

        self.position.x += self.speed.x;
        self.position.y += self.speed.y;
    }

    pub fn checkCollisions(self: *Ball, other: Paddle) void {
        const firstRect = rl.Rectangle.init(self.position.x, self.position.y, self.size.x, self.size.y);
        const secondRect = rl.Rectangle.init(other.position.x, other.position.y, other.size.x, other.size.y);
        if (rl.checkCollisionRecs(firstRect, secondRect)) {
            self.speed.x *= -1;
        }
    }

    pub fn reset(self: *Ball) void {
        self.position = rl.Vector2.init(SCREENWIDTH / 2, SCREENHEIGHT / 2);
    }

    pub fn draw(self: *Ball) void {
        rl.drawRectangleV(self.position, self.size, rl.Color.red);
    }
};

const Paddle = struct {
    position: rl.Vector2,
    size: rl.Vector2,
    speed: f32,

    pub fn init(position: rl.Vector2, size: rl.Vector2, speed: f32) Paddle {
        return Paddle{
            .position = rl.Vector2.init(position.x, position.y),
            .size = rl.Vector2.init(size.x, size.y),
            .speed = speed,
        };
    }

    pub fn update(self: *Paddle) void {
        if (self.position.y <= 0) {
            self.position.y = 0;
        }

        if (self.position.y + self.size.y >= SCREENHEIGHT) {
            self.position.y = SCREENHEIGHT - self.size.y;
        }

        if (rl.isKeyDown(rl.KeyboardKey.up)) {
            self.position.y -= self.speed;
        }

        if (rl.isKeyDown(rl.KeyboardKey.down)) {
            self.position.y += self.speed;
        }
    }

    pub fn followBall(self: *Paddle, ball: *Ball) void {
        // self.position.y = ball.position.y;
        const height = self.position.y + self.size.y / 2;
        const ball_height = ball.position.y + ball.size.y / 2;

        if (ball.position.x >= SCREENWIDTH / @as(f32, 1.6)) {
            if (height > ball_height) {
                self.position.y -= self.speed / 2.7;
            }

            if (height <= ball_height) {
                self.position.y += self.speed / 2.7;
            }
        }

        if (self.position.y <= 0) {
            self.position.y = 0;
        }

        if (self.position.y + self.size.y >= SCREENHEIGHT) {
            self.position.y = SCREENHEIGHT - self.size.y;
        }
    }

    pub fn draw(self: *Paddle) void {
        rl.drawRectangleV(self.position, self.size, rl.Color.white);
    }
};

pub fn main() anyerror!void {
    rl.initWindow(SCREENWIDTH, SCREENHEIGHT, "Pong!");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var ball = Ball.init(SCREENHEIGHT / 2, SCREENHEIGHT / 2, 32, 4);
    var player = Paddle.init(rl.Vector2.init(10, SCREENHEIGHT / 2 - 60), rl.Vector2.init(15, 120), 8);
    var enemy = Paddle.init(rl.Vector2.init(SCREENWIDTH - 35, SCREENHEIGHT / 2 - 60), rl.Vector2.init(15, 120), 8);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();

        rl.drawText(rl.textFormat("%d", .{cpu_score}), SCREENWIDTH / 4 - 20, 20, 80, rl.Color.gold);
        rl.drawText(rl.textFormat("%d", .{player_score}), SCREENWIDTH / 3 - 20, 20, 80, rl.Color.gold);
        defer rl.endDrawing();

        ball.update();
        ball.draw();

        enemy.draw();
        enemy.followBall(&ball);

        player.update();
        player.draw();

        ball.checkCollisions(player);
        ball.checkCollisions(enemy);
        rl.clearBackground(rl.Color.black);
    }
}
