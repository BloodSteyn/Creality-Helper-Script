#!/bin/sh

set -e

# Gantry profiles for K1 linear rail conversions.
#
# A profile only describes the travel geometry of the gantry. It never changes
# microsteps, currents or sensorless homing thresholds, so motor tuning already
# present in printer.cfg is kept. rotation_distance is only changed on request,
# when it does not match the 20T pulleys used by linear rail kits.

function gantry_profile_message(){
  top_line
  title 'Gantry Profile' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}This allows to set the X/Y travel, nozzle wipe position,     ${white}│"
  echo -e " │ ${cyan}bed mesh area and input shaper probe point in printer.cfg    ${white}│"
  echo -e " │ ${cyan}and gcode_macro.cfg to match a linear rail gantry.           ${white}│"
  echo -e " │ ${cyan}Motors currents and microsteps settings are not changed.     ${white}│"
  hr
  bottom_line
}

# Sets the GP_* variables for the profile given in $1.
function gantry_profile_load() {
  case "$1" in
    stock)
      GP_NAME="Stock K1 (220x220)"
      GP_X_ENDSTOP="229";   GP_X_MIN="-5";   GP_X_MAX="229"
      GP_Y_ENDSTOP="-0.5";  GP_Y_MIN="-0.5"; GP_Y_MAX="226"
      GP_CLR_X="95";        GP_CLR_Y="221";  GP_CLR_LEN_X="40"; GP_CLR_LEN_Y="2"
      GP_PROBE="110,110,10"
      GP_MESH_MIN="5,5";    GP_MESH_MAX="215,215"
      GP_BED_X="220.0";     GP_BED_Y="220.0";;
    bcj-x)
      GP_NAME="BootyCall Jones X-Axis Linear Rail"
      GP_X_ENDSTOP="226.5"; GP_X_MIN="-2.5"; GP_X_MAX="226.5"
      GP_Y_ENDSTOP="-0.5";  GP_Y_MIN="-0.5"; GP_Y_MAX="204"
      GP_CLR_X="92.5";      GP_CLR_Y="200";  GP_CLR_LEN_X="40"; GP_CLR_LEN_Y="1"
      GP_PROBE="110,110,10"
      GP_MESH_MIN="5,5";    GP_MESH_MAX="215,204"
      GP_BED_X="220.0";     GP_BED_Y="220.0";;
    hdm-235)
      GP_NAME="HDM Full Linear Rail (235x235)"
      GP_X_ENDSTOP="235";   GP_X_MIN="0";    GP_X_MAX="235"
      GP_Y_ENDSTOP="0";     GP_Y_MIN="0";    GP_Y_MAX="235"
      GP_CLR_X="94";        GP_CLR_Y="230";  GP_CLR_LEN_X="40"; GP_CLR_LEN_Y="2"
      GP_PROBE="117.5,117.5,10"
      GP_MESH_MIN="10,10";  GP_MESH_MAX="225,225"
      GP_BED_X="235.0";     GP_BED_Y="235.0";;
    hdm-226)
      GP_NAME="HDM Full Linear Rail (235x226)"
      GP_X_ENDSTOP="235";   GP_X_MIN="0";    GP_X_MAX="235"
      GP_Y_ENDSTOP="0";     GP_Y_MIN="0";    GP_Y_MAX="226"
      GP_CLR_X="94";        GP_CLR_Y="223";  GP_CLR_LEN_X="40"; GP_CLR_LEN_Y="2"
      GP_PROBE="117.5,108.5,10"
      GP_MESH_MIN="10,10";  GP_MESH_MAX="225,215"
      GP_BED_X="235.0";     GP_BED_Y="226.0";;
    *)
      return 1;;
  esac
}

