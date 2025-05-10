#!/bin/sh
set -e

ETCD_VERSION="latest"

echo "Bon Matin!"

# Print the current cpu architecture
echo "Current CPU architecture: $(uname -m)"

# Do a switch-case like on the architecture
case $(uname -m) in
    x86_64)
        echo "Building for x86_64"
        export GOOS=linux GOARCH=amd64
        # Add your build commands for x86_64 here
        ;;
    aarch64)
        echo "Building for aarch64"
        export GOOS=linux GOARCH=arm64
        # Add your build commands for aarch64 here
        ;;
    armv7l)
        echo "Building for armv7l"
        export GOOS=linux GOARCH=arm GOARM=7
        # Add your build commands for armv7l here
        ;;
    *)
        echo "Unsupported architecture: $(uname -m)"
        exit 1
        ;;
esac

# # Get the b2 package
# echo "Getting b2 package..."
# wget https://github.com/Backblaze/B2_Command_Line_Tool/releases/latest/download/b2-linux -O /usr/local/bin/b2
# chmod +x /usr/local/bin/b2
# echo "b2 version: $(b2 version)"

# Get the latest release of etcd
ETCD_RELEASE_NAME=$(curl -s https://api.github.com/repos/etcd-io/etcd/releases/$ETCD_VERSION | jq -r '.tag_name')

# Get the source code for the latest release
curl -sL https://github.com/etcd-io/etcd/archive/refs/tags/$ETCD_RELEASE_NAME.tar.gz -o etcd-source.tar.gz
mkdir -p etcd-source
cd etcd-source
tar -xzf ../etcd-source.tar.gz --strip-components=1
rm ../etcd-source.tar.gz

# Build etcd
echo "Building etcd..."
./build.sh

# Print the version of etcd
echo "etcd version: $(./bin/etcd --version)"
# Print the version of etcdctl
echo "etcdctl version: $(./bin/etcdctl --version)"
# Print the version of etcdutl
echo "etcdutl version: $(./bin/etcdutl --version)"
