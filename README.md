
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
- It automatically creates wrapper scripts to recall package functionality
- It keeps the filesystem clean: all the software is installed the `/media/fat/misc` folder
- TODO : automatic boot script ???

# Installation

To install all the software, you can download the
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

Work in progress.

# Package Specification

Work in progress.

# Adapt the script to other devices

Work in progress.

