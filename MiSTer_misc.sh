#/usr/bin/env bash

# TREE_PATH="/media/fat"
TREE_PATH="/media/data/temp/MiSTer_misc_test"
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

wk_init() {
  echo ""
}

set_project_info() {

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

wk_remove() {
  echo "Removing $PACKAGE_NAME..."
  rm -fR "$PACKAGE_WORKING_DIR"
}

wk_install(){
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

wk_show_shortcut() {
cat << EOF
#!/usr/bin/env bash

  # Test internet
  ping -c 1 www.google.com > /dev/null
  if [ "\$?" != "0" ]; then
    echo "Network not found: check your internet connection or try later"
    exit 126
  fi

  if [[ -x "$PACKAGE_WORKING_DIR/$PACKAGE_UPDATER_NAME" ]]; then
    "$PACKAGE_WORKING_DIR/$PACKAGE_UPDATER_NAME" update
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

wk_generate_wrapper() {
cat << EOF
#!/usr/bin/env bash
  cd "$PACKAGE_WORKING_DIR" || exit 127
  "$1" || exit 127
EOF
}

wk_config() {

  # Automatic generation of the updater script to be linked in the SCRIPT_DIR folder
  if [ "$PACKAGE_OWNER" = "$PACKAGE_UPDATER_OWNER" -a "$PACKAGE_NAME" = "$PACKAGE_UPDATER_NAME" ]; then
    mkdir -p "$PACKAGE_ACTION"
    wk_show_shortcut > "$PACKAGE_ACTION/update.sh" ||die
  fi

  # Add action hooks in the Script dir
  for HOOK in $(ls "$PACKAGE_ACTION") ; do
    wk_generate_wrapper "$PACKAGE_ACTION/$HOOK" > "$SCRIPT_DIR/${PACKAGE_NAME}_$HOOK.sh" ||die
  done

  # TODO : boot hooks ?

  # TODO : other configs ?
}

wk_finish(){
  echo "Done."
}

wk_package_do() {
  ACTION="$1"
  shift
  set_project_info $@
  "wk_$ACTION"
}

# PACKAGE LIST
wk_do_for_other() {
  wk_package_do "$1" pocomane webkeyboard 'arm.*tar.gz'
  wk_package_do "$1" pocomane MiSTer_Batch_Control 'mbc' bare
  # wk_package_do "$1" nilp0inter MiSTer_WebMenu 'webmenu.sh' installer
  # TODO : add ther packages
}

wk_do_for_updater() {
  wk_package_do "$1" # This will fallback to the UPDATER package (i.e. the one containing this file)
}

wk_do_for_all() {
  wk_do_for_updater $1
  wk_do_for_other $1
}

wk_info(){
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

wk_is_updater_installed() {
  set_project_info
  if [[ -x "$PACKAGE_DEFAULT_SCRIPT" ]]; then
    return 0 # true when checked in a "if"
  fi
  return 1 # false when checked in a "if"
}

wk_run_installed_updater() {
  set_project_info

  # For release
  "$PACKAGE_DEFAULT_SCRIPT" $@ ||die

  # For development
  # wk_main_dispatch $@
}

wk_main_dispatch() {
  if [ "$#" = "0" ]; then
    wk_info
  else
    case $1 in

      "update")
         set_project_info
         mkdir -p "$SCRIPT_DIR" ||die "can not create the script directory '$SCRIPT_DIR'"

         if wk_is_updater_installed; then
           wk_run_installed_updater remove
         else
           wk_do_for_all remove  # it will call wk_remove
         fi

         wk_do_for_updater install
         wk_run_installed_updater internal_installer_for_update
         ;;
      "remove")
         wk_do_for_all remove           # it will call wk_remove
         ;;
      "internal_installer_for_update")
         wk_do_for_other install          # it will call wk_install
         ;;
      "config")
         wk_do_for_all config           # it will call wk_config
         ;;
      "show_shortcut")
         set_project_info
         wk_show_shortcut
         ;;
      *)
         echo "Invalid option"
         wk_info
         false ||die "invalid option"
         ;;
    esac
  fi
}

wk_init
wk_main_dispatch $@
wk_finish

