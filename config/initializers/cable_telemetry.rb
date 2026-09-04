ActiveSupport::Notifications.subscribe("broadcast.action_cable") do |_name, _start, _finish, _id, payload|
  encoded = payload[:coder] ? payload[:coder].encode(payload[:message]) : payload[:message].to_s
  bytes = encoded.bytesize
  ActiveSupport::Notifications.instrument(
    "cable.broadcast.wrestlingdev",
    stream: payload[:broadcasting],
    message_count: 1,
    total_bytes: bytes,
    payload_size_bytes: bytes
  )
end
