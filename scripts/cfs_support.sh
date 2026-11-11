#!/bin/sh

set -e

# Support for the K1 series CFS Upgrade Kit firmware (2.3.5.x).

function entware_git_message(){
  top_line
  title 'Entware Git' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Git provided with the CFS Upgrade Kit firmware is not able   ${white}│"
  echo -e " │ ${cyan}to clone or update GitHub repositories. This replaces it by  ${white}│"
  echo -e " │ ${cyan}the Entware version. Stock version is kept as git.bak.       ${white}│"
  hr
  bottom_line
}

function cfs_kamp_message(){
  top_line
  title 'CFS KAMP Integration' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Community adaptation by cmtergomes that keeps the CFS        ${white}│"
  echo -e " │ ${cyan}loading sequence while KAMP meshes and purges around the     ${white}│"
  echo -e " │ ${cyan}printed objects. Tested by its author with firmware          ${white}│"
  echo -e " │ ${cyan}2.3.5.34 and CFS 1.1.3.                                      ${white}│"
  hr
  bottom_line
}

function cfs_retrude_message(){
  top_line
  title 'CFS Retrude Before Cut' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Mod by FrederickAlt that retracts the filament out of the    ${white}│"
  echo -e " │ ${cyan}heatbreak before cutting it, to reduce the purge waste on    ${white}│"
  echo -e " │ ${cyan}each filament change. It replaces box.cfg and needs slicer   ${white}│"
  echo -e " │ ${cyan}changes (made for OrcaSlicer).                               ${white}│"
  hr
  bottom_line
}

function cfs_positions_message(){
  top_line
  title 'CFS Toolhead Positions' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}This allows to set the positions used by the CFS in box.cfg  ${white}│"
  echo -e " │ ${cyan}file: filament cutter, purge chute and nozzle wiper.         ${white}│"
  echo -e " │ ${cyan}They must be measured again after a gantry conversion.       ${white}│"
  hr
  bottom_line
}

