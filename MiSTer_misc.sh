#/usr/bin/env bash

MISC_DIR="/media/fat/misc"
LINK_DIR="/media/fat/Scripts"
SCRIPT_DIR="/media/fat/Scripts"
PACKAGE_UPDATER_OWNER="pocomane"
PACKAGE_UPDATER_NAME="MiSTer_misc"
PACKAGE_UPDATER_TYPE="github.master"
ACTION_HOOK="hook/action"
EXPOSE_HOOK="hook/expose"
BOOT_HOOK="hook/boot"
QUICK_HOOK_NAME="__unnamed__"

# DEBUG="true"
# DEBUG_MISC_SUB="/media/data/temp/MiSTer_misc_test/misc"
# DEBUG_LINK_DIR="/media/data/temp/MiSTer_misc_test/Scripts"
# DEBUG_SCRIPT_DIR="/media/data/temp/MiSTer_misc_test/Scripts"

# ---------------------------------------------------------------------------------

TMPFILE="./.download.tmp"
CURL=" curl -L -k "
# TAR=" tar --no-same-owner --no-same-permissions "
TAR=" tar --no-same-owner "
UNZIP=" unzip "

die(){
  echo "ERROR $1"
  exit 127
}

# All the function use the following suffix (from "Updater Script"): us_

us_init() {
  echo ""
}

us_is_default_argument() {
  if [ "$1" = "" -o "$1" = "." ]; then
    return 0 # true when checked in a "if"
  fi
  return 1 # false when checked in a "if"
}

us_set_package_info() {

  if [ "$DEBUG" == "true" ]; then
    MISC_DIR="$DEBUG_MISC_SUB"
    LINK_DIR="$DEBUG_LINK_DIR"
    SCRIPT_DIR="$DEBUG_SCRIPT_DIR"
  fi

  PACKAGE_OWNER="$1"
  PACKAGE_NAME="$2"
  PACKAGE_PATTERN="$3"
  PACKAGE_TYPE="$4"
  PACKAGE_SIMPLENAME="$5"
  
  # Fallback to UPDATER package (the one containing this file) when the first two
  # arguments are empty
  PACKAGE_FALLBACK=""
  if us_is_default_argument "$PACKAGE_OWNER"; then
    if us_is_default_argument "$PACKAGE_NAME"; then
      PACKAGE_FALLBACK="true"
    fi
  fi
  if [ "$PACKAGE_FALLBACK" = "true" ]; then
    PACKAGE_TYPE="$PACKAGE_UPDATER_TYPE"
    PACKAGE_OWNER="$PACKAGE_UPDATER_OWNER"
    PACKAGE_NAME="$PACKAGE_UPDATER_NAME"
  fi

  # Other defaults
  if us_is_default_argument "$PACKAGE_PATTERN"; then
    PACKAGE_PATTERN="$PACKAGE_NAME"
  fi
  if us_is_default_argument "$PACKAGE_TYPE"; then
    PACKAGE_TYPE="gz.tar"
  fi
  if us_is_default_argument "$PACKAGE_SIMPLENAME"; then
    PACKAGE_SIMPLENAME="$PACKAGE_NAME"
  fi

  PACKAGE_REPO_SERVER="https://github.com"
  PACKAGE_REPO_API_SERVER="https://api.github.com/repos"
  PACKAGE_REPO="$PACKAGE_OWNER/$PACKAGE_NAME"
  PACKAGE_REPO_URL="$PACKAGE_REPO_SERVER/$PACKAGE_REPO"
  PACKAGE_REPO_API_URL="$PACKAGE_REPO_API_SERVER/$PACKAGE_REPO"
  PACKAGE_REPO_CONTENT="https://raw.githubusercontent.com/$PACKAGE_OWNER/$PACKAGE_NAME"
  PACKAGE_WORKING_DIR="$MISC_DIR/$PACKAGE_NAME"
  PACKAGE_DEFAULT_SCRIPT_NAME="$PACKAGE_NAME.sh"
  PACKAGE_DEFAULT_SCRIPT="$PACKAGE_WORKING_DIR/$PACKAGE_DEFAULT_SCRIPT_NAME"
  PACKAGE_EXPOSE="$PACKAGE_WORKING_DIR/$EXPOSE_HOOK"
  PACKAGE_ACTION="$PACKAGE_WORKING_DIR/$ACTION_HOOK"
  PACKAGE_BOOT="$PACKAGE_WORKING_DIR/$BOOT_HOOK"
}

