#/usr/bin/env bash

TREE_PATH="/media/data/temp/MiSTer_misc_test"
SCRIPT_SUB="Scripts"
MISC_SUB="misc"
PACKAGE_UPDATER_OWNER="pocomane"
PACKAGE_UPDATER_NAME="MiSTer_misc"
# TREE_PATH="/media/fat"
# SCRIPT_SUB="Scripts"
# MISC_SUB="misc"
# PACKAGE_UPDATER_OWNER="pocomane"
# PACKAGE_UPDATER_NAME="MiSTer_misc"

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
  PACKAGE_WORKING_DIR="$TREE_PATH/$MISC_SUB/$PACKAGE_NAME"
  PACKAGE_DEFAULT_SCRIPT="$TREE_PATH/$MISC_SUB/$PACKAGE_NAME/${PACKAGE_NAME}.sh"
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

    # vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    # You can simply run the following command instead of running this file
    #
    curl -L -k https://raw.githubusercontent.com/pocomane/MiSTer_misc/master/util/MiSTer_misc.sh | bash -s update
    #
    # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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

wk_config() {
  wk_show_shortcut > "$SCRIPT_DIR/${PACKAGE_UPDATER_NAME}_update.sh" ||die
  # TODO : other configs ?
}

wk_finish(){
  echo "Done."
}

# PACKAGE LIST
wk_do_for_all() {
  set_project_info ; "wk_$1"
  set_project_info pocomane webkeyboard 'arm.*tar.gz' ; "wk_$1"
  # set_project_info nilp0inter MiSTer_WebMenu 'webmenu.sh' installer ; "wk_$1"
  set_project_info pocomane MiSTer_Batch_Control 'mbc' bare ; "wk_$1"
  # TODO : add ther packages
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

wk_main_dispatch() {
  if [ "$#" = "0" ]; then
    wk_info
  else
    case $1 in

      "update")
         set_project_info
         mkdir -p "$SCRIPT_DIR" ||die "can not create the script directory '$SCRIPT_DIR'"

         if [[ -x "$PACKAGE_DEFAULT_SCRIPT" ]]; then # use the installed Remover if found
           "$PACKAGE_DEFAULT_SCRIPT" remove ||die
           set_project_info
           wk_do_for_all install # it will call wk_install

         else # otherwise fallback to the Remover in this script
           wk_do_for_all remove  # it will call wk_remove
           set_project_info
           wk_do_for_all install # it will call wk_install
         fi
         set_project_info
         echo "Configuring installed packages..."
         "$PACKAGE_DEFAULT_SCRIPT" config ||die
         ;;
      "remove")
         wk_do_for_all remove           # it will call wk_remove
         ;;
      "internal_installer_for_update")
         wk_do_for_all install          # it will call wk_install
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

