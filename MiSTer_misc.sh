#/usr/bin/env bash

TREE_PATH="/media/fat"
# TREE_PATH="/media/data/temp/MiSTer_misc_test"
SCRIPT_SUB="Scripts"
MISC_SUB="misc"
PACKAGE_UPDATER_OWNER="pocomane"
PACKAGE_UPDATER_NAME="MiSTer_misc"
HOOK_SUB="hook"
ACTION_HOOK="action"
BOOT_HOOK="boot"

# ---------------------------------------------------------------------------------

TMPFILE="./.download.tmp"
CURL=" curl -L -k -s "
# TAR=" tar --no-same-owner --no-same-permissions "
TAR=" tar --no-same-owner "

die(){
  echo "ERROR $1"
  exit 127
}

# All the function use the following suffix (from "Updater Script"): us_

us_init() {
  echo ""
}

us_set_package_info() {

  PACKAGE_OWNER="$1"
  PACKAGE_NAME="$2"
  PACKAGE_PATTERN="$3"
  PACKAGE_TYPE="$4"
  
  # Fallback to UPDATER package (the one containing this file)
  if [ "$PACKAGE_OWNER" = "" ]; then
    PACKAGE_OWNER="$PACKAGE_UPDATER_OWNER"
  fi
  if [ "$PACKAGE_NAME" = "" ]; then
    PACKAGE_NAME="$PACKAGE_UPDATER_NAME"
  fi

  if [ "$PACKAGE_PATTERN" = "" ]; then
    PACKAGE_PATTERN="$PACKAGE_NAME"
  fi
  
  if [ "$PACKAGE_TYPE" = "" ]; then
    PACKAGE_TYPE="tgz"
  fi
  
  SCRIPT_DIR="$TREE_PATH/$SCRIPT_SUB"

  PACKAGE_REPO="$PACKAGE_OWNER/$PACKAGE_NAME"
  PACKAGE_REPO_URL="https://github.com/$PACKAGE_REPO"
  PACKAGE_REPO_API="https://api.github.com/repos/$PACKAGE_REPO"
  PACKAGE_REPO_CONTENT="https://raw.githubusercontent.com/$PACKAGE_OWNER/$PACKAGE_NAME"
  PACKAGE_WORKING_DIR="$TREE_PATH/$MISC_SUB/$PACKAGE_NAME"
  PACKAGE_DEFAULT_SCRIPT_NAME="$PACKAGE_NAME.sh"
  PACKAGE_DEFAULT_SCRIPT="$PACKAGE_WORKING_DIR/$PACKAGE_DEFAULT_SCRIPT_NAME"
  PACKAGE_ACTION="$PACKAGE_WORKING_DIR/$HOOK_SUB/$ACTION_HOOK"
  PACKAGE_BOOT="$PACKAGE_WORKING_DIR/$HOOK_SUB/$BOOT_HOOK"
}

us_remove() {
  echo "Removing $PACKAGE_NAME..."
  rm -fR "$PACKAGE_WORKING_DIR"
}

us_install(){
  echo "Updating $PACKAGE_NAME..."

  mkdir -p "$PACKAGE_WORKING_DIR" ||die "can not create the working directory '$PACKAGE_WORKING_DIR'"
  cd "$PACKAGE_WORKING_DIR" ||die "can not enter in the working direrctory '$PACKAGE_WORKING_DIR'"

  # download
  PACK_LIST=$($CURL -L -s $PACKAGE_REPO_API/releases/latest | sed -ne 's|^[ "]*browser_download_url[ "]*:[ "]*\([^"]*\)[ ",\t]*$|\1|p')
  PACK_URL=$(echo "$PACK_LIST" | grep "$PACKAGE_PATTERN" | head -n 1)
  PACKAGE_INFO="repo '$PACKAGE_REPO_URL' / file '$PACK_URL'"
  $CURL "$PACK_URL" -o "$TMPFILE" ||die "can not download $PACKAGE_INFO"

  # extract
  case $PACKAGE_TYPE in
    "bare")
      echo -n "" # nothing to do
      ;;
    "installer")
      "$TMPFILE"
      ;;
    "tgz")
      $TAR -xzf "$TMPFILE" ||die "can not unpack $PACKAGE_INFO"
      ;;
    "tar")
      $TAR -xf "$TMPFILE" ||die "can not unpack $PACKAGE_INFO"
      ;;
    *)
      false ||die "unsupported package type"
      ;;
  esac

  if [ "$?" != "0" ]; then
    false ||die "Installation failed"
  fi
  
  rm -f "$TMPFILE"
}

