import 'package:logging/logging.dart';

import 'ihub_protocol.dart';
import 'itransport.dart';
// Conditional imports for platform-specific implementations
import 'web_socket_transport_stub.dart'
    if (dart.library.io) 'web_socket_transport_io.dart'
    if (dart.library.html) 'web_socket_transport_web.dart';

// Re-export the base class for type compatibility
export 'web_socket_transport_stub.dart' show WebSocketTransportBase;

/// WebSocket transport for SignalR connections.
/// Uses platform-specific implementations via conditional imports.
/// - On IO platforms (mobile, desktop): Uses dart:io WebSocket with custom headers support
/// - On Web platforms: Uses WebSocketChannel.connect (no custom headers, uses query params)
class WebSocketTransport implements ITransport {
  final ITransport _transport;

  WebSocketTransport(
    AccessTokenFactory? accessTokenFactory,
    Logger? logger,
    bool logMessageContent,
    MessageHeaders? headers,
  ) : _transport = createWebSocketTransport(
          accessTokenFactory,
          logger,
          logMessageContent,
          headers,
        );

  @override
  OnClose? get onClose => _transport.onClose;

  @override
  set onClose(OnClose? value) => _transport.onClose = value;

  @override
  OnReceive? get onReceive => _transport.onReceive;

  @override
  set onReceive(OnReceive? value) => _transport.onReceive = value;

  @override
  Future<void> connect(String? url, TransferFormat transferFormat) =>
      _transport.connect(url, transferFormat);

  @override
  Future<void> send(Object data) => _transport.send(data);

  @override
  Future<void> stop() => _transport.stop();
}
