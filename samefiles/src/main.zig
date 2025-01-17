const std = @import("std");
const crypto = @import("std").crypto;

// computes sha1
pub fn hash(input: []u8) [20]u8 {
    var sha1 = std.crypto.hash.Sha1.init(.{});
    sha1.update(input);

    var digest: [std.crypto.hash.Sha1.digest_length]u8 = undefined;
    sha1.final(&digest);

    return digest;
}

pub fn main() !void {
    // allocator used to concat strings and read files
    const page = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(page);
    defer arena.deinit();

    const allocator = arena.allocator();

    // args to get the path
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <path/to/folder>\n", .{args[0]});
        return;
    }

    const path = args[1];

    // opens the directory
    var dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
    defer dir.close();

    // create hashmap
    var map = std.StringHashMap([]const u8).init(allocator);
    defer map.deinit();

    var dir_iterate = dir.iterate();
    while (try dir_iterate.next()) |dir_content| {
        if (dir_content.kind == .directory) continue;
        if (dir_content.name[0] == '.') continue;

        // concat the strings
        const total_length = path.len + dir_content.name.len + 1;
        const buffer_text = try allocator.alloc(u8, total_length);
        defer allocator.free(buffer_text);
        std.mem.copyForwards(u8, buffer_text[0..path.len], path);
        std.mem.copyForwards(u8, buffer_text[path.len .. path.len + 1], "/");
        std.mem.copyForwards(u8, buffer_text[path.len + 1 ..], dir_content.name);

        const file = try std.fs.cwd().openFile(buffer_text, .{});
        defer file.close();

        const file_size = try file.getEndPos();

        // alloc file
        const buffer = try allocator.alloc(u8, file_size);
        defer allocator.free(buffer);

        _ = try file.readAll(buffer);

        // Compute hash
        const hash_value = hash(buffer);

        // Allocate and persist hash key
        const hash_key = try allocator.alloc(u8, hash_value.len);
        std.mem.copyForwards(u8, hash_key, &hash_value);

        // Allocate and persist file name value
        const name_value = try allocator.alloc(u8, dir_content.name.len);
        std.mem.copyForwards(u8, name_value, dir_content.name);

        // Insert into hashmap
        if (!map.contains(hash_key)) {
            try map.put(hash_key, name_value);
        } else {
            std.debug.print("\x1b[31m{s}\x1b[0m is the same as \x1b[31m{s}\x1b[0m\n", .{ map.get(hash_key).?, dir_content.name });
        }
    }
}
