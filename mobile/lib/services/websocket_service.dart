import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../models/activity_result.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _token;
  Timer? _reconnectTimer;
  final _statusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _statusController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String token) async {
    _token = token;
    _doConnect();
  }

  void _doConnect() {
    if (_token == null) return;

    try {
      final wsUrl = '${AppConfig.wsUrl}/ws/stream?token=$_token';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      if (!_statusController.isClosed) {
        _statusController.add(true);
      }

      _channel!.stream.listen(
        (message) {
          // Server may send commands or acknowledgements
        },
        onError: (error) => _handleDisconnect(),
        onDone: () => _handleDisconnect(),
      );
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    if (!_statusController.isClosed) {
      _statusController.add(false);
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _doConnect);
  }

  void sendActivity(ActivityResult result) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(result.toJson()));
      } catch (e) {
        _handleDisconnect();
      }
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _isConnected = false;
    if (!_statusController.isClosed) {
      _statusController.add(false);
    }
  }

  void dispose() {
    disconnect();
    _statusController.close();
  }
}
