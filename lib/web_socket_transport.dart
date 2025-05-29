import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:signalr_netcore/ihub_protocol.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'errors.dart';
import 'itransport.dart';
import 'utils.dart';

class WebSocketTransport implements ITransport {
  // Properties

  final Logger? _logger;
  final AccessTokenFactory? _accessTokenFactory;
  final bool _logMessageContent;
  WebSocketChannel? _webSocket;
  StreamSubscription<Object?>? _webSocketListenSub;
  MessageHeaders? _headers;

  @override
  OnClose? onClose;

  @override
  OnReceive? onReceive;

  // Methods
  WebSocketTransport(AccessTokenFactory? accessTokenFactory, Logger? logger,
      bool logMessageContent, MessageHeaders? headers)
      : _accessTokenFactory = accessTokenFactory,
        _logger = logger,
        _logMessageContent = logMessageContent,
        _headers = headers;

  @override
  Future<void> connect(String? url, TransferFormat transferFormat) async {
    assert(url != null);

    _logger?.finest("(WebSockets transport) Connecting");

    Map<String, String> headers = _headers?.asMap ?? {};

    if (_accessTokenFactory != null) {
      final token = await _accessTokenFactory!();
      if (!isStringEmpty(token)) {
        if (kIsWeb) {
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
      if (kIsWeb) {
        _webSocket = WebSocketChannel.connect(Uri.parse(url));
      } else {
        final webSocket = await io.WebSocket.connect(url, headers: headers);
        _webSocket = IOWebSocketChannel(webSocket);
      }
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
      //_logger?.finest("(WebSockets transport) sending data.");

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
