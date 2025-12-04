cmake_minimum_required(VERSION 3.20)
project(rpc_sample CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# To use Pigweed, you must have a Git submodule or a copy of the Pigweed
# repository. This CMake project is configured to use a Git submodule.
set(PW_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/pigweed")

set(pigweed_SOURCE_DIR "${PW_ROOT}")
set(pigweed_BINARY_DIR "${CMAKE_BINARY_DIR}/pigweed")
set(ENV{PW_ROOT} "${pigweed_SOURCE_DIR}")

# Include Pigweed CMake modules
include(${pigweed_SOURCE_DIR}/pw_build/pigweed.cmake)

# Include backend definition files
include(${pigweed_SOURCE_DIR}/pw_assert/backend.cmake)
include(${pigweed_SOURCE_DIR}/pw_log/backend.cmake)
include(${pigweed_SOURCE_DIR}/pw_sync/backend.cmake)
include(${pigweed_SOURCE_DIR}/pw_sys_io/backend.cmake)
include(${pigweed_SOURCE_DIR}/pw_thread/backend.cmake)
include(${pigweed_SOURCE_DIR}/pw_chrono/backend.cmake)

# Set backends
pw_set_backend(pw_log pw_log_basic)
pw_set_backend(pw_assert.assert pw_assert_log.assert_backend)
pw_set_backend(pw_assert.check pw_assert_log.check_backend)
pw_set_backend(pw_sys_io pw_sys_io_stdio)
pw_set_backend(pw_sync.mutex pw_sync_stl.mutex_backend)
pw_set_backend(pw_sync.binary_semaphore pw_sync_stl.binary_semaphore_backend)
pw_set_backend(pw_sync.counting_semaphore pw_sync_stl.counting_semaphore_backend)
pw_set_backend(pw_sync.condition_variable pw_sync_stl.condition_variable_backend)
pw_set_backend(pw_sync.timed_mutex pw_sync_stl.timed_mutex_backend)
pw_set_backend(pw_sync.thread_notification pw_sync.binary_semaphore_thread_notification_backend)
pw_set_backend(pw_sync.timed_thread_notification pw_sync.binary_semaphore_timed_thread_notification_backend)
pw_set_backend(pw_sync.interrupt_spin_lock pw_sync_stl.interrupt_spin_lock)
pw_set_backend(pw_thread.sleep pw_thread_stl.sleep)
pw_set_backend(pw_thread.yield pw_thread_stl.yield)
pw_set_backend(pw_thread.id pw_thread_stl.id)
pw_set_backend(pw_thread.thread pw_thread_stl.thread)
pw_set_backend(pw_chrono.system_clock pw_chrono_stl.system_clock)
pw_set_backend(pw_chrono.system_timer pw_chrono_stl.system_timer)

add_subdirectory(${pigweed_SOURCE_DIR} ${pigweed_BINARY_DIR} EXCLUDE_FROM_ALL)

include(${pigweed_SOURCE_DIR}/pw_protobuf_compiler/proto.cmake)


# Define the proto library
pw_proto_library(time_service_proto
  SOURCES
    time_service.proto
)

# Define the server executable
add_executable(rpc_sample_server server.cc)

target_link_libraries(rpc_sample_server
  PRIVATE
    time_service_proto.pwpb
    time_service_proto.pwpb_rpc
    pw_rpc.server
    pw_rpc.pwpb.echo_service
    pw_hdlc
    pw_hdlc.rpc_channel_output
    pw_log
    pw_log_basic
    pw_stream.socket_stream
)
