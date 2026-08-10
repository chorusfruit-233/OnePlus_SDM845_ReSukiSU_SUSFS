# Device syscall regression test

Build the test as a static AArch64 binary and push it to a rooted device:

```sh
aarch64-linux-gnu-gcc -static -O2 -Wall -Wextra \
  -o susfs_syscall_test susfs_syscall_test.c
adb push susfs_syscall_test /data/local/tmp/
adb push run-susfs-regression.sh /data/local/tmp/
adb shell su -c '/data/local/tmp/run-susfs-regression.sh'
```

The default fixture covers `stat`, `open/read`, `access`, `readlink`,
`getdents64`, `rename`, `unlink`, `O_PATH`, `O_TRUNC`, and readable
`/proc/self/mountinfo` and fdinfo fields. Run the same binary from a SUSFS
unmounted app/namespace with `--hidden /path/to/marked-entry` to assert
`ENOENT` for all of those path operations. `--mount-token` and
`--fdinfo-token` optionally assert that the supplied SUS_MOUNT-specific strings
are hidden.
