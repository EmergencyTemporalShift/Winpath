#!/bin/bash

# AI Disclosure: This script was created with the assistance of the large language model Gemini
# Please review it before doing anything mission critical


# This script converts a Windows-style path with a drive letter
# to a standard Linux path. It's useful for paths that comes from
# compatibility layers like Wine or Proton.
#
# This updated version includes command-line flags to control the output:
#   -o, --output: Prints the converted path to standard output (stdout).
#   -c, --clipboard: Copies the converted path to the clipboard.
#   -d, --dry-run: Same as -o, for a clear "test" of the conversion without
#                  opening the file browser.
#   -w, --wl-copy: Forces the use of the wl-copy clipboard utility.
#   -x, --xclip: Forces the use of the xclip clipboard utility.
#   If no flags are provided, the script will automatically open the
#   converted directory in the default file browser.

# Initialize options and flags
output_to_stdout=false
output_to_clipboard=false
force_xclip=false
force_wl_copy=false

# Use getopts to parse command-line flags
# The ':' after 'cdowx' indicates that 'c', 'd', 'o', 'w', and 'x' are valid options
# The '--' handles long options
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do
    case $1 in
        -o | --output | -d | --dry-run )
            output_to_stdout=true
            ;;
        -c | --clipboard )
            output_to_clipboard=true
            ;;
        -w | --wl-copy )
            output_to_clipboard=true
            force_wl_copy=true
            ;;
        -x | --xclip )
            output_to_clipboard=true
            force_xclip=true
            ;;
    esac
    shift
done
if [[ "$1" == '--' ]]; then
    shift
fi

# The input path from the user is now the first argument after any flags
windows_path="$1"

# Check if an argument was provided
if [ -z "$windows_path" ]; then
    echo "Usage: $0 [-o | -c | -d | -w | -x] <windows_path>"
    echo "  -o, --output    Prints the path to stdout."
    echo "  -c | --clipboard Copies the path to the clipboard."
    echo "  -d, --dry-run   Prints the path to stdout (same as -o)."
    echo "  -w, --wl-copy   Forces wl-copy for the clipboard."
    echo "  -x, --xclip     Forces xclip for the clipboard."
    echo "  (Default)       Opens the path in the default file browser."
    echo ""
    echo "Example: $0 'Z:\home\youruser\.local\share\Steam'"
    exit 1
fi

# Convert backslashes to forward slashes first
linux_path=$(echo "$windows_path" | sed 's/\\/\//g')

# The drive letter conversion assumes that Z: maps to the root of the filesystem.
# This is a common convention in Wine/Proton. The rest of the path should
# be preserved as is, since Linux paths are case-sensitive.
if [[ "$linux_path" =~ ^[A-Za-z]: ]]; then
    # Replace the leading drive letter and colon with a single forward slash
    converted_path=$(echo "$linux_path" | sed 's/^[A-Za-z]:/\//')
else
    # If there's no drive letter, just use the path as is
    converted_path="$linux_path"
fi

# Final cleanup to remove any potential double leading slashes
converted_path=$(echo "$converted_path" | sed 's/^\/\//\//')

# Default action: open the default file browser unless a flag is specified
if [[ "$output_to_stdout" == true ]]; then
    echo "$converted_path"
    exit 0
elif [[ "$output_to_clipboard" == true ]]; then
    # Prioritize specific clipboard tools if forced by flags (rightmost precedence)
    if [[ "$force_wl_copy" == true ]]; then
        if ! command -v wl-copy &> /dev/null; then
            echo "Error: The '-w' flag was used, but wl-copy was not found."
            exit 1
        fi
        echo -n "$converted_path" | wl-copy
        echo "Path copied to clipboard (using wl-copy)."
    elif [[ "$force_xclip" == true ]]; then
        if ! command -v xclip &> /dev/null; then
            echo "Error: The '-x' flag was used, but xclip was not found."
            exit 1
        fi
        echo -n "$converted_path" | xclip -selection clipboard
        echo "Path copied to clipboard (using xclip)."
    # Fall back to automatic detection if no flag was specified
    elif command -v wl-copy &> /dev/null; then
        echo -n "$converted_path" | wl-copy
        echo "Path copied to clipboard (using wl-copy)."
    elif command -v xclip &> /dev/null; then
        echo -n "$converted_path" | xclip -selection clipboard
        echo "Path copied to clipboard (using xclip)."
    else
        echo "Error: Neither wl-copy nor xclip was found. Please install a clipboard utility."
        exit 1
    fi
    exit 0
else
    # This is the new default behavior
    xdg-open "$converted_path" &>/dev/null &
    echo "Opening default file browser at: $converted_path"
fi
