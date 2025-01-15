I made this simple project to practice zig.

# xorcipher

The program encrypts the provided file by performing a bitwise XOR operation on each byte with a specific key (hardcoded).

## Compiling

```
zig build
```

you can find the executable in **zig-out/bin**

## Usage

```
./xorcipher path/to/file [e|d]
```
- **e** appends .encrypted after the extension
- **d** appends .decrypted after the extension