# Loads the values currently set in the configuration files into the GP_* variables.
function gantry_profile_read_current() {
  GP_NAME="Current configuration"
  GP_X_ENDSTOP="$(cfg_get_key "$PRINTER_CFG" "stepper_x" "position_endstop")"
  GP_X_MIN="$(cfg_get_key "$PRINTER_CFG" "stepper_x" "position_min")"
  GP_X_MAX="$(cfg_get_key "$PRINTER_CFG" "stepper_x" "position_max")"
  GP_Y_ENDSTOP="$(cfg_get_key "$PRINTER_CFG" "stepper_y" "position_endstop")"
  GP_Y_MIN="$(cfg_get_key "$PRINTER_CFG" "stepper_y" "position_min")"
  GP_Y_MAX="$(cfg_get_key "$PRINTER_CFG" "stepper_y" "position_max")"
  GP_CLR_X="$(cfg_get_key "$PRINTER_CFG" "prtouch_v2" "clr_noz_start_x")"
  GP_CLR_Y="$(cfg_get_key "$PRINTER_CFG" "prtouch_v2" "clr_noz_start_y")"
  GP_CLR_LEN_X="$(cfg_get_key "$PRINTER_CFG" "prtouch_v2" "clr_noz_len_x")"
  GP_CLR_LEN_Y="$(cfg_get_key "$PRINTER_CFG" "prtouch_v2" "clr_noz_len_y")"
  GP_PROBE="$(cfg_get_probe_points "$PRINTER_CFG")"
  GP_MESH_MIN="$(cfg_get_key "$PRINTER_CFG" "bed_mesh" "mesh_min")"
  GP_MESH_MAX="$(cfg_get_key "$PRINTER_CFG" "bed_mesh" "mesh_max")"
  GP_BED_X="$(cfg_get_key "$MACROS_CFG" "gcode_macro PRINTER_PARAM" "variable_max_x_position")"
  GP_BED_Y="$(cfg_get_key "$MACROS_CFG" "gcode_macro PRINTER_PARAM" "variable_max_y_position")"
}

function gantry_profile_print() {
  echo -e " ${green}${GP_NAME}${white}"
  echo
  echo -e "   [stepper_x]         endstop ${yellow}${GP_X_ENDSTOP}${white} / min ${yellow}${GP_X_MIN}${white} / max ${yellow}${GP_X_MAX}${white}"
  echo -e "   [stepper_y]         endstop ${yellow}${GP_Y_ENDSTOP}${white} / min ${yellow}${GP_Y_MIN}${white} / max ${yellow}${GP_Y_MAX}${white}"
  echo -e "   [prtouch_v2]        nozzle wipe start ${yellow}${GP_CLR_X},${GP_CLR_Y}${white} / length ${yellow}${GP_CLR_LEN_X},${GP_CLR_LEN_Y}${white}"
  echo -e "   [bed_mesh]          ${yellow}${GP_MESH_MIN}${white} to ${yellow}${GP_MESH_MAX}${white}"
  echo -e "   [resonance_tester]  probe point ${yellow}${GP_PROBE}${white}"
  echo -e "   [PRINTER_PARAM]     bed size ${yellow}${GP_BED_X}${white} x ${yellow}${GP_BED_Y}${white}"
  echo
}

# gantry_profile_ask <prompt> <variable name>
# Keeps the current value of the variable when the answer is empty.
function gantry_profile_ask() {
  local answer current
  eval "current=\"\$$2\""
  read -p "   ${white}$1 [${yellow}${current}${white}]: ${yellow}" answer
  if [ -n "$answer" ]; then
    eval "$2=\"\$answer\""
  fi
}

# Asks every value, starting from the values currently in the configuration files.
function gantry_profile_custom() {
  gantry_profile_read_current
  GP_NAME="Custom"
  echo -e "${white}"
  echo -e " Press Enter to keep the value shown in brackets."
  echo
  gantry_profile_ask "stepper_x position_endstop" GP_X_ENDSTOP
  gantry_profile_ask "stepper_x position_min" GP_X_MIN
  gantry_profile_ask "stepper_x position_max" GP_X_MAX
  gantry_profile_ask "stepper_y position_endstop" GP_Y_ENDSTOP
  gantry_profile_ask "stepper_y position_min" GP_Y_MIN
  gantry_profile_ask "stepper_y position_max" GP_Y_MAX
  gantry_profile_ask "Nozzle wipe start X" GP_CLR_X
  gantry_profile_ask "Nozzle wipe start Y" GP_CLR_Y
  gantry_profile_ask "Nozzle wipe length X" GP_CLR_LEN_X
  gantry_profile_ask "Nozzle wipe length Y" GP_CLR_LEN_Y
  gantry_profile_ask "Bed mesh min (x,y)" GP_MESH_MIN
  gantry_profile_ask "Bed mesh max (x,y)" GP_MESH_MAX
  gantry_profile_ask "Input shaper probe point (x,y,z)" GP_PROBE
  gantry_profile_ask "Bed size X" GP_BED_X
  gantry_profile_ask "Bed size Y" GP_BED_Y
  echo -e "${white}"
}

