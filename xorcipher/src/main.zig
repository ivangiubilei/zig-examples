const std = @import("std");

const KEY = 0b10100111;

pub fn encryptDecrypt(allocator: std.mem.Allocator, path: []const u8, extension: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const file_contents = try allocator.alloc(u8, file_size);
    defer allocator.free(file_contents);
    _ = try file.readAll(file_contents);

    // decrypt
    var decrypted_encrypted: []u8 = try allocator.alloc(u8, file_size);
    defer allocator.free(decrypted_encrypted);
    for (file_contents, 0..) |byte, i| {
        decrypted_encrypted[i] = byte ^ KEY;
    }

    // concat .decrypted to file
    const end_file = extension;
    var complete_path = try allocator.alloc(u8, path.len + end_file.len);
    defer allocator.free(complete_path);

    std.mem.copyForwards(u8, complete_path[0..path.len], path);
    std.mem.copyForwards(u8, complete_path[path.len..], end_file);

    // create new encrypted file
    const created_file = try std.fs.cwd().createFile(complete_path, .{});
    _ = try created_file.write(decrypted_encrypted);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer std.debug.print("{}", .{gpa.deinit()});
    const allocator = gpa.allocator();

    // args to get the path
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 3 or (!std.mem.eql(u8, args[2], "e") and !std.mem.eql(u8, args[2], "d"))) {
        std.debug.print("Usage: {s} <path/to/file/> [e|d]\n", .{args[0]});
        return;
    }

    const path = args[1];

    const extension = if (std.mem.eql(u8, args[2], "e")) ".encrypted" else ".decrypted";

    try encryptDecrypt(allocator, path, extension);
}
