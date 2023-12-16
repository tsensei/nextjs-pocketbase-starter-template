#!/bin/bash

# Check if pnpm is installed
if ! command -v pnpm &> /dev/null
then
    echo -e "Error: pnpm is not installed. To install, use \e[34msudo npm install -g pnpm\e[0m"
    exit 1
fi

echo "Installing all dependencies"
pnpm i

# Declare the PocketBase version
PB_VERSION="0.20.0"

PB_DIR="./pocketbase"

# Create a pocketbase directory in project_root
mkdir -p $PB_DIR

# Check if unzip is installed
if ! command -v unzip &> /dev/null
then
    echo "Error: unzip is not installed. Please install unzip to proceed."
    exit 1
fi

# Download PocketBase and keep it temporarily
echo "Downloading PocketBase version $PB_VERSION..."
curl -L -# "https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip" -o /tmp/pocketbase.zip

# Extract the content into the pocketbase directory
echo
echo "Extracting PocketBase..."
unzip /tmp/pocketbase.zip -d $PB_DIR

# Clean up the downloaded zip file
rm /tmp/pocketbase.zip

./pocketbase/pocketbase serve &
PB_PID=$!

# Healthcheck with curl
echo "Performing health check..."
ATTEMPTS=10
SUCCESS=false
for ((i=1; i<=ATTEMPTS; i++)); do
    RESPONSE=$(curl -s "http://localhost:8090/api/health")
    if [[ $RESPONSE == *'"code":200'* ]]; then
        echo "PocketBase is up and running!"
        SUCCESS=true
        break
    else
        echo "Attempt $i of $ATTEMPTS: Waiting for PocketBase to start..."
        sleep 0.5
    fi
done

if [ "$SUCCESS" = false ]; then
    echo "Error: PocketBase did not respond in time."
    exit 1
fi

# Run additional command if healthcheck passed
echo "Generating pocketbase types..."
pnpm typegen

# Shutdown PocketBase
kill $PB_PID
echo
echo "PocketBase was successfully installed"

echo
echo "Next steps:"
echo -e "1. Run \e[34mpnpm dev\e[0m to start NextJS dev server and pocketbase"
echo -e "2. Go to Pocketbase Admin UI :  \e[34mhttp://127.0.0.1:8090/_/\e[0m and signup"
echo -e "3. Go to NextJS site homepage : \e[34mhttp://localhost:3000\e[0m and follow furthur instructions"
