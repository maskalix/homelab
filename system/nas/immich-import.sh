#!/bin/bash

# Function to create immich-import folder and import.sh script
create_import_script() {
    # Check if username is provided
    if [ -z "$1" ]; then
        echo "Usage: $0 <username>"
        exit 1
    fi
    
    USERNAME="$1"
    USER_HOME_DIR=$(eval echo ~$USERNAME)
    PICTURES_DIR="$USER_HOME_DIR/Pictures"
    IMPORT_DIR="$PICTURES_DIR/immich-import"
    IMPORT_SCRIPT="$IMPORT_DIR/import.sh"
    CRED_FILE="$IMPORT_DIR/.cred"

    # Create the immich-import folder
    mkdir -p "$IMPORT_DIR"
    chown -R $USERNAME:$USERNAME $PICTURES_DIR
    # Create import.sh script
    cat > "$IMPORT_SCRIPT" <<EOF
#!/bin/bash

# Check if immich is installed
if ! command -v immich &> /dev/null
then
    echo "immich command not found. Please install it first."
    exit 1
fi

# Check if .cred file exists
if [ ! -f "$CRED_FILE" ]; then
    echo ".cred file not found. Please ensure the .cred file exists with the API key."
    exit 1
fi

# Read API key from .cred file
API_KEY=\$(cat "$CRED_FILE")

# Login to immich
immich login http://IP_ADDR/api \$API_KEY

# Upload files
immich upload upload --recursive "$USER_HOME_DIR/Pictures/immich-import/"
EOF

    # Make the import.sh script executable
    chmod +x "$IMPORT_SCRIPT"

    # Check if .cred file exists, if not, prompt for API key and save it
    if [ ! -f "$CRED_FILE" ]; then
        read -p "Enter your API key: " API_KEY
        echo "$API_KEY" > "$CRED_FILE"
        chmod 600 "$CRED_FILE"
        echo "API key saved to $CRED_FILE."
    else
        echo ".cred file already exists. Using existing API key."
    fi

    echo "Setup complete. The immich-import folder and import.sh script have been created at $IMPORT_DIR."
}

# Call the function with the provided username
create_import_script "$1"
