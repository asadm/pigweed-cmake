import os
import shutil
import sys
from pathlib import Path

# Add Pigweed python packages to path
pw_root = Path(__file__).parent / "pigweed"
sys.path.append(str(pw_root / "pw_build" / "py"))
sys.path.append(str(pw_root / "pw_protobuf" / "py"))
sys.path.append(str(pw_root / "pw_protobuf_compiler" / "py"))
sys.path.append(str(pw_root / "pw_rpc" / "py"))
sys.path.append(str(pw_root / "pw_hdlc" / "py"))
sys.path.append(str(pw_root / "pw_status" / "py"))
sys.path.append(str(pw_root / "pw_stream" / "py"))
sys.path.append(str(pw_root / "pw_toolchain" / "py"))

from pw_protobuf_compiler import generate_protos

def main():
    # Define paths
    project_root = Path(__file__).parent
    generated_dir = project_root / "generated_protos"
    pigweed_dir = project_root / "pigweed"
    
    # Clean generated directory
    if generated_dir.exists():
        shutil.rmtree(generated_dir)
    generated_dir.mkdir(parents=True)

    # 1. Generate pw_protobuf protos (codegen_options, etc.)
    # These are needed by pw_protobuf itself
    print("Generating pw_protobuf protos...")
    generate_protos.main([
        "--language", "python",
        "--out-dir", str(generated_dir),
        "--proto-path", str(pigweed_dir),
        "--sources",
        str(pigweed_dir / "pw_protobuf/pw_protobuf_codegen_protos/codegen_options.proto"),
        str(pigweed_dir / "pw_protobuf/pw_protobuf_protos/common.proto"),
        str(pigweed_dir / "pw_protobuf/pw_protobuf_protos/field_options.proto"),
        str(pigweed_dir / "pw_protobuf/pw_protobuf_protos/status.proto"),
    ])

    # 2. Generate pw_rpc internal protos
    # These need to be moved to the source tree for pw_rpc to find them
    print("Generating pw_rpc internal protos...")
    temp_rpc_dir = generated_dir / "temp_rpc"
    temp_rpc_dir.mkdir()
    
    generate_protos.main([
        "--language", "python",
        "--out-dir", str(temp_rpc_dir),
        "--proto-path", str(pigweed_dir),
        "--sources",
        str(pigweed_dir / "pw_rpc/internal/packet.proto"),
    ])

    # Move packet_pb2.py to source tree
    rpc_internal_dir = pigweed_dir / "pw_rpc/py/pw_rpc/internal"
    rpc_internal_dir.mkdir(parents=True, exist_ok=True)
    (rpc_internal_dir / "__init__.py").touch()
    
    packet_pb2 = list(temp_rpc_dir.glob("**/packet_pb2.py"))[0]
    shutil.move(str(packet_pb2), str(rpc_internal_dir / "packet_pb2.py"))
    shutil.rmtree(temp_rpc_dir)

    # 3. Generate application protos
    print("Generating application protos...")
    generate_protos.main([
        "--language", "python",
        "--out-dir", str(generated_dir),
        "--proto-path", str(project_root),
        "--proto-path", str(pigweed_dir),
        "--sources",
        str(project_root / "time_service.proto"),
    ])

    print("Proto generation complete.")

if __name__ == "__main__":
    main()