function install_entware_git(){
  entware_git_message
  local yn
  while true; do
    install_msg "Entware Git" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Installing packages..."
        set +e
        "$ENTWARE_FILE" update
        "$ENTWARE_FILE" install ca-bundle git git-http
        set -e
        if [ ! -f "$ENTWARE_GIT_FILE" ]; then
          error_msg "Git installation failed, stock version is unchanged!"
          return
        fi
        echo -e "Info: Linking file..."
        if [ -e "$SYSTEM_GIT_FILE" ] && [ ! -L "$SYSTEM_GIT_FILE" ] && [ ! -e "$SYSTEM_GIT_FILE".bak ]; then
          mv "$SYSTEM_GIT_FILE" "$SYSTEM_GIT_FILE".bak
        fi
        ln -sf "$ENTWARE_GIT_FILE" "$SYSTEM_GIT_FILE"
        if [ -d "$MOONRAKER_FOLDER"/moonraker ]; then
          echo -e "Info: Declaring Moonraker repository as safe..."
          set +e
          if ! "$ENTWARE_GIT_FILE" config --global --get-all safe.directory | grep -q "^$MOONRAKER_FOLDER/moonraker$"; then
            "$ENTWARE_GIT_FILE" config --global --add safe.directory "$MOONRAKER_FOLDER"/moonraker
          fi
          set -e
        fi
        ok_msg "Entware Git has been installed successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_entware_git(){
  entware_git_message
  local yn
  while true; do
    remove_msg "Entware Git" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Restoring stock version..."
        rm -f "$SYSTEM_GIT_FILE"
        mv "$SYSTEM_GIT_FILE".bak "$SYSTEM_GIT_FILE"
        ok_msg "Entware Git has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function install_cfs_kamp(){
  cfs_kamp_message
  if printer_is_busy; then
    error_msg "A print is in progress, please retry when the printer is idle!"
    return
  fi
  local yn
  while true; do
    install_msg "CFS KAMP Integration" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        if [ -d "$CFS_KAMP_FOLDER" ]; then
          rm -rf "$CFS_KAMP_FOLDER"
        fi
        echo -e "Info: Downloading CFS KAMP Integration..."
        set +e
        git clone --depth 1 "$CFS_KAMP_URL" "$CFS_KAMP_FOLDER"
        set -e
        if [ ! -f "$CFS_KAMP_FOLDER"/install.sh ]; then
          rm -rf "$CFS_KAMP_FOLDER"
          error_msg "Download failed!"
          return
        fi
        echo -e "Info: Running CFS KAMP Integration installer..."
        echo
        cd "$CFS_KAMP_FOLDER"
        set +e
        sh ./install.sh install
        local result=$?
        set -e
        cd "$HELPER_SCRIPT_FOLDER"
        if [ $result -ne 0 ] || [ -L "$KAMP_FOLDER"/Start_Print.cfg ]; then
          rm -rf "$CFS_KAMP_FOLDER"
          error_msg "CFS KAMP Integration has not been installed!"
          return
        fi
        ok_msg "CFS KAMP Integration has been installed successfully!"
        echo -e "   In your slicer, enable ${yellow}Label Objects${white} and ${yellow}Exclude Objects${white} settings"
        echo -e "   and leave print calibration disabled when sending a print."
        echo -e "   Stay at the printer for the first print."
        echo
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_cfs_kamp(){
  cfs_kamp_message
  if printer_is_busy; then
    error_msg "A print is in progress, please retry when the printer is idle!"
    return
  fi
  local yn
  while true; do
    remove_msg "CFS KAMP Integration" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Running CFS KAMP Integration rollback..."
        echo
        cd "$CFS_KAMP_FOLDER"
        set +e
        sh ./install.sh rollback
        local result=$?
        set -e
        cd "$HELPER_SCRIPT_FOLDER"
        if [ $result -ne 0 ]; then
          error_msg "Rollback failed, CFS KAMP Integration is still installed!"
          return
        fi
        echo -e "Info: Removing files..."
        rm -rf "$CFS_KAMP_FOLDER"
        ok_msg "CFS KAMP Integration has been removed successfully!"
        echo -e "   gcode_macro.cfg file is back as it was before the installation:"
        echo -e "   apply your Gantry Profile again if it was set after it."
        echo
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function install_cfs_retrude(){
  cfs_retrude_message
  if printer_is_busy; then
    error_msg "A print is in progress, please retry when the printer is idle!"
    return
  fi
  local yn
  while true; do
    install_msg "CFS Retrude Before Cut" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        local box_section="/tmp/hs-box-section.cfg"
        local serial_section="/tmp/hs-serial-section.cfg"
        local new_box="/tmp/hs-box-new.cfg"
        cfg_get_section "$BOX_CFG" "box" > "$box_section"
        if [ ! -s "$box_section" ]; then
          rm -f "$box_section"
          error_msg "[box] configuration was not found in box.cfg file!"
          return
        fi
        if [ -d "$CFS_RETRUDE_FOLDER" ]; then
          rm -rf "$CFS_RETRUDE_FOLDER"
        fi
        echo -e "Info: Downloading CFS Retrude Before Cut..."
        set +e
        git clone --depth 1 "$CFS_RETRUDE_URL" "$CFS_RETRUDE_FOLDER"
        set -e
        if [ ! -f "$CFS_RETRUDE_FOLDER"/box.cfg ] || ! cfg_has_section "$CFS_RETRUDE_FOLDER"/box.cfg "box"; then
          rm -rf "$CFS_RETRUDE_FOLDER"
          rm -f "$box_section"
          error_msg "Download failed!"
          return
        fi
        echo -e "Info: Backing up box.cfg file..."
        mkdir -p "$CFS_RETRUDE_BACKUP_FOLDER"
        cp "$BOX_CFG" "$CFS_RETRUDE_BACKUP_FOLDER"/box.cfg.original
        echo -e "Info: Keeping your [box] configuration in the new box.cfg file..."
        cp "$CFS_RETRUDE_FOLDER"/box.cfg "$new_box"
        cfg_replace_section "$new_box" "box" "$box_section"
        cfg_get_section "$BOX_CFG" "serial_485 serial485" > "$serial_section"
        if [ -s "$serial_section" ] && cfg_has_section "$new_box" "serial_485 serial485"; then
          cfg_replace_section "$new_box" "serial_485 serial485" "$serial_section"
        fi
        cat "$new_box" > "$BOX_CFG"
        rm -f "$box_section" "$serial_section" "$new_box"
        if grep -q -s "^\[save_variables\]" "$KLIPPER_CONFIG_FOLDER"/*.cfg "$HS_CONFIG_FOLDER"/*.cfg; then
          echo -e "Info: [save_variables] configuration is already enabled..."
        else
          echo -e "Info: Adding [save_variables] configuration in printer.cfg file..."
          if [ ! -d "$HS_CONFIG_FOLDER" ]; then
            mkdir -p "$HS_CONFIG_FOLDER"
          fi
          ln -sf "$CFS_RETRUDE_CFG_URL" "$CFS_RETRUDE_FILE"
          sed -i '/\[include printer_params\.cfg\]/a \[include Helper-Script/cfs-retrude\.cfg\]' "$PRINTER_CFG"
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "CFS Retrude Before Cut has been installed successfully!"
        echo -e "   Machine G-code must now be changed in your slicer, instructions are here:"
        echo -e "   ${yellow}https://github.com/FrederickAlt/CREALITY-K1-AND-K1-MAX-CFS-RETRUDE-BEFORE-CUT-MOD${white}"
        echo -e "   Settings of the mod are in ${yellow}[gcode_macro pre_cut_box]${white} in box.cfg file."
        echo -e "   Stay at the printer for the first filament changes."
        echo
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_cfs_retrude(){
  cfs_retrude_message
  if printer_is_busy; then
    error_msg "A print is in progress, please retry when the printer is idle!"
    return
  fi
  if [ ! -f "$CFS_RETRUDE_BACKUP_FOLDER"/box.cfg.original ]; then
    error_msg "Backup of the original box.cfg file was not found!"
    return
  fi
  local yn
  while true; do
    remove_msg "CFS Retrude Before Cut" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        local box_section="/tmp/hs-box-section.cfg"
        echo -e "Info: Restoring original box.cfg file with your current [box] configuration..."
        cfg_get_section "$BOX_CFG" "box" > "$box_section"
        cat "$CFS_RETRUDE_BACKUP_FOLDER"/box.cfg.original > "$BOX_CFG"
        if [ -s "$box_section" ]; then
          cfg_replace_section "$BOX_CFG" "box" "$box_section"
        fi
        rm -f "$box_section"
        echo -e "Info: Removing files..."
        rm -rf "$CFS_RETRUDE_FOLDER"
        rm -f "$CFS_RETRUDE_BACKUP_FOLDER"/box.cfg.original
        if [ -L "$CFS_RETRUDE_FILE" ] || [ -f "$CFS_RETRUDE_FILE" ]; then
          rm -f "$CFS_RETRUDE_FILE"
          sed -i '/include Helper-Script\/cfs-retrude\.cfg/d' "$PRINTER_CFG"
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "CFS Retrude Before Cut has been removed successfully!"
        echo -e "   Do not forget to restore the Machine G-code in your slicer."
        echo
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

# cfs_position_ask <key> <description>
# Asks a new value for <key> of [box] and records it in the list of changes.
function cfs_position_ask() {
  local current answer
  current="$(cfg_get_key "$BOX_CFG" "box" "$1")"
  if [ -z "$current" ]; then
    return 0
  fi
  read -p "   ${white}$2 ${green}$1 ${white}[${yellow}${current}${white}]: ${yellow}" answer
  if [ -n "$answer" ] && [ "$answer" != "$current" ]; then
    CFS_POSITION_CHANGES="${CFS_POSITION_CHANGES}$1=$answer
"
  fi
}

function set_cfs_positions(){
  cfs_positions_message
  if printer_is_busy; then
    error_msg "A print is in progress, please retry when the printer is idle!"
    return
  fi
  if ! cfg_has_section "$BOX_CFG" "box"; then
    error_msg "[box] configuration was not found in box.cfg file!"
    return
  fi
  echo -e " ${white}To measure a position: home the printer, move the toolhead by"
  echo -e " small steps from Fluidd or Mainsail and note X and Y."
  echo -e " The cutter is pressed by moving from ${green}pre_cut_pos${white} to ${green}cut_pos${white}:"
  echo -e " ${green}cut_pos${white} is where the cutter lever is fully pressed on its block."
  echo
  echo -e " Press Enter to keep the value shown in brackets."
  echo
  CFS_POSITION_CHANGES=""
  cfs_position_ask "pre_cut_pos_x" "Before cut"
  cfs_position_ask "pre_cut_pos_y" "Before cut"
  cfs_position_ask "cut_pos_x" "Cut"
  cfs_position_ask "cut_pos_y" "Cut"
  cfs_position_ask "safe_pos_y" "Safe"
  cfs_position_ask "extrude_pos_x" "Purge chute"
  cfs_position_ask "extrude_pos_y" "Purge chute"
  cfs_position_ask "clean_left_pos_x" "Wiper left"
  cfs_position_ask "clean_left_pos_y" "Wiper left"
  cfs_position_ask "clean_right_pos_x" "Wiper right"
  cfs_position_ask "clean_right_pos_y" "Wiper right"
  cfs_position_ask "retrude_position_x" "Unload"
  cfs_position_ask "retrude_position_y" "Unload"
  echo -e "${white}"
  if [ -z "$CFS_POSITION_CHANGES" ]; then
    error_msg "No change to apply!"
    return
  fi
  echo -e " Changes to apply:"
  echo "$CFS_POSITION_CHANGES" | while IFS= read -r change; do
    if [ -n "$change" ]; then
      echo -e "   ${green}${change%%=*}${white}: ${yellow}${change#*=}${white}"
    fi
  done
  echo
  local yn
  while true; do
    read -p "${white} Do you want to apply these ${green}CFS toolhead positions ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        local backup
        backup="$(cfg_backup "$BOX_CFG" "cfs-positions")"
        echo -e "Info: box.cfg saved to ${backup}"
        echo -e "Info: Updating [box] in box.cfg file..."
        echo "$CFS_POSITION_CHANGES" > /tmp/hs-cfs-positions
        while IFS= read -r change; do
          if [ -n "$change" ]; then
            cfg_set_key "$BOX_CFG" "box" "${change%%=*}" "${change#*=}"
          fi
        done < /tmp/hs-cfs-positions
        rm -f /tmp/hs-cfs-positions
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "CFS toolhead positions have been applied successfully!"
        echo -e "   Test with a filament unload from the screen and keep a hand on the"
        echo -e "   power switch: a wrong cut position can crash the toolhead."
        echo
        return;;
      N|n)
        error_msg "Operation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
