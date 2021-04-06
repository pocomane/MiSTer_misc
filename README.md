
# MiSTer_misc

This is a script to install and update miscellaneous software on a target device.
The default distribution is meant to be used on a MiSTer FPGA, however it is
designed to be easly adapted to other systems. Read the dedicated section to more
information on such scenarios, the rest of this documentation will assume a
MiSTer FPGA target with default miscellaneous software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

# Features

The features of the script are:

- It is very simple: you can read and fully understand it in minutes
- The packages are distributed as github repository
- It automatically creates links and wrapper scripts to recall package functionality
- It keeps the filesystem clean: all the software is installed the `/media/fat/misc` folder
- TODO : automatic boot script ! ?

# Installation

To install or update all the software, you can download the
[MiSTer_misc_update.sh](https://raw.githubusercontent.com/pocomane/MiSTer_misc/master/MiSTer_misc_update.sh)
to your device and run it. Alternatively you can run

```
curl -L -k "https://raw.githubusercontent.com/pocomane/MiSTer_misc/master/MiSTer_misc.sh" | bash -s update
```

in a shell on the target device.

Both the methods will download the last script from the repo and install it in the
default path: `/media/fat/misc/MiSTer_misc`. It will also generate some script 
in the default path: `/media/fat/Scripts`. One of this is the updater script
itself: `/media/fat/Scripts/MiSTer_misc_update.sh`.

# Contained software

This is a list of the software that will be installed.

- [webkeyboard](https://github.com/pocomane/webkeyboard) - It let you to
  control the device from a remote keyboard. The scripts
  `webkeyboard_start.sh` and `webkeyboard_stop.sh` will be created to launch
  and stop the service. Connect http://ip.addes.of_the.device:8081 from any
  computer in the network to send keystroks through the web.
- [webmenu with wrapper](https://github.com/pocomane/MiSTer_webmenu_package) - It
  is a GUI served as a web-page. Connecting a browser from any computer to it, you
  can launch core and roms, search your collection, etc. The script
  `webmenu_start.sh` and `webmenu_stop.sh` will be created to start/stop the
  app.
- [mbc](https://github.com/pocomane/MiSTer_Batch_Control) - It is an utility to
  control the MiSTer from the command line (e.g. launch a rom).

# How it works

The script is very simple. It just download a list of software from the github
repos (defined by the owner and its name) into an `Installation` directory. In
case there is already something in such directory, it first remove it, so it
always got the latest revision. Each package will be placed in the sub-folder of
the `Installation` one with the same name of the package.

The list of packages to download, with their `repo_type` and `package_name` can
be quickly changed in the script, as described in the following sections. The
`repo_type` defines how download the software from it.

For each installed software, some functionality script are linked in the
`Scripts` and `Links` directories to be easly recalled. The difference between
the two directories is that the `Links` will contain proper links, while the
`Scripts` one will contain wrapper script that perform some auxiliary work (
change the current dir, and wait a keypress at the end).

TODO : implement automatic boot script ! ?

# Adapt the script to other devices

To adapt the script to other device and software, you can fork this repo, and
change the following variables in the main script

- PACKAGE_UPDATER_OWNER and NAME define the github repo of the owner of the
  uptade script itself; you should place here you github username (in OWNER)
  and forked repo name (in NAME);
- MISC_DIR defines the `Installation` directory, where the software will be
  copied;
- SCRIPT_DIR defines the path for the `Scripts` folder; an empty value will
  disable the creation of the script wrappers;
- LINK_DIR defines the path for the `Links` folder; an empty value will disable
  the creation of the links;

You can also change the following variables for some advanced configuration
(some of them tweaks the package specification, so refer to the relative
section for more details):

- PACKAGE_UPDATER_TYPE is the type of repo containing the updater script itself;
  (the default "github.master" should be good for most of the scenarios, see next
  section for other options):
- EXPOSE_HOOK specifies which subfolder in a package contains the scripts to be
  place in the `Links` folder;
- ACTION_HOOK specifies which subfolder in a package contains the scripts to be
  wrapped in `Scripts` directory;
- BOOT_HOOK si not implemented yet ! ? ;
- QUICK_HOOK_NAME contains the name of the script that will be linked with the
  same name of the package (default is `__unnamed__`, wihout any extension)

After that you have to find the package list definition function: just search
for `PACKAGE LIST` to find it. You have to clean-up the function and refill it
with the list of the packages you want to include. The exact syntax is defined
in the next section, in general each package must correspond to a github repo.

Finally you can regenerate the shortcut script with

```
./MiSTer_misc.sh show_shortcut > MiSTer_misc_update.sh
```

Obviously you can rename the scripts as you wish.

# Package Specification

As said in the previous sections, in the script there is a list of package to
install. Each line define one package. The general sintax is:

```
us_package_do "$1" github_user github_repo opt_pattern repo_type package_name
```

The first two terms must be always the same. Then there is the user name of
the owner of the github repo containing the software, and the repo name. If any
of the other options is dot (.) or it is missing, a default value is used.

The `package_name` is the name you want to use to refer to the software (e.g.
for naming the package directory); as default it the same string passed as
`github_repo`.  The `opt_pattern` define a regex pattern used for some repo
types (details in following) and they have; its default is `github_repo` too.

Each package will be installed in its `Target` directory, i.e. the
`package_name` subfolder of the `Installation` directory. What is placed inside
such directory depends on the value of `repo_type` (which default is "gz.tar"):

- "github.master" - the target repo is simply cloned inside the `Target`
  directory; the `.git` auxiliary folder is removed (note: `opt_pattern` is
  ignored); the master branch is checked-out;

- "bare" - it looks in the last github release page for the first file matching
  the `opt_pattern`; it is downloaded in the `Target` directory;

- "uudecode.xz", or "gz.tar", or "tar" - it behaves like the "bare" package,
  but the file is decompressed according to the desired algorithm (uuencode,
  gz, etc);

Once the software is installed, some sub-folder are treated in the followng
special way:

- hook/action - all the script in this subfolder are linked in the `Scripts`
  folder, to be quickly searched and launched; the content of the `package_name` is
  used as prefix for the target name, so, for example, if two packages `pkg_a`
  and `pkg_b` provide a `start.sh` script, in the desired subfolder you will
  fined two files `pkg_a_start.sh`, `pkg_b_start.sh`; the `__unnamed__` script
  is a special case since it will be linked in `pkg_a` or `pkg_b` without any
  suffix;

- hook/boot - it is currently ignored (to be implemented yet ! ? )

