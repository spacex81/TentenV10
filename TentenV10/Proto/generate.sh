#!/bin/bash

# Get the directory where generate.sh is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Path to the protocol file
PROTO_FILE="$SCRIPT_DIR/protocol/service.proto"

# Generate Swift files from the .proto file
protoc --proto_path="$SCRIPT_DIR/protocol" \
       --swift_out="$SCRIPT_DIR" \
       --swift-grpc_out="$SCRIPT_DIR" \
       "$PROTO_FILE"
