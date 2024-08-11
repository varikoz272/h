echo "[REQUIRMENTS] zig-0.12.0"
echo "[REQUIRMENTS] pthread.h (might be missing on Windows)"
zig build -Doptimize=ReleaseSafe
