#!/usr/bin/env bash
set -euo pipefail

echo "[1/3] Disable all /sys/class/wakeup/*/device/power/wakeup"
for w in /sys/class/wakeup/wakeup*; do
  p="$w/device/power/wakeup"
  [ -e "$p" ] || continue
  if [ "$(cat "$p" 2>/dev/null || echo n/a)" = "enabled" ]; then
    echo disabled > "$p" || true
  fi
done

echo "[2/3] Disable all enabled entries in /proc/acpi/wakeup"
if [ -r /proc/acpi/wakeup ] && [ -w /proc/acpi/wakeup ]; then
  awk 'NR>1 && $3 ~ /\*enabled/ {print $1}' /proc/acpi/wakeup | while read -r dev; do
    [ -n "$dev" ] || continue
    echo "$dev" > /proc/acpi/wakeup || true
  done
else
  echo "  /proc/acpi/wakeup not writable in this context"
fi

echo "[3/3] Verification"
echo "--- /proc/acpi/wakeup ---"
cat /proc/acpi/wakeup

echo "--- enabled in /sys/class/wakeup ---"
for w in /sys/class/wakeup/wakeup*; do
  p="$w/device/power/wakeup"
  [ -e "$p" ] || continue
  s=$(cat "$p" 2>/dev/null || echo n/a)
  if [ "$s" = "enabled" ]; then
    name=$(cat "$w/name" 2>/dev/null || basename "$w")
    path=$(readlink -f "$w/device" 2>/dev/null || true)
    printf '%s  %s\n' "$name" "$path"
  fi
done
