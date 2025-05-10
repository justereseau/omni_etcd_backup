#!/bin/sh
set -e

echo "Bon Matin!"

# Print the current cpu architecture
echo "Current CPU architecture: $(uname -m)"

# Do a switch-case like on the architecture
case $(uname -m) in
    x86_64)
        echo "Building for x86_64"
        # Add your build commands for x86_64 here
        ;;
    aarch64)
        echo "Building for aarch64"
        # Add your build commands for aarch64 here
        ;;
    armv7l)
        echo "Building for armv7l"
        # Add your build commands for armv7l here
        ;;
    *)
        echo "Unsupported architecture: $(uname -m)"
        exit 1
        ;;
esac

# Get the b2 package
echo "Getting b2 package..."
wget https://github.com/Backblaze/B2_Command_Line_Tool/releases/latest/download/b2-linux -O /usr/local/bin/b2
chmod +x /usr/local/bin/b2
echo "b2 version: $(b2 version)"