us_prepare_folder() {
  if [ "$LINK_DIR" != "" ] ; then
    mkdir -p "$LINK_DIR" ||die "can not create the link directory '$LINK_DIR'"
  fi
  if [ "$SCRIPT_DIR" != "" ] ; then
    mkdir -p "$SCRIPT_DIR" ||die "can not create the script directory '$SCRIPT_DIR'"
  fi
}

us_remove() {
  echo "Removing $PACKAGE_NAME..."

  # Remove links for the exposed hooks
  if [ "$LINK_DIR" != "" ] ; then
    for HOOK in $(ls "$PACKAGE_EXPOSE" 2>/dev/null) ; do
      # Print error when not found, but DO NOT stop the process !
      FULLPATH="$LINK_DIR/${PACKAGE_SIMPLENAME}_$HOOK"
      if [ "$HOOK" = "$QUICK_HOOK_NAME" ] ; then
        FULLPATH="$LINK_DIR/${PACKAGE_SIMPLENAME}"
      fi
      rm "$FULLPATH"
    done
  fi

  # Remove script wrappers for the action hooks
  if [ "$SCRIPT_DIR" != "" ] ; then
    for HOOK in $(ls "$PACKAGE_ACTION" 2>/dev/null) ; do
      # Print error when not found, but DO NOT stop the process !
      FULLPATH="$SCRIPT_DIR/${PACKAGE_SIMPLENAME}_$HOOK"
      if [ "$HOOK" = "$QUICK_HOOK_NAME" ] ; then
        FULLPATH="$SCRIPT_DIR/${PACKAGE_SIMPLENAME}"
      fi
      rm "$FULLPATH"
    done
  fi

  # Remove package content
  rm -fR "$PACKAGE_WORKING_DIR"
}

