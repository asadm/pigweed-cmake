#include <chrono>
#include <thread>

#include "pw_hdlc/rpc_channel.h"
#include "pw_hdlc/decoder.h"
// #include "pw_hdlc/rpc_packets.h"
#include "pw_log/log.h"
#include "pw_rpc/server.h"
#include "pw_stream/socket_stream.h"
#include "time_service.pwpb.h"
#include "time_service.rpc.pwpb.h"

namespace {

// 1. Implement the Service
class TimeServiceImpl final
    : public rpc_sample::pw_rpc::pwpb::TimeService::Service<TimeServiceImpl> {
 public:
  pw::Status GetTime(const rpc_sample::TimeRequest::Message& request,
                     rpc_sample::TimeResponse::Message& response) {
    PW_LOG_INFO("Received GetTime request");
    // Get current time in milliseconds
    auto now = std::chrono::system_clock::now();
    auto duration = now.time_since_epoch();
    auto millis = std::chrono::duration_cast<std::chrono::milliseconds>(duration).count();
    
    response.timestamp = millis;
    return pw::OkStatus();
  }
};

}  // namespace

int main() {
  // pw::log_basic::SetOutput();
  PW_LOG_INFO("Starting RPC Sample Server");

  // 2. Setup Transport (Socket simulating UART)
  pw::stream::ServerSocket server_socket;
  if (!server_socket.Listen(33000).ok()) {
    PW_LOG_ERROR("Failed to listen on port 33000");
    return 1;
  }
  PW_LOG_INFO("Listening on port 33000");

  auto accept_result = server_socket.Accept();
  if (!accept_result.ok()) {
    PW_LOG_ERROR("Failed to accept connection");
    return 1;
  }
  pw::stream::SocketStream& socket_stream = *accept_result;
  PW_LOG_INFO("Client connected");

  // 3. Setup RPC Server
  // HDLC Channel Output: Writes encoded HDLC frames to the socket
  pw::hdlc::RpcChannelOutput hdlc_channel_output(socket_stream, 1, "HDLC");
  
  std::array<pw::rpc::Channel, 1> channels = {
    pw::rpc::Channel::Create<1>(&hdlc_channel_output),
  };
  pw::rpc::Server server(channels);

  // 4. Register Service
  TimeServiceImpl time_service;
  server.RegisterService(time_service);

  // 5. Read Loop (Decode HDLC -> Feed to RPC Server)
  std::array<std::byte, 1024> buffer;
  pw::hdlc::Decoder decoder(buffer);

  while (true) {
    auto read_result = socket_stream.Read(buffer);
    if (!read_result.ok()) {
      PW_LOG_INFO("Client disconnected");
      break;
    }

    for (std::byte b : *read_result) {
      if (auto result = decoder.Process(b); result.ok()) {
        pw::hdlc::Frame frame = result.value();
        if (frame.address() == 1) { // RPC address
          server.ProcessPacket(frame.data());
        }
      }
    }
  }

  return 0;
}
