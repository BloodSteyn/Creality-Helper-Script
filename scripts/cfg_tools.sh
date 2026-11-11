#!/bin/sh

set -e

# Shared helpers for editing Klipper configuration files by section/key.
# They never touch the auto-generated SAVE_CONFIG block at the end of printer.cfg.

# cfg_get_key <file> <section> <key>
# Prints the value of <key> in [<section>] (trailing comments removed), or nothing.
function cfg_get_key() {
  awk -v sec="[$2]" -v key="$3" '
    /^#\*# <-+ SAVE_CONFIG/ { exit }
    /^\[/ {
      line = $0
      sub(/[ \t]*#.*$/, "", line)
      sub(/[ \t]+$/, "", line)
      insec = (line == sec)
      next
    }
    insec && $0 ~ ("^" key "[ \t]*[:=]") {
      val = $0
      sub(/^[^:=]*[:=][ \t]*/, "", val)
      sub(/[ \t]*#.*$/, "", val)
      sub(/[ \t\r]+$/, "", val)
      print val
      exit
    }
  ' "$1"
}

# cfg_set_key <file> <section> <key> <value>
# Replaces the value of <key> in [<section>], or adds the key if it is missing.
# Returns 1 (file untouched) when the section does not exist.
function cfg_set_key() {
  local file="$1"
  local tmp="$1.hs-tmp"
  if ! cfg_has_section "$file" "$2"; then
    return 1
  fi
  awk -v sec="[$2]" -v key="$3" -v val="$4" '
    function flush() {
      if (insec && !done) { print key ": " val; done = 1 }
    }
    /^#\*# <-+ SAVE_CONFIG/ { flush(); insec = 0; locked = 1 }
    !locked && /^\[/ {
      flush()
      line = $0
      sub(/[ \t]*#.*$/, "", line)
      sub(/[ \t]+$/, "", line)
      insec = (line == sec)
      print
      next
    }
    !locked && insec && !done && $0 ~ ("^" key "[ \t]*[:=]") {
      print key ": " val
      done = 1
      next
    }
    { print }
    END { flush() }
  ' "$file" > "$tmp"
  cat "$tmp" > "$file"
  rm -f "$tmp"
}

# cfg_has_section <file> <section>
function cfg_has_section() {
  awk -v sec="[$2]" '
    /^#\*# <-+ SAVE_CONFIG/ { exit }
    /^\[/ {
      line = $0
      sub(/[ \t]*#.*$/, "", line)
      sub(/[ \t\r]+$/, "", line)
      if (line == sec) { found = 1; exit }
    }
    END { exit(found ? 0 : 1) }
  ' "$1"
}

# cfg_get_section <file> <section>
# Prints the whole [<section>] block, header included.
function cfg_get_section() {
  awk -v sec="[$2]" '
    /^#\*# <-+ SAVE_CONFIG/ { exit }
    /^\[/ {
      line = $0
      sub(/[ \t]*#.*$/, "", line)
      sub(/[ \t\r]+$/, "", line)
      insec = (line == sec)
    }
    insec { print }
  ' "$1"
}

# cfg_replace_section <file> <section> <file containing the new section block>
# Returns 1 (file untouched) when the section does not exist in <file>.
function cfg_replace_section() {
  local file="$1"
  local tmp="$1.hs-tmp"
  if ! cfg_has_section "$file" "$2"; then
    return 1
  fi
  awk -v sec="[$2]" -v newfile="$3" '
    /^\[/ {
      line = $0
      sub(/[ \t]*#.*$/, "", line)
      sub(/[ \t\r]+$/, "", line)
      insec = (line == sec)
      if (insec) {
        while ((getline newline < newfile) > 0) print newline
        close(newfile)
      }
    }
    !insec { print }
  ' "$file" > "$tmp"
  cat "$tmp" > "$file"
  rm -f "$tmp"
}

# cfg_get_probe_points <file>
# Prints the first probe point of [resonance_tester].
function cfg_get_probe_points() {
  awk '
    /^#\*# <-+ SAVE_CONFIG/ { exit }
    /^\[/ { insec = ($0 ~ /^\[resonance_tester\]/); next }
    insec && /^probe_points[ \t]*[:=]/ {
      val = $0
      sub(/^[^:=]*[:=][ \t]*/, "", val)
      sub(/[ \t\r]+$/, "", val)
      if (val != "") { print val; exit }
      want = 1
      next
    }
    insec && want && /^[ \t]+[0-9.-]/ {
      val = $0
      gsub(/[ \t\r]/, "", val)
      print val
      exit
    }
  ' "$1"
}

# cfg_set_probe_points <file> <x,y,z>
# Replaces the probe points of [resonance_tester] with a single point.
function cfg_set_probe_points() {
  local file="$1"
  local tmp="$1.hs-tmp"
  if ! cfg_has_section "$file" "resonance_tester"; then
    return 1
  fi
  awk -v val="$2" '
    function flush() {
      if (insec && !done) { print "probe_points:"; print "   " val; done = 1 }
    }
    /^#\*# <-+ SAVE_CONFIG/ { flush(); insec = 0; locked = 1 }
    !locked && /^\[/ {
      flush()
      insec = ($0 ~ /^\[resonance_tester\]/)
      skipping = 0
      print
      next
    }
    !locked && insec && !done && /^probe_points[ \t]*[:=]/ {
      print "probe_points:"
      print "   " val
      done = 1
      skipping = 1
      next
    }
    skipping && /^[ \t]+[0-9.-]/ { next }
    { skipping = 0; print }
    END { flush() }
  ' "$file" > "$tmp"
  cat "$tmp" > "$file"
  rm -f "$tmp"
}

# cfg_backup <file> <label>
# Copies <file> to the Helper Script backup folder with a timestamp and prints the copy's path.
function cfg_backup() {
  local folder="$HS_BACKUP_FOLDER/$2"
  local name="$(basename "$1").$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$folder"
  cp "$1" "$folder/$name"
  echo "$folder/$name"
}

# printer_is_busy
# Succeeds when Moonraker reports a print that is running or paused.
function printer_is_busy() {
  local state
  state=$("$CURL" -s -m 5 "http://127.0.0.1:7125/printer/objects/query?print_stats=state" 2>/dev/null || true)
  if echo "$state" | grep -q -E '"state": *"(printing|paused)"'; then
    return 0
  fi
  return 1
}

# is_cfs_firmware
# Succeeds on the K1 series CFS Upgrade Kit firmware (2.x, ships Creality's box module).
function is_cfs_firmware() {
  if [ -f "$BOX_CFG" ]; then
    return 0
  fi
  if ls "$KLIPPER_EXTRAS_FOLDER"/box* > /dev/null 2>&1; then
    return 0
  fi
  return 1
}
