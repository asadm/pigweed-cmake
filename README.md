# Pigweed RPC CMake Sample

This project demonstrates how to use Pigweed RPC with CMake. It includes a C++ server and a Python client that communicate over a socket.

## Project Structure

*   **`server.cc`**: A simple C++ RPC server that implements a `TimeService`.
*   **`client.py`**: A Python client that connects to the server and makes RPC calls.
*   **`time_service.proto`**: The Protobuf definition for the RPC service.
*   **`generate_protos.py`**: A Python script to generate C++ and Python code from the `.proto` files using `pw_protobuf_compiler`.
*   **`run.sh`**: A helper script to set up the environment, build the project, and run the example.
*   **`pigweed/`**: The Pigweed repository (submodule).

The easiest way to run the sample is using the provided `run.sh` script:

```bash
./run.sh
```

This script will:
1.  Set up a Python virtual environment.
2.  Install necessary Python dependencies (`protobuf`, `pyserial`).
3.  Generate the Protobuf/RPC code.
4.  Configure and build the C++ server using CMake.
5.  Start the C++ server in the background.
6.  Run the Python client to send RPC requests.

## Manual Build & Run

If you prefer to run the steps manually:

1.  **Setup Python Environment:**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    pip install protobuf pyserial
    export PYTHONPATH=$PYTHONPATH:$(pwd)/generated_protos
    export PYTHONPATH=$PYTHONPATH:$(pwd)/generated_protos/pw_protobuf
    export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_hdlc/py
    export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_log/py
    export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_protobuf/py
    export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_protobuf_compiler/py
    export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_rpc/py
    export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_status/py
    export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_stream/py
    export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_symbolizer/py
    export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_tokenizer/py
    export PYTHONPATH=$PYTHONPATH:$(pwd)/pigweed/pw_toolchain/py
    ```

2.  **Generate Protos:**
    ```bash
    python3 generate_protos.py
    ```

3.  **Build C++ Server:**
    ```bash
    mkdir -p build
    cd build
    cmake .. -GNinja
    ninja
    cd ..
    ```

4.  **Run:**
    *   Start the server: `./build/rpc_server`
    *   In another terminal (with venv activated and PYTHONPATH set), run the client: `python3 client.py`
