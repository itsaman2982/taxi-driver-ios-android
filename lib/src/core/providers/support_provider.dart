import 'package:flutter/material.dart';
import 'package:taxi_driver/src/core/api/api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SupportProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  IO.Socket? _socket;

  List<dynamic> _tickets = [];
  Map<String, dynamic>? _activeTicket;
  List<dynamic> _messages = [];
  bool _isLoading = false;
  bool _isAdminTyping = false;

  List<dynamic> get tickets => _tickets;
  Map<String, dynamic>? get activeTicket => _activeTicket;
  List<dynamic> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isAdminTyping => _isAdminTyping;

  void initSocket(String baseUrl) {
    if (_socket != null) return;
    
    _socket = IO.io(baseUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('🔌 Support Socket Connected');
      if (_activeTicket != null) {
        joinRoom(_activeTicket!['_id']);
      }
    });

    _socket!.on('new_support_message', (data) {
      if (_activeTicket != null && data['ticketId'] == _activeTicket!['_id']) {
        _messages.add(data);
        notifyListeners();
      }
    });

    _socket!.on('support_typing', (data) {
       if (data['senderRole'] == 'admin') {
         _isAdminTyping = data['isTyping'] ?? false;
         notifyListeners();
       }
    });
  }

  void joinRoom(String ticketId) {
    _socket?.emit('join_support', {'ticketId': ticketId});
  }

  Future<bool> createTicket({required String title, String category = 'General', String description = ''}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post('support/tickets', {
        'title': title,
        'category': category,
        'description': description,
        'priority': 'medium',
      });
      if (response['success'] == true) {
        final ticket = response['data'];
        _activeTicket = ticket;
        _messages = [];
        _tickets.insert(0, ticket);
        joinRoom(ticket['_id']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error creating ticket: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchTickets() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('support/tickets');
      if (response['success'] == true) {
        _tickets = response['data'] ?? [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching tickets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String ticketId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('support/tickets/$ticketId');
      if (response['success'] == true) {
        _activeTicket = response['data']['ticket'];
        _messages = response['data']['messages'] ?? [];
        joinRoom(ticketId);
      }
    } catch (e) {
      debugPrint('❌ Error fetching messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String ticketId, String message) async {
    try {
      final response = await _apiService.post('support/tickets/$ticketId/messages', {
        'message': message,
      });
      // Message is appended via socket event usually, but we can also append locally for speed
      if (response['success'] == true) {
        // _messages.add(response['data']);
        // notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
    }
  }

  void setTyping(String ticketId, bool isTyping) {
    _socket?.emit('support_typing', {
      'ticketId': ticketId,
      'isTyping': isTyping,
    });
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}
