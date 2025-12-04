#!/bin/bash
set -e

# 0. Setup Python Venv
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install protobuf pyserial

# Add generated_protos and Pigweed packages to PYTHONPATH
export PYTHONPATH=$PYTHONPATH:$(pwd)/generated_protos
export PYTHONPATH=$PYTHONPATH:$(pwd)/generated_protos/pw_protobuf
export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_build/py
export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_protobuf/py
export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_protobuf_compiler/py
export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_rpc/py
export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_hdlc/py
export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_status/py
export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_stream/py
export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_toolchain/py

# 1. Configure and Build
mkdir -p build
cd build
cmake .. -DPython3_EXECUTABLE=$(which python3)

# 2. Generate Protos
cd ..
python3 generate_protos.py

# 3. Build C++
cd build
make -j4
cd ..

# Kill any existing server instance
pkill -f rpc_sample_server || true
sleep 1

# 4. Run Server
./build/rpc_sample_server &
SERVER_PID=$!
echo "Server started with PID $SERVER_PID"
sleep 5 # Wait for server to start

# 5. Run Client
echo "Running Python Client..."
python3 client.py

# Cleanup
kill $SERVER_PID > /dev/null 2>&1 || true
