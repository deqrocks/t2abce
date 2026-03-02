#!/usr/bin/env bash
set -euo pipefail

OUT="$HOME/apple-bce-logs/$(date +%F_%H%M%S)"
mkdir -p "$OUT"

# 1) Full kernel log (current boot)
journalctl -k -b -o short-monotonic > "$OUT/kernel_boot_monotonic.log"

# 2) Focused filter used for BCE/VHCI resume triage
journalctl -k -b -o short-monotonic \
  | rg -n "PM: suspend entry|PM: Waking up|bce_vhci|apple-bce|aaudio|hci_bcm4377|brcmfmac|usbhid|hid|USB disconnect|xhci|HC died|command timed out|resume port|resume endpoints|No queued item found for tag|RTI status invalid" \
  > "$OUT/kernel_focus.log"

# 3) Resume window around the latest wakeup marker
wake_line=$(rg -n "ACPI: PM: Waking up from system sleep state S3" "$OUT/kernel_boot_monotonic.log" | tail -n1 | cut -d: -f1 || true)
if [[ -n "${wake_line:-}" ]]; then
  start=$((wake_line - 120)); (( start < 1 )) && start=1
  end=$((wake_line + 900))
  sed -n "${start},${end}p" "$OUT/kernel_boot_monotonic.log" > "$OUT/resume_window.log"
fi

# 4) Failure window around first BCE/USB resume failure marker
fail_line=$(rg -n "bce_vhci: resume port .* failed|HC died; cleaning up|failed to resume async" "$OUT/kernel_boot_monotonic.log" | head -n1 | cut -d: -f1 || true)
if [[ -n "${fail_line:-}" ]]; then
  s=$((fail_line - 120)); (( s < 1 )) && s=1
  e=$((fail_line + 500))
  sed -n "${s},${e}p" "$OUT/kernel_boot_monotonic.log" > "$OUT/failure_window.log"
fi

# 5) Current runtime state snapshots
lsusb -t > "$OUT/lsusb_t.txt"
ls /sys/bus/usb/devices | sort > "$OUT/usb_devices_all.txt"
ls /sys/bus/usb/devices | rg '^5-' | sort > "$OUT/usb_devices_bus5.txt"
lsmod | rg -n "apple_bce|hci_bcm4377|brcmfmac|aaudio|bluetooth" > "$OUT/modules_focus.txt"

# 6) Optional full journal of current boot
journalctl -b -o short-monotonic > "$OUT/journal_boot_monotonic.log"

# 7) Bundle archive
tar -C "$(dirname "$OUT")" -czf "$OUT.tar.gz" "$(basename "$OUT")"

echo "Saved to: $OUT"
echo "Archive : $OUT.tar.gz"
