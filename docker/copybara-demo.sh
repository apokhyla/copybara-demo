#!/bin/bash -x

# WARNING: the script in the current version fails/hangs because of the GitHub authorization

set -eo pipefail

CONFIG_FILE="copy.bara.sky"
IMAGE_NAME="copybara:local"

# 1. Check for GITHUB_TOKEN

if [ -z "$GITHUB_TOKEN" ]; then
    echo "⚠️ GITHUB_TOKEN is not set."
    echo -n "Please paste your GitHub Personal Access Token (classic) here: "
    read -s GITHUB_TOKEN
    echo ""
fi

# 2. Check if Docker is running

if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running."
    echo " Please start Docker Desktop or the Docker daemon and try again."
    exit 1
fi

# 3. Create a temporary git config file

echo "🔐 Configuring git to use your token..."

GIT_CONFIG_FILE="$(pwd)/.gitconfig-temp"

cat <<EOF > "$GIT_CONFIG_FILE"
[url "https://x-access-token:${GITHUB_TOKEN}@github.com/"]
    insteadOf = https://github.com/
[user]
    name = Copybara Bot
    email = anton.pokhyla@mongodb.com
[safe]
    directory = *
EOF

trap 'rm -f "$GIT_CONFIG_FILE"; echo "🧹 Cleanup complete."' EXIT

# 4. Build Copybara image if missing

if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
    echo "🏗️ Copybara docker image not found. Building from source..."
    
    git clone https://github.com/google/copybara.git temp_copybara_build
    
    cd temp_copybara_build
    docker build -t $IMAGE_NAME .
    
    cd ..
    rm -rf temp_copybara_build
    
    echo "✅ Build complete."
fi

# 5. Run

echo "🚀 Starting Copybara..."

docker run \
    --rm \
    -u root \
    -e HOME=/root \
    -e GIT_TERMINAL_PROMPT=0 \
    -e GIT_TRACE=1 \
    -e GIT_CURL_VERBOSE=1 \
    -v "$(pwd)":/usr/src/app \
    -v "$GIT_CONFIG_FILE":/root/.gitconfig \
    -e COPYBARA_CONFIG=$CONFIG_FILE \
    -e COPYBARA_WORKFLOW=ops-manager \
    -e GITHUB_TOKEN="${GITHUB_TOKEN:-}" \
    -it \
    $IMAGE_NAME \
    migrate $CONFIG_FILE --verbose

echo "✅ Done."