us_install(){
  echo "Updating $PACKAGE_NAME..."

  mkdir -p "$PACKAGE_WORKING_DIR" ||die "can not create the working directory '$PACKAGE_WORKING_DIR'"
  cd "$PACKAGE_WORKING_DIR" ||die "can not enter in the working direrctory '$PACKAGE_WORKING_DIR'"

  # download
  case $PACKAGE_TYPE in
    "github.master")
      PACK_URL="$PACKAGE_REPO_URL/archive/refs/heads/master.zip"
      ;;
    *)
      PACK_LIST=$($CURL -L -s "$PACKAGE_REPO_API_URL/releases/latest" | grep '"browser_download_url"' | sed 's:.*"\(.*\)"[^"]*:\1:g')
      PACK_URL=$(echo "$PACK_LIST" | grep "$PACKAGE_PATTERN" | head -n 1)
      PACKAGE_INFO="repo '$PACKAGE_REPO_URL' / file '$PACK_URL'"
      ;;
  esac
  $CURL "$PACK_URL" -o "$TMPFILE" ||die "can not download $PACKAGE_INFO"

  # extract
  case $PACKAGE_TYPE in
    "bare")
      # mv "$TMPFILE" "$(echo "$PACK_URL" | sed 's:^.*/::')"
      mv "$TMPFILE" "$PACKAGE_PATTERN"
      ;;
    "uudecode.xz")
      uudecode -o "$TMPFILE.xz" "$TMPFILE" ||die "can not unpack $PACKAGE_INFO"
      rm "$TMPFILE" ||die "can not unpack $PACKAGE_INFO"
      xz --decompress "$TMPFILE.xz" ||die "can not unpack $PACKAGE_INFO"
      cp "$TMPFILE" "$PACKAGE_NAME" ||die "can not unpack $PACKAGE_INFO"
      ;;
    "gz.tar")
      $TAR -xzf "$TMPFILE" ||die "can not unpack $PACKAGE_INFO"
      ;;
    "tar")
      $TAR -xf "$TMPFILE" ||die "can not unpack $PACKAGE_INFO"
      ;;
    "github.master")
      $UNZIP "$TMPFILE" ||die "can not unpack $PACKAGE_INFO"
      SUBNAM="$(ls)"
      mv "$SUBNAM"/* "$SUBNAM"/.[!.]* "$SUBNAM"/..?* . 2> /dev/null
      rmdir "$SUBNAM" ||die "can not unpack $PACKAGE_INFO"
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
echo "#!/usr/bin/env bash"
if [ "$SHORTCUT_INFO" != "" ] ;then
  echo -e "\n# $SHORTCUT_INFO\n"
fi
cat << EOF

  # Test internet
  ping -c 1 www.google.com > /dev/null
  if [ "\$?" != "0" ]; then
    echo "Network not found: check your internet connection or try later"
    exit 126
  fi

  # vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  # You can simply run the following command instead of running this file
  #
  curl -L -k "$PACKAGE_REPO_CONTENT/master/$PACKAGE_DEFAULT_SCRIPT_NAME" | bash -s update
  #
  # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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
  "$1" \$@
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
  echo "Configuring $PACKAGE_NAME..."

  if us_is_updater_package; then
    # This is done with a wrapper for other packages, however the Updater is
    # an exception since the "Shortcut" MUST work also withou any installation)
    if [ "$SCRIPT_DIR" != "" ] ; then
      us_show_shortcut > "$SCRIPT_DIR/${PACKAGE_NAME}_update.sh" ||die
    fi
  else

    # Add link for the exposed hooks
    if [ "$LINK_DIR" != "" ] ; then
      for HOOK in $(ls "$PACKAGE_EXPOSE" 2>/dev/null) ; do
        FULLPATH="$LINK_DIR/${PACKAGE_SIMPLENAME}_$HOOK" ||die
        if [ "$HOOK" = "$QUICK_HOOK_NAME" ] ; then
          FULLPATH="$LINK_DIR/${PACKAGE_SIMPLENAME}" ||die
        fi
        ln -s "$PACKAGE_EXPOSE/$HOOK" "$FULLPATH" ||die
      done
    fi

    # Add script wrappers for the action hooks
    if [ "$SCRIPT_DIR" != "" ] ; then
      for HOOK in $(ls "$PACKAGE_ACTION" 2>/dev/null) ; do
        FULLPATH="$SCRIPT_DIR/${PACKAGE_SIMPLENAME}_$HOOK" ||die
        if [ "$HOOK" = "$QUICK_HOOK_NAME" ] ; then
          FULLPATH="$SCRIPT_DIR/${PACKAGE_SIMPLENAME}" ||die
        fi
        us_generate_wrapper "$PACKAGE_ACTION/$HOOK" > "$FULLPATH" ||die
      done
    fi
  fi

  # TODO : other configs ? boot hooks ?
}

us_finish(){
  echo "Done."
}

us_package_do() {
  ACTION="$1"
  shift

  # This will fallback to the UPDATER package (i.e. the one containing this
  # file) when no other parameter are given
  us_set_package_info $@

  case $ACTION in
    "install")
      us_install
      ;;
    "remove")
      us_remove
      ;;
    "config")
      us_config
      ;;
    *)
      echo "Invalid action '$1'"
      exit -1;
      ;;
  esac
}

# PACKAGE LIST
us_do_for_other() {
  us_package_do "$1" pocomane webkeyboard 'arm.*tar.gz'
  us_package_do "$1" pocomane MiSTer_Batch_Control 'mbc.tar.gz' . 'mbc'
  us_package_do "$1" nilp0inter MiSTer_WebMenu 'webmenu.sh' uudecode.xz
  us_package_do "$1" pocomane MiSTer_webmenu_package . . 'webmenu'
  # TODO : add ther packages
}

us_do_for_updater() {
  us_package_do "$1"
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

  if [ "$DEBUG" == "true" ]; then
    # for debug: use current script to install packages
    us_main_dispatch $@
  else
    # for release: use the downloaded script to install packages
    "$PACKAGE_DEFAULT_SCRIPT" $@ ||die
  fi
}

us_main_dispatch() {
  if [ "$#" = "0" ]; then
    us_info
  else
    case $1 in

      "update")
         us_set_package_info
         us_prepare_folder

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
         SHORTCUT_INFO="This file was generated by '$0 $@'"
         us_show_shortcut
         SHORTCUT_INFO=""
         exit 0 # skip the ending summary so the result can be store in a script without any changes
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