us_show_shortcut() {
cat << EOF
#!/usr/bin/env bash

  # Test internet
  ping -c 1 www.google.com > /dev/null
  if [ "\$?" != "0" ]; then
    echo "Network not found: check your internet connection or try later"
    exit 126
  fi

  if [[ -x "$PACKAGE_WORKING_DIR/$PACKAGE_DEFAULT_SCRIPT_NAME" ]]; then
    "$PACKAGE_WORKING_DIR/$PACKAGE_DEFAULT_SCRIPT_NAME" update
  else

    # vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    # You can simply run the following command instead of running this file
    #
    curl -L -k "$PACKAGE_REPO_CONTENT/master/$PACKAGE_DEFAULT_SCRIPT_NAME" | bash -s update
    #
    # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

  fi

  X=("\${PIPESTATUS[@]}")
  EXIT_CODE=\${X[0]}
  if [ "\$EXIT_CODE" = "0" ]; then
    EXIT_CODE=\${X[1]}
  fi
  if [ "\$EXIT_CODE" != "0" ]; then
    echo "Error downloading the package (\$EXIT_CODE)"
  fi

  read -n 1 -s -r -p "Press any key to continue"
  echo ""
  exit \$EXIT_CODE
EOF
}

us_generate_wrapper() {
cat << EOF
#!/usr/bin/env bash
  cd "$PACKAGE_WORKING_DIR"
  "$1"
  EXIT_CODE="\$?"
  read -n 1 -s -r -p "Press any key to continue"
  echo ""
  exit \$EXIT_CODE
EOF
}

us_is_updater_package(){
  if [ "$PACKAGE_OWNER" = "$PACKAGE_UPDATER_OWNER" -a "$PACKAGE_NAME" = "$PACKAGE_UPDATER_NAME" ]; then
    return 0 # true when checked in a "if"
  fi
  return 1 # false when checked in a "if"
}

us_config() {

  if us_is_updater_package; then
    # This is done with a wrapper for other packages, however the Updater is
    # an exception since the "Shortcut" MUST work also withou any installation)
    us_show_shortcut > "$SCRIPT_DIR/${PACKAGE_NAME}_updater.sh" ||die
  else

    # Add action hooks in the Script dir
    for HOOK in $(ls "$PACKAGE_ACTION" 2>/dev/null) ; do
      us_generate_wrapper "$PACKAGE_ACTION/$HOOK" > "$SCRIPT_DIR/${PACKAGE_NAME}_$HOOK" ||die
    done
  fi

  # TODO : other configs ? boot hooks ?
}

us_finish(){
  echo "Done."
}

us_package_do() {
  ACTION="$1"
  shift
  us_set_package_info $@
  "us_$ACTION"
}

# PACKAGE LIST
us_do_for_other() {
  us_package_do "$1" pocomane webkeyboard 'arm.*tar.gz'
  us_package_do "$1" pocomane MiSTer_Batch_Control 'mbc' bare
  # us_package_do "$1" nilp0inter MiSTer_WebMenu 'webmenu.sh' installer
  # TODO : add ther packages
}

us_do_for_updater() {
  us_package_do "$1" # This will fallback to the UPDATER package (i.e. the one containing this file)
}

us_do_for_all() {
  us_do_for_updater $1
  us_do_for_other $1
}

us_info(){
  echo "Usage Summary."
  echo "To download and update the software:"
  echo "  $0 update"
  echo "To remove the software:"
  echo "  $0 remove"
  echo "To configure the software:"
  echo "  $0 config"
  echo "To view a simple Updater Shortcut script:"
  echo "  $0 show_shortcut"
}

us_is_updater_installed() {
  us_set_package_info
  if [[ -x "$PACKAGE_DEFAULT_SCRIPT" ]]; then
    return 0 # true when checked in a "if"
  fi
  return 1 # false when checked in a "if"
}

us_run_installed_updater() {
  us_set_package_info

  # For release
  "$PACKAGE_DEFAULT_SCRIPT" $@ ||die

  # For development
  # us_main_dispatch $@
}

us_main_dispatch() {
  if [ "$#" = "0" ]; then
    us_info
  else
    case $1 in

      "update")
         us_set_package_info
         mkdir -p "$SCRIPT_DIR" ||die "can not create the script directory '$SCRIPT_DIR'"

         if us_is_updater_installed; then
           us_run_installed_updater remove
         else
           us_do_for_all remove  # it will call us_remove
         fi

         us_do_for_updater install
         us_run_installed_updater internal_installer_for_update
         ;;
      "remove")
         us_do_for_all remove           # it will call us_remove
         ;;
      "internal_installer_for_update")
         us_do_for_other install          # it will call us_install
         us_do_for_all config           # it will call us_config
         ;;
      "config")
         us_do_for_all config           # it will call us_config
         ;;
      "show_shortcut")
         us_set_package_info
         us_show_shortcut
         ;;
      *)
         echo "Invalid option"
         us_info
         false ||die "invalid option"
         ;;
    esac
  fi
}

us_init
us_main_dispatch $@
us_finish

