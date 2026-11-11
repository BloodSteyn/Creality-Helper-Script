#!/bin/sh

set -e

function cfs_kamp_installed() {
  [ -d "$CFS_KAMP_FOLDER" ] && [ -f "$KAMP_FOLDER"/Start_Print.cfg ] && [ ! -L "$KAMP_FOLDER"/Start_Print.cfg ]
}

function cfs_retrude_installed() {
  [ -f "$BOX_CFG" ] && grep -q "^\[gcode_macro pre_cut_box\]" "$BOX_CFG"
}

function entware_git_installed() {
  [ -L "$SYSTEM_GIT_FILE" ] && [ "$(readlink "$SYSTEM_GIT_FILE")" = "$ENTWARE_GIT_FILE" ]
}

function mods_menu_ui_k1() {
  top_line
  title '[ HARDWARE MODS MENU ]' "${yellow}"
  inner_line
  hr
  subtitle '•GANTRY:'
  menu_option ' 1' 'Apply' 'Gantry Profile'
  menu_option ' 2' 'Restore' 'previous gantry configuration'
  hr
  subtitle '•CFS UPGRADE KIT:'
  menu_option ' 3' 'Install' 'Entware Git'
  menu_option ' 4' 'Remove' 'Entware Git'
  menu_option ' 5' 'Install' 'CFS KAMP Integration'
  menu_option ' 6' 'Remove' 'CFS KAMP Integration'
  menu_option ' 7' 'Install' 'CFS Retrude Before Cut'
  menu_option ' 8' 'Remove' 'CFS Retrude Before Cut'
  menu_option ' 9' 'Set' 'CFS Toolhead Positions'
  hr
  inner_line
  hr
  bottom_menu_option 'b' 'Back to [Main Menu]' "${yellow}"
  bottom_menu_option 'q' 'Exit' "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}

function mods_menu_k1() {
  clear
  mods_menu_ui_k1
  local mods_menu_opt
  while true; do
    read -p " ${white}Type your choice and validate with Enter: ${yellow}" mods_menu_opt
    case "${mods_menu_opt}" in
      1)
        run "apply_gantry_profile" "mods_menu_ui_k1";;
      2)
        run "restore_gantry_backup" "mods_menu_ui_k1";;
      3)
        if entware_git_installed; then
          error_msg "Entware Git is already installed!"
        elif [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is needed, please install it first!"
        else
          run "install_entware_git" "mods_menu_ui_k1"
        fi;;
      4)
        if ! entware_git_installed; then
          error_msg "Entware Git is not installed!"
        elif [ ! -e "$SYSTEM_GIT_FILE".bak ]; then
          error_msg "Stock Git backup was not found!"
        else
          run "remove_entware_git" "mods_menu_ui_k1"
        fi;;
      5)
        if ! is_cfs_firmware; then
          error_msg "CFS Upgrade Kit firmware is needed!"
        elif cfs_kamp_installed; then
          error_msg "CFS KAMP Integration is already installed!"
        elif [ ! -d "$KAMP_FOLDER" ]; then
          error_msg "Klipper Adaptive Meshing & Purging is needed, please install it first!"
        else
          run "install_cfs_kamp" "mods_menu_ui_k1"
        fi;;
      6)
        if [ ! -f "$CFS_KAMP_FOLDER"/install.sh ]; then
          error_msg "CFS KAMP Integration is not installed!"
        else
          run "remove_cfs_kamp" "mods_menu_ui_k1"
        fi;;
      7)
        if ! is_cfs_firmware || [ ! -f "$BOX_CFG" ]; then
          error_msg "CFS Upgrade Kit firmware is needed!"
        elif cfs_retrude_installed; then
          error_msg "CFS Retrude Before Cut is already installed!"
        else
          run "install_cfs_retrude" "mods_menu_ui_k1"
        fi;;
      8)
        if ! cfs_retrude_installed; then
          error_msg "CFS Retrude Before Cut is not installed!"
        else
          run "remove_cfs_retrude" "mods_menu_ui_k1"
        fi;;
      9)
        if [ ! -f "$BOX_CFG" ]; then
          error_msg "CFS Upgrade Kit firmware is needed!"
        else
          run "set_cfs_positions" "mods_menu_ui_k1"
        fi;;
      B|b)
        clear; main_menu; break;;
      Q|q)
         clear; exit 0;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
  mods_menu_k1
}
