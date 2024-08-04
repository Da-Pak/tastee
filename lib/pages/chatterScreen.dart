import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/constants.dart';
import 'drawer_menu.dart';
import 'utils/conversation.dart';
import 'package:tastee_app/pages/utils/loading_dialog.dart';

String username = 'User';
String email = 'user@example.com';
String userId = '1';
String messageText = '';
User? loggedInUser;
User? user;

class ChatterScreen extends StatefulWidget {
  @override
  _ChatterScreenState createState() => _ChatterScreenState();
}

class _ChatterScreenState extends State<ChatterScreen>
    with SingleTickerProviderStateMixin {
  final chatMsgTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final FocusNode _focusNode = FocusNode();
  bool isLoading = true;
  List<MessageBubble> _messages = [];
  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  late AnimationController _animationController;
  late Animation<int> _animation;
  String? _cachedToken;
  DateTime? _tokenExpirationTime;

  @override
  void initState() {
    super.initState();
    initializeData();

    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1))
          ..repeat();
    _animation = IntTween(begin: 1, end: 5).animate(_animationController);
  }

  Future<void> initializeData() async {
    showLoadingDialog(context);
    await getCurrentUser();
    await fetchConversations();
    hideLoadingDialog(context);
  }

  Future<String?> getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    // 캐시된 토큰이 있고 아직 유효한 경우 재사용
    if (_cachedToken != null &&
        _tokenExpirationTime != null &&
        DateTime.now().isBefore(_tokenExpirationTime!)) {
      return _cachedToken;
    }

    // 새 토큰 발급
    try {
      _cachedToken = await user.getIdToken();
      // 토큰 만료 시간을 현재 시간 + 50분으로 설정 (1시간보다 약간 짧게 설정)
      _tokenExpirationTime = DateTime.now().add(Duration(minutes: 50));
      print('cashed token');
      print(_cachedToken);
      return _cachedToken;
    } catch (e) {
      print("Error getting ID token: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> getCurrentUser() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setState(() {
          user = currentUser;
          loggedInUser = currentUser;
          username = loggedInUser?.displayName ?? 'User';
          email = loggedInUser?.email ?? 'user@example.com';
          userId = loggedInUser?.uid ?? '1';
        });
        String? token = await getIdToken();
        print("User ID Token: $token");
      } else {
        print("No user is currently signed in.");
      }
    } catch (e) {
      print("Error in getCurrentUser: $e");
      showErrorDialog('Authentication Error', 'Failed to get current user.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> sendMessage() async {
    if (_cachedToken == null) {
      throw Exception('Failed to get authentication token');
    }
    if (_currentConversation == null || messageText.isEmpty) return;
    final newMessage = Message(
      id: DateTime.now().toString(),
      text: messageText,
      sender: username,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    addMessageToList(newMessage, true);
    chatMsgTextController.clear();
    final url = Uri.parse('${NameBox.apiURL}/messages/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_cachedToken',
        },
        body: jsonEncode({
          'id': newMessage.id,
          'conversation_id': _currentConversation?.id,
          'text': newMessage.text,
          'timestamp': newMessage.timestamp,
          'sender': newMessage.sender,
          'user_id': userId,
        }),
      );
      if (response.statusCode == 200) {
        var responseData = jsonDecode(utf8.decode(response.bodyBytes));
        var gptResponse = responseData['gpt_response'];
        addMessageToList(
            Message(
              id: gptResponse['id'],
              text: gptResponse['text'],
              sender: gptResponse['sender'],
              timestamp: gptResponse['timestamp'],
            ),
            false);
      } else {
        showErrorDialog('Error', 'Failed to send message');
      }
    } catch (e) {
      showErrorDialog('Error', 'Failed to send message');
    } finally {
      _focusNode.requestFocus();
    }
  }

  void addMessageToList(Message message, bool is_question) {
    setState(() {
      _currentConversation?.messages.insert(0, message);
      _currentConversation?.messages
          .sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _messages = _currentConversation!.messages
          .map((message) => MessageBubble(
                msgText: message.text,
                msgSender: 'me',
                user: message.sender == username,
                timestamp: message.timestamp,
              ))
          .toList();
      if (is_question) {
        _messages.insert(
          0,
          MessageBubble(
            msgText: '...',
            msgSender: 'AI',
            user: false,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            isLoading: true,
            animation: _animation,
          ),
        );
      }
    });
  }

  Future<void> fetchConversations() async {
    if (_cachedToken == null) {
      throw Exception('Failed to get authentication token');
    }

    final url =
        Uri.parse('${NameBox.apiURL}/conversations_with_messages/$userId');
    print('fetch');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_cachedToken'},
      );
      print('fetch2');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        print('data');
        print(data);

        if (data.isEmpty) {
          createConversation('new conversation');
          return; // 빈 데이터이므로 더 이상 진행하지 않음
        }

        List<Conversation> conversations = data
            .map((conversation) => Conversation.fromJson(conversation))
            .toList();
        conversations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        print('processing');
        setState(() {
          _conversations = conversations;
          print(conversations);
        });
        print('conversations');
        print(_conversations);
        if (_conversations.isNotEmpty) {
          handleConversationSelect(_conversations[0]);
        }
      } else {
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      showErrorDialog('Error', e.toString());
    }
  }

  Future<void> createConversation(String title) async {
    if (_cachedToken == null) {
      throw Exception('Failed to get authentication token');
    }
    print('created');
    try {
      final response = await http.post(
        Uri.parse('${NameBox.apiURL}/create_conversation/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_cachedToken',
        },
        body: jsonEncode({
          'id': DateTime.now().toString(),
          'title': title,
          'user_id': userId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'messages': [],
        }),
      );
      print('response');
      print(response);
      if (response.statusCode == 201) {
        fetchConversations();
      } else {
        showErrorDialog('Error', 'Failed to create conversation');
      }
    } catch (e) {
      showErrorDialog('Error', 'Failed to create conversation');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    if (_cachedToken == null) {
      throw Exception('Failed to get authentication token');
    }
    final url =
        Uri.parse('${NameBox.apiURL}/delete_conversation/$conversationId');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $_cachedToken'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _conversations.removeWhere((conv) => conv.id == conversationId);
          if (_currentConversation?.id == conversationId) {
            _currentConversation =
                _conversations.isNotEmpty ? _conversations[0] : null;
            _messages = _currentConversation?.messages
                    .map((message) => MessageBubble(
                          msgText: message.text,
                          msgSender: message.sender,
                          user: message.sender == username,
                          timestamp: message.timestamp,
                        ))
                    .toList() ??
                [];
          }
        });
      } else {
        showErrorDialog('Error', 'Failed to delete conversation');
      }
    } catch (e) {
      showErrorDialog('Error', 'Failed to delete conversation');
    }
  }

  void handleConversationSelect(Conversation conversation) {
    setState(() {
      _currentConversation = conversation;
      _currentConversation?.messages
          .sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _messages = _currentConversation!.messages
          .map((message) => MessageBubble(
                msgText: message.text,
                msgSender: message.sender,
                user: message.sender == username,
                timestamp: message.timestamp,
              ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: AppBar(
              iconTheme: IconThemeData(color: Colors.deepPurple),
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: Size(25, 10),
                child: Container(
                  child: LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    backgroundColor: Colors.blue[100],
                  ),
                  constraints: BoxConstraints.expand(height: 1),
                ),
              ),
              backgroundColor: Colors.white10,
              title: Row(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        NameBox.appName,
                        style: TextStyle(
                            fontSize: 24,
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(NameBox.appMaker,
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.deepPurple,
                          )),
                    ],
                  ),
                  SizedBox(width: 20), // 간격 조정
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 20), // 간격 조정
                  Expanded(
                    child: Row(
                      children: [
                        if (_currentConversation != null)
                          Flexible(
                            child: Text(
                              _currentConversation!.title,
                              style: TextStyle(
                                fontSize: 36,
                                color: const Color.fromARGB(255, 81, 45, 142),
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Spacer(flex: 1), // 오른쪽 빈 공간
                      ],
                    ),
                  ),
                ],
              ),
            ),
            drawer: DrawerMenu(
              username: username,
              email: email,
              userId: userId,
              auth: _auth,
              onConversationSelect: handleConversationSelect,
              conversations: _conversations,
              createConversation: createConversation,
              deleteConversation: deleteConversation,
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: ListView(
                    reverse: true,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    children: _messages,
                  ),
                ),
                buildMessageComposer(),
              ],
            ),
          );
  }

  Widget buildMessageComposer() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: kMessageContainerDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Material(
              borderRadius: BorderRadius.circular(50),
              color: Colors.white,
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 2, bottom: 2),
                child: TextField(
                  focusNode: _focusNode,
                  onChanged: (value) {
                    messageText = value;
                  },
                  onSubmitted: (val) {
                    sendMessage();
                  },
                  controller: chatMsgTextController,
                  decoration: kMessageTextFieldDecoration,
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
          MaterialButton(
            shape: CircleBorder(),
            color: Colors.blue,
            onPressed: () {
              sendMessage();
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String msgText;
  final String msgSender;
  final bool user;
  final int timestamp;
  final bool isLoading;
  final Animation<int>? animation;

  MessageBubble({
    required this.msgText,
    required this.msgSender,
    required this.user,
    required this.timestamp,
    this.isLoading = false,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment:
            user ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              msgSender,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          Material(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              topLeft: user ? Radius.circular(50) : Radius.circular(0),
              bottomRight: Radius.circular(50),
              topRight: user ? Radius.circular(0) : Radius.circular(50),
            ),
            color: user ? Colors.blue : Colors.white,
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: isLoading
                  ? AnimatedBuilder(
                      animation: animation!,
                      builder: (context, child) {
                        String dots = '·' * animation!.value;
                        return Text(
                          dots,
                          style: TextStyle(
                            color: user ? Colors.white : Colors.blue,
                            fontSize: 25,
                          ),
                        );
                      },
                    )
                  : SelectableText(
                      msgText,
                      style: TextStyle(
                        color: user ? Colors.white : Colors.blue,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
