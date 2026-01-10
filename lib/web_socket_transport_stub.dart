import 'dart:async';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'errors.dart';
import 'ihub_protocol.dart';
import 'itransport.dart';
import 'utils.dart';

/// Factory function to create a WebSocketChannel.
/// This is implemented differently on web vs IO platforms.
typedef WebSocketChannelFactory = Future<WebSocketChannel> Function(
  String url,
  Map<String, String> headers,
);

/// Base class for WebSocket transport that works on all platforms.
/// Platform-specific connection logic is provided via [createWebSocketChannel].
class WebSocketTransportBase implements ITransport {
  // Properties
  final Logger? _logger;
  final AccessTokenFactory? _accessTokenFactory;
  final bool _logMessageContent;
  final WebSocketChannelFactory _channelFactory;
  final bool _useQueryParamAuth;
  WebSocketChannel? _webSocket;
  StreamSubscription<Object?>? _webSocketListenSub;
  final MessageHeaders? _headers;

  @override
  OnClose? onClose;

  @override
  OnReceive? onReceive;

  // Methods
  WebSocketTransportBase(
    AccessTokenFactory? accessTokenFactory,
    Logger? logger,
    bool logMessageContent,
    MessageHeaders? headers,
    WebSocketChannelFactory channelFactory, {
    bool useQueryParamAuth = true,
  })  : _accessTokenFactory = accessTokenFactory,
        _logger = logger,
        _logMessageContent = logMessageContent,
        _headers = headers,
        _channelFactory = channelFactory,
        _useQueryParamAuth = useQueryParamAuth;

  @override
  Future<void> connect(String? url, TransferFormat transferFormat) async {
    assert(url != null);

    _logger?.finest("(WebSockets transport) Connecting");

    Map<String, String> headers = _headers?.asMap ?? {};

    if (_accessTokenFactory != null) {
      final token = await _accessTokenFactory!();
      if (!isStringEmpty(token)) {
        // On web, we can't set custom headers, so add token to URL
        // On IO, we can set headers
        if (_useQueryParamAuth) {
          final encodedToken = Uri.encodeComponent(token);
          url = url! +
              (url.indexOf("?") < 0 ? "?" : "&") +
              "access_token=$encodedToken";
        } else {
          headers['Authorization'] = 'Bearer $token';
        }
      }
    }

    var websocketCompleter = Completer();
    var opened = false;
    url = url!.replaceFirst('http', 'ws');
    _logger?.finest("WebSocket try connecting to '$url'.");

    try {
      _webSocket = await _channelFactory(url, headers);
      opened = true;
      if (!websocketCompleter.isCompleted) websocketCompleter.complete();
      _logger?.info("WebSocket connected to '$url'.");
      _webSocketListenSub = _webSocket!.stream.listen(
        // onData
        (Object? message) {
          if (_logMessageContent && message is String) {
            _logger?.finest(
                "(WebSockets transport) data received. message ${getDataDetail(message, _logMessageContent)}.");
          } else {
            _logger?.finest("(WebSockets transport) data received.");
          }
          if (onReceive != null) {
            try {
              onReceive!(message);
            } catch (error) {
              _logger?.severe(
                  "(WebSockets transport) error calling onReceive, error: $error");
              _close();
            }
          }
        },

        // onError
        onError: (Object? error) {
          var e = error != null ? error : "Unknown websocket error";
          if (!websocketCompleter.isCompleted) {
            websocketCompleter.completeError(e);
          }
        },

        // onDone
        onDone: () {
          // Don't call close handler if connection was never established
          // We'll reject the connect call instead
          if (opened) {
            if (onClose != null) {
              onClose!();
            }
          } else {
            if (!websocketCompleter.isCompleted) {
              websocketCompleter
                  .completeError("There was an error with the transport.");
            }
          }
        },
      );
    } catch (e) {
      if (!websocketCompleter.isCompleted) {
        websocketCompleter.completeError(e);
      }
      _logger?.severe("WebSocket connection to '$url' failed: $e");
    }

    return websocketCompleter.future;
  }

  @override
  Future<void> send(Object data) {
    if (_webSocket != null) {
      _logger?.finest(
          "(WebSockets transport) sending data. ${getDataDetail(data, true)}.");

      if (data is String) {
        _webSocket!.sink.add(data);
      } else if (data is Uint8List) {
        _webSocket!.sink.add(data);
      } else {
        throw GeneralError("Content type is not handled.");
      }

      return Future.value(null);
    }

    return Future.error(GeneralError("WebSocket is not in the OPEN state"));
  }

  @override
  Future<void> stop() async {
    await _close();
    return Future.value(null);
  }

  _close() async {
    if (_webSocket != null) {
      // Clear websocket handlers because we are considering the socket closed now
      await _webSocketListenSub?.cancel();
      _webSocketListenSub = null;

      _webSocket!.sink.close();
      _webSocket = null;
    }

    _logger?.finest("(WebSockets transport) socket closed.");
    if (onClose != null) {
      onClose!();
    }
  }
}

/// Stub implementation - this should never be called directly.
/// Use conditional imports to get the platform-specific implementation.
WebSocketTransportBase createWebSocketTransport(
  AccessTokenFactory? accessTokenFactory,
  Logger? logger,
  bool logMessageContent,
  MessageHeaders? headers,
) {
  throw UnsupportedError(
      'Cannot create WebSocketTransport without a platform-specific implementation');
}
