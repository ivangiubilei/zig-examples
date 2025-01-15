const std = @import("std");

const KEY = 0b10100111;

pub fn encrypt(allocator: std.mem.Allocator, path: []const u8) !void {
    // read file
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const file_contents = try allocator.alloc(u8, file_size);
    defer allocator.free(file_contents);
    _ = try file.readAll(file_contents);

    var encrypted: []u8 = try allocator.alloc(u8, file_size);
    defer allocator.free(encrypted);
    for (file_contents, 0..) |byte, i| {
        encrypted[i] = byte ^ KEY;
    }

    // concat .encrypted to file
    const end_file = ".encrypted";
    var complete_path = try allocator.alloc(u8, path.len + end_file.len);
    defer allocator.free(complete_path);

    std.mem.copyForwards(u8, complete_path[0..path.len], path);
    std.mem.copyForwards(u8, complete_path[path.len..], end_file);

    // create new encrypted file
    const created_file = try std.fs.cwd().createFile(complete_path, .{});
    _ = try created_file.write(encrypted);
}

pub fn decrypt(allocator: std.mem.Allocator, path: []const u8) !void {
    // read file that ends with ".encrypted"
    const end_file_enc = ".encrypted";
    var complete_path_enc = try allocator.alloc(u8, path.len + end_file_enc.len);
    defer allocator.free(complete_path_enc);

    std.mem.copyForwards(u8, complete_path_enc[0..path.len], path);
    std.mem.copyForwards(u8, complete_path_enc[path.len..], end_file_enc);

    const file = try std.fs.cwd().openFile(complete_path_enc, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const file_contents = try allocator.alloc(u8, file_size);
    defer allocator.free(file_contents);
    _ = try file.readAll(file_contents);

    // decrypt
    var decrypted: []u8 = try allocator.alloc(u8, file_size);
    defer allocator.free(decrypted);
    for (file_contents, 0..) |byte, i| {
        decrypted[i] = byte ^ KEY;
    }

    // concat .decrypted to file
    const end_file_dec = ".decrypted";
    var complete_path_dec = try allocator.alloc(u8, path.len + end_file_dec.len);
    defer allocator.free(complete_path_dec);

    std.mem.copyForwards(u8, complete_path_dec[0..path.len], path);
    std.mem.copyForwards(u8, complete_path_dec[path.len..], end_file_dec);

    // create new encrypted file
    const created_file = try std.fs.cwd().createFile(complete_path_dec, .{});
    _ = try created_file.write(decrypted);
}

pub fn main() !void {
    // TODO: add command line arguments to decided to encrypt or decrypt + path
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const path = "./src/test.txt";
    try encrypt(allocator, path);
    try decrypt(allocator, path);
}
