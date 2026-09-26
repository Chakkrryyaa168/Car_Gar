import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static const String _defaultWsUrl = 'ws://127.0.0.1:8000/ws';
  final String baseWsUrl;
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _isConnected = false;
  String? _currentTicketId;

  WebSocketService({this.baseWsUrl = _defaultWsUrl});

  Stream<Map<String, dynamic>> get stream => _messageController.stream;
  bool get isConnected => _isConnected;
  String? get currentTicketId => _currentTicketId;

  void connect({String? ticketId}) {
    disconnect();
    _currentTicketId = ticketId;

    final url = ticketId != null
        ? '$baseWsUrl/tickets/$ticketId/'
        : '$baseWsUrl/tickets/';

    try {
      if (kDebugMode) {
        print('Connecting WebSocket to: $url');
      }
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;

      _channel?.stream.listen(
        (data) {
          try {
            final parsed = jsonDecode(data.toString());
            if (kDebugMode) {
              print('WebSocket event received: $parsed');
            }
            _messageController.add(parsed);
          } catch (e) {
            if (kDebugMode) {
              print('Error decoding websocket message: $e');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('WebSocket stream error: $error');
          }
          _isConnected = false;
        },
        onDone: () {
          if (kDebugMode) {
            print('WebSocket disconnected.');
          }
          _isConnected = false;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('WebSocket connection exception: $e');
      }
      _isConnected = false;
    }
  }

  void sendPing() {
    if (_isConnected && _channel != null) {
      _channel?.sink.add(jsonEncode({'action': 'ping'}));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _currentTicketId = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
