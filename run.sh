#!/bin/bash
set -e

# 0. Setup Python Venv
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install protobuf pyserial

# 1. Configure and Build
mkdir -p build
cd build
cmake .. -DPython3_EXECUTABLE=$(which python3)

# Generate pw_protobuf_codegen_protos
mkdir -p generated_protos/pw_protobuf_codegen_protos
touch generated_protos/pw_protobuf_codegen_protos/__init__.py

# Generate into a temp dir first because protoc follows package structure
mkdir -p generated_protos/temp
protoc --python_out=generated_protos/temp \
  -I../../ \
  ../../pw_protobuf/pw_protobuf_codegen_protos/codegen_options.proto

echo "DEBUG: Finding generated files:"
find generated_protos

# We will adjust this after seeing the debug output
# For now, try to find it and move it dynamically
FOUND_FILE=$(find generated_protos/temp -name "codegen_options_pb2.py")
mv "$FOUND_FILE" generated_protos/pw_protobuf_codegen_protos/

# Generate pw_protobuf_codegen_protos
# Generate into a temp dir first
mkdir -p generated_protos/temp
protoc --python_out=generated_protos/temp \
  -I../../ \
  ../../pw_protobuf/pw_protobuf_codegen_protos/codegen_options.proto

# Move to source tree
# pw_protobuf_codegen_protos is expected to be in pw_protobuf package
# We need to see where it generated.
# It likely generated in pw/protobuf/codegen_options_pb2.py or pw_protobuf/pw_protobuf_codegen_protos/...
# Let's find it and move it to ../../pw_protobuf/py/pw_protobuf/
# But wait, pw_protobuf source has pw_protobuf package.
# Does it have pw_protobuf_codegen_protos subpackage?
# Let's check if we need to create it.
# mkdir -p ../../pw_protobuf/py/pw_protobuf/pw_protobuf_codegen_protos
# touch ../../pw_protobuf/py/pw_protobuf/pw_protobuf_codegen_protos/__init__.py
# find generated_protos/temp -name "codegen_options_pb2.py" -exec mv {} ../../pw_protobuf/py/pw_protobuf/pw_protobuf_codegen_protos/ \;

# Generate pw_protobuf_protos
mkdir -p generated_protos/pw_protobuf_protos
touch generated_protos/pw_protobuf_protos/__init__.py

