import argparse
import socket
import sys
import threading
import time
from pw_hdlc.rpc import HdlcRpcClient, channel_output, default_channels
from pw_rpc import Channel
from pw_stream.stream_readers import SocketReader

# Import generated proto modules
import time_service_pb2


def main():
    # Connect to the server
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect(('localhost', 33000))

    # Create the client
    client = HdlcRpcClient(
        SocketReader(sock, 4096), 
        [time_service_pb2], 
        [Channel(1, channel_output(sock.sendall, address=1))],
        rpc_frames_address=1,
        log_frames_address=2
    )

    response_received = threading.Event()
    
    def on_next(*args):
        if len(args) > 1:
            response = args[1]
            print(f"Success! Server time: {response.timestamp}", flush=True)
        response_received.set()

    def on_error(*args):
        print(f"RPC failed with status: {args[1] if len(args) > 1 else 'Unknown'}", flush=True)
        response_received.set()

    with client:
        service = client.rpcs().rpc_sample.TimeService
        request_type = service.GetTime.method.request_type
        
        print("Sending GetTime request...", flush=True)
        service.GetTime.invoke(request_type(), on_next=on_next, on_error=on_error)
        
        print("Waiting for response...", flush=True)
        if response_received.wait(timeout=5):
            print("Response received!", flush=True)
        else:
            print("Timed out waiting for response.", flush=True)
            sys.exit(1)

if __name__ == '__main__':
    main()
