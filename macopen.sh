#!/bin/sh

usage() {
	echo "Usage: macopen [-u <eduser>] [-h <host>] [-U <fsuser>] <filename> [<filename2>...<filenameN>] [-A openArguments]"
  echo "Help: Connects via SSH to the specified Mac, mounts this host's filesystem via SSHFS,"
  echo "      and opens the specified file(s) using the 'open' command."
  echo "Options:"
  echo "      -u Connects to the Mac as the specified user"
  echo "      -h Connects to the specified host"
  echo "      -U Mounts this host's filesystem as the specified user"
  echo "      -H Overrides the host name for the connection to this host's filesystem"
}

# Set the ED_USER variable that determines the user with which we'll log into
# the Mac.  Prefer the MACOPEN_USER environment variable; if that's empty,
# default to the logged-in user on this host.  This can be overridden by the
# -u command-line option.

if [ -z "$ED_USER" ]; then
	ED_USER="$MACOPEN_USER"
fi

if [ -z "$ED_USER" ]; then
	ED_USER="$USER"
fi

# Set the ED_HOST variable that determines what Mac we'll connect to via SSH.
# Prefer the MACOPEN_HOST environment variable; fall back on the SSH_CLIENT
# environment variable.  This can be overridden by the -h command-line option.  

if [ -z "$ED_HOST" ]; then
	ED_HOST="$MACOPEN_HOST"
fi

if [ -z "$ED_HOST" ]; then
	ED_HOST=$(echo "$SSH_CLIENT" | sed 's/ .*//')
fi

# Set the FS_HOST variable that tells the Mac what machine's filesystem to mount.
# In case the "hostname" can't be resolved due to DNS issues or something, this
# can be overridden by the -H command-line option.

FS_HOST=`hostname`

# Set the FS_USER variable that tells the Mac what username to use when mounting
# this host's filesystem.  This can be overridden by the -U command-line option.

FS_USER="$USER"

# parse the command-line options using bash's built-in getopts

while getopts ":u:h:U:h:" opt; do
  case $opt in
    u)
      ED_USER="$OPTARG"
      ;;
    h)
    	ED_HOST="$OPTARG"
    	;;
    U)
    	FS_USER="$OPTARG"
        ;;
    H)
        FS_HOST="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

echo "after getopts, OPTIND=$OPTIND and \$1=$1"

OPEN_ARGS=""
FS_PATHS=""

MOUNTS_DIR='$HOME/.macopen_mounts'
MOUNT_DIR="$MOUNTS_DIR/$FS_USER@$FS_HOST"

while [ -n "$1" ] && [ "$1" != "-A" ]
do
	FILENAME=`basename $1`
	DIRNAME=$(cd "$(dirname "$1")"; pwd)
        LOCAL_PATH=$(echo "$DIRNAME/$FILENAME" | sed 's|^/||')
        FS_PATH="$MOUNT_DIR/$LOCAL_PATH"
        if [ -n "$FS_PATHS" ]; then
           FS_PATHS="$FS_PATHS \"$FS_PATH\""
        else
           FS_PATHS="\"$FS_PATH\""
        fi
	shift
done

if [ -z "$FS_PATHS" ]; then
	echo "No filename specifed." >&2
	usage
	exit 1
fi

if [ -z "$ED_HOST" ]; then
	echo "No host specified.  You have three options:"
	echo "  1) Export SSH_CLIENT in your .bashrc (bash unexports it under certain circumstances),"
	echo "  2) Set the MACOPEN_HOST environment variable, or"
	echo "  3) Specify the host on the command line via the -h option"
fi

echo "FS_PATHS=$FS_PATHS"

MOUNT_AND_OPEN_SCRIPT=$(cat << 'EOF'

MOUNTS_DIR=$MOUNTS_DIR
MOUNT_DIR="$MOUNT_DIR"

if [ ! -d "$MOUNTS_DIR" ]; then
 mkdir "$MOUNTS_DIR"
fi

if [ ! -d $MOUNT_DIR ]; then
  mkdir "$MOUNT_DIR"
fi

if mount | grep "$MOUNT_DIR" > /dev/null; then
  echo "filesystem $MOUNT_DIR already mounted"
else
  /usr/local/bin/sshfs -o follow_symlinks,volname=$FS_HOST $FS_USER@$FS_HOST:/ "$MOUNT_DIR"
fi

echo "open $OPEN_ARGS $FS_PATHS"

open $OPEN_ARGS $FS_PATHS

EOF
);

echo "trying ssh ${ED_USER}@${ED_HOST}"

ssh "${ED_USER}@${ED_HOST}" <<EOF

FS_HOST="$FS_HOST"
FS_USER="$FS_USER"
FS_PATHS="$FS_PATHS"
OPEN_ARGS="$OPEN_ARGS"

$MOUNT_AND_OPEN_SCRIPT

EOF