# Clean temp dir before second run to avoid confusion
rm -rf generated_protos/temp/*

protoc --python_out=generated_protos/temp \
  -I../../ \
  ../../pw_protobuf/pw_protobuf_protos/*.proto

echo "DEBUG: Finding generated files (2 cleaned):"
find generated_protos

# Move all pb2 files from temp to pw_protobuf_protos
find generated_protos/temp -name "*_pb2.py" -exec mv {} generated_protos/pw_protobuf_protos/ \;

# Generate pw_protobuf_protos
rm -rf generated_protos/temp/*
protoc --python_out=generated_protos/temp \
  -I../../ \
  ../../pw_protobuf/pw_protobuf_protos/*.proto

# Move to source tree
# pw_protobuf_protos is expected to be in pw_protobuf package?
# Or is it a separate package?
# The error was "ModuleNotFoundError: No module named 'pw_protobuf_protos'"
# This implies it's a top level package OR a subpackage that was imported as top level?
# Wait, if it's "pw_protobuf_protos", it might be a separate package.
# But earlier I generated it in generated_protos/pw_protobuf_protos and added generated_protos to PYTHONPATH.
# If I move it to source, I need to know where it's expected.
# The import was `from pw_protobuf_protos.field_options_pb2 import FieldOptions`?
# No, the error was `ModuleNotFoundError: No module named 'pw_protobuf_protos'`.
# So it expects `pw_protobuf_protos` to be importable.
# I should create `../../pw_protobuf_protos` (new dir) and add it to PYTHONPATH?
# Or just put it in `generated_protos` and keep `generated_protos` in PYTHONPATH, BUT ensure I don't shadow `pw_rpc` or `pw_protobuf`.
# The issue was `pw_rpc` shadowing.
# `pw_protobuf_protos` does not shadow anything if it doesn't exist in source.
# So I can keep `pw_protobuf_protos` in `generated_protos`.

# BUT `pw_protobuf_codegen_protos`?
# The error for that was `ModuleNotFoundError: No module named 'pw_protobuf_codegen_protos'` (implied).
# Actually, `pw_protobuf` imports it.
# If I keep `pw_protobuf_protos` and `pw_protobuf_codegen_protos` in `generated_protos`, it works for them.
# The problem is `pw_rpc`.
# I should ONLY move `pw_rpc` generated files to source, and keep others in `generated_protos`?
# Or move EVERYTHING to source to be consistent.

# Let's move `pw_rpc` generated files to source.
# And keep `pw_protobuf_protos` in `generated_protos` (since it's a separate top-level package name).
# And `pw_protobuf_codegen_protos`?
# It was `from pw_protobuf_codegen_protos.codegen_options_pb2 import CodegenOptions`.
# So it is also a top-level package name.

# So:
# 1. pw_protobuf_codegen_protos -> generated_protos/pw_protobuf_codegen_protos (Keep)
# 2. pw_protobuf_protos -> generated_protos/pw_protobuf_protos (Keep)
# 3. pw_rpc internal packet -> ../../pw_rpc/py/pw_rpc/internal/packet_pb2.py (Move to source)

# Revert pw_rpc generation in generated_protos
rm -rf generated_protos/pw_rpc

# Generate pw_rpc protos into temp
rm -rf generated_protos/temp/*
protoc --python_out=generated_protos/temp \
  -I../../ \
  ../../pw_rpc/internal/packet.proto

# Create pw_rpc/internal in source tree if it doesn't exist
mkdir -p ../../pw_rpc/py/pw_rpc/internal
touch ../../pw_rpc/py/pw_rpc/internal/__init__.py

# Move to source
find generated_protos/temp -name "packet_pb2.py" -exec mv {} ../../pw_rpc/py/pw_rpc/internal/ \;

# Set PYTHONPATH to include Pigweed packages
export PYTHONPATH=$PYTHONPATH:$(pwd)/../../pw_build/py
export PYTHONPATH=$PYTHONPATH:$(pwd)/../../pw_protobuf/py
export PYTHONPATH=$PYTHONPATH:$(pwd)/../../pw_protobuf_compiler/py
export PYTHONPATH=$PYTHONPATH:$(pwd)/../../pw_rpc/py
export PYTHONPATH=$PYTHONPATH:$(pwd)/../../pw_hdlc/py
export PYTHONPATH=$PYTHONPATH:$(pwd)/../../pw_status/py
export PYTHONPATH=$PYTHONPATH:$(pwd)/../../pw_stream/py
export PYTHONPATH=$PYTHONPATH:$(pwd)/../../pw_toolchain/py

# Generate pw_rpc/internal/packet.proto manually (as before)
# ... (Keep existing manual generation for pw_rpc if needed, or use generate_protos)
# Actually, let's use generate_protos for everything if possible, but manual is fine for internal.

# Generate time_service.proto (Python Protos)
python3 -m pw_protobuf_compiler.generate_protos \
  --proto-path=.. \
  --proto-path=../../ \
  --language python \
  --out-dir generated_protos \
  --sources ../time_service.proto

# Add generated_protos to PYTHONPATH
export PYTHONPATH=$PYTHONPATH:$(pwd)/generated_protos

# 2. Build
# cd build
cmake ..
make -j4
cd ..

# Kill any existing server instance
pkill -f rpc_sample_server || true
sleep 1

# 3. Run Server
./build/rpc_sample_server &
SERVER_PID=$!
echo "Server started with PID $SERVER_PID"
sleep 5 # Wait for server to start

# 4. Run Client
echo "Running Python Client..."
python3 client.py

# Cleanup
kill $SERVER_PID > /dev/null 2>&1 || true