function gantry_profile_write() {
  local backup
  backup="$(cfg_backup "$PRINTER_CFG" "gantry")"
  echo -e "Info: printer.cfg saved to ${backup}"
  backup="$(cfg_backup "$MACROS_CFG" "gantry")"
  echo -e "Info: gcode_macro.cfg saved to ${backup}"
  echo -e "Info: Updating [stepper_x] and [stepper_y] in printer.cfg file..."
  cfg_set_key "$PRINTER_CFG" "stepper_x" "position_endstop" "$GP_X_ENDSTOP"
  cfg_set_key "$PRINTER_CFG" "stepper_x" "position_min" "$GP_X_MIN"
  cfg_set_key "$PRINTER_CFG" "stepper_x" "position_max" "$GP_X_MAX"
  cfg_set_key "$PRINTER_CFG" "stepper_y" "position_endstop" "$GP_Y_ENDSTOP"
  cfg_set_key "$PRINTER_CFG" "stepper_y" "position_min" "$GP_Y_MIN"
  cfg_set_key "$PRINTER_CFG" "stepper_y" "position_max" "$GP_Y_MAX"
  if [ "$GP_SET_ROTATION" = "y" ]; then
    echo -e "Info: Setting rotation_distance to 40 in [stepper_x] and [stepper_y]..."
    cfg_set_key "$PRINTER_CFG" "stepper_x" "rotation_distance" "40"
    cfg_set_key "$PRINTER_CFG" "stepper_y" "rotation_distance" "40"
  fi
  if cfg_has_section "$PRINTER_CFG" "prtouch_v2"; then
    echo -e "Info: Updating nozzle wipe position in printer.cfg file..."
    cfg_set_key "$PRINTER_CFG" "prtouch_v2" "clr_noz_start_x" "$GP_CLR_X"
    cfg_set_key "$PRINTER_CFG" "prtouch_v2" "clr_noz_start_y" "$GP_CLR_Y"
    cfg_set_key "$PRINTER_CFG" "prtouch_v2" "clr_noz_len_x" "$GP_CLR_LEN_X"
    cfg_set_key "$PRINTER_CFG" "prtouch_v2" "clr_noz_len_y" "$GP_CLR_LEN_Y"
  else
    echo -e "Info: [prtouch_v2] is not present in printer.cfg file, nozzle wipe position is skipped..."
  fi
  if cfg_has_section "$PRINTER_CFG" "bed_mesh"; then
    echo -e "Info: Updating [bed_mesh] in printer.cfg file..."
    cfg_set_key "$PRINTER_CFG" "bed_mesh" "mesh_min" "$GP_MESH_MIN"
    cfg_set_key "$PRINTER_CFG" "bed_mesh" "mesh_max" "$GP_MESH_MAX"
  else
    echo -e "Info: [bed_mesh] is not present in printer.cfg file, bed mesh area is skipped..."
  fi
  if cfg_has_section "$PRINTER_CFG" "resonance_tester"; then
    echo -e "Info: Updating [resonance_tester] in printer.cfg file..."
    cfg_set_probe_points "$PRINTER_CFG" "$GP_PROBE"
  fi
  if cfg_has_section "$MACROS_CFG" "gcode_macro PRINTER_PARAM"; then
    echo -e "Info: Updating [gcode_macro PRINTER_PARAM] in gcode_macro.cfg file..."
    cfg_set_key "$MACROS_CFG" "gcode_macro PRINTER_PARAM" "variable_max_x_position" "$GP_BED_X"
    cfg_set_key "$MACROS_CFG" "gcode_macro PRINTER_PARAM" "variable_max_y_position" "$GP_BED_Y"
  else
    echo -e "Info: [gcode_macro PRINTER_PARAM] is not present in gcode_macro.cfg file, bed size is skipped..."
  fi
  mkdir -p "$GANTRY_BACKUP_FOLDER"
  echo "$GP_NAME" > "$GANTRY_PROFILE_FILE"
}

