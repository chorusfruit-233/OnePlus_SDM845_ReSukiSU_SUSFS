#!/system/bin/sh
set -eu

BIN=${1:-/data/local/tmp/susfs_syscall_test}
shift || true

if [ ! -x "$BIN" ]; then
	printf '%s\n' "missing executable: $BIN" >&2
	exit 2
fi

exec "$BIN" "$@"