function gantry_profile_notes() {
  local rotation
  rotation="$(cfg_get_key "$PRINTER_CFG" "stepper_x" "rotation_distance")"
  echo -e "   ${white}Next steps:"
  echo -e "   • Home X and Y, then check travel by hand before printing."
  echo -e "   • If homing fails, adjust ${yellow}driver_SGTHRS${white} in [tmc2209 stepper_x/y]."
  echo -e "   • Check the nozzle wipe position matches your silicone wiper."
  echo -e "   • Saved bed meshes belong to the old gantry: run a new bed mesh."
  echo -e "   • Run input shaper calibration again."
  echo -e "   • Set the same build area in your slicer."
  if [ -n "$rotation" ] && [ "$rotation" != "40" ]; then
    echo -e "   • ${yellow}rotation_distance is ${rotation}${white}: 20T pulleys need 40."
  fi
  echo -e "   • Motors other than stock: check ${yellow}run_current${white} and ${yellow}microsteps${white}."
  if is_cfs_firmware; then
    echo -e "   • ${yellow}CFS:${white} cutter, purge and wipe positions in box.cfg are not"
    echo -e "     changed here, set them with the CFS toolhead positions tool."
  fi
  echo
}

function apply_gantry_profile(){
  gantry_profile_message
  if [ ! -f "$PRINTER_CFG" ] || [ ! -f "$MACROS_CFG" ]; then
    error_msg "printer.cfg or gcode_macro.cfg file is missing!"
    return
  fi
  if printer_is_busy; then
    error_msg "A print is in progress, please retry when the printer is idle!"
    return
  fi
  gantry_profile_read_current
  gantry_profile_print
  echo -e " ${white}Available profiles:"
  echo
  echo -e "   ${yellow}1${white}) HDM Full Linear Rail (235x235)"
  echo -e "   ${yellow}2${white}) HDM Full Linear Rail (235x226)"
  echo -e "   ${yellow}3${white}) BootyCall Jones X-Axis Linear Rail"
  echo -e "   ${yellow}4${white}) Stock K1 (220x220)"
  echo -e "   ${yellow}5${white}) Custom values"
  echo -e "   ${yellow}c${white}) Cancel"
  echo
  local profile_opt
  while true; do
    read -p " ${white}Select a profile: ${yellow}" profile_opt
    case "${profile_opt}" in
      1) gantry_profile_load "hdm-235"; break;;
      2) gantry_profile_load "hdm-226"; break;;
      3) gantry_profile_load "bcj-x"; break;;
      4) gantry_profile_load "stock"; break;;
      5) gantry_profile_custom; break;;
      C|c)
        error_msg "Operation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
  echo -e "${white}"
  gantry_profile_print
  local yn rotation
  GP_SET_ROTATION="n"
  rotation="$(cfg_get_key "$PRINTER_CFG" "stepper_x" "rotation_distance")"
  if [ "${profile_opt}" != "4" ] && [ -n "$rotation" ] && [ "$rotation" != "40" ]; then
    echo -e " rotation_distance of X and Y motors is ${yellow}${rotation}${white}. Linear rail kits use"
    echo -e " 20T pulleys which need ${yellow}40${white} (stock pulleys need 72)."
    echo
    while true; do
      read -p "${white} Do you want to set ${green}rotation_distance to 40 ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
      case "${yn}" in
        Y|y) GP_SET_ROTATION="y"; break;;
        N|n) break;;
        *) error_msg "Please select a correct choice!";;
      esac
    done
    echo -e "${white}"
  fi
  while true; do
    read -p "${white} Do you want to apply this ${green}gantry profile ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        gantry_profile_write
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Gantry profile has been applied successfully!"
        gantry_profile_notes
        return;;
      N|n)
        error_msg "Operation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function restore_gantry_backup(){
  gantry_profile_message
  local printer_backup macros_backup
  printer_backup="$(ls -t "$GANTRY_BACKUP_FOLDER"/printer.cfg.* 2>/dev/null | head -n 1)"
  macros_backup="$(ls -t "$GANTRY_BACKUP_FOLDER"/gcode_macro.cfg.* 2>/dev/null | head -n 1)"
  if [ -z "$printer_backup" ] || [ -z "$macros_backup" ]; then
    error_msg "No gantry profile backup found!"
    return
  fi
  if printer_is_busy; then
    error_msg "A print is in progress, please retry when the printer is idle!"
    return
  fi
  echo -e " ${white}Latest backups:"
  echo -e "   ${yellow}${printer_backup}${white}"
  echo -e "   ${yellow}${macros_backup}${white}"
  echo
  local yn
  while true; do
    restore_msg "these configuration files" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Restoring files..."
        cp "$printer_backup" "$PRINTER_CFG"
        cp "$macros_backup" "$MACROS_CFG"
        rm -f "$GANTRY_PROFILE_FILE"
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Configuration files have been restored successfully!"
        return;;
      N|n)
        error_msg "Restoration canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
