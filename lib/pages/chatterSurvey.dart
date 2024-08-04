import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tastee_app/pages/utils/constants.dart';
import 'package:tastee_app/pages/utils/loading_dialog.dart';

String username = 'User';
String email = 'user@example.com';
String userId = '1';
String messageText = '';
User? loggedInUser;

class ChatterSurvey extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<ChatterSurvey> {
  List<String> sentenceandanswer = [];
  List<String> sentenceTemplate = [];
  List<String> answerTemplate = [];
  String currentSentenceTemplate = "";
  List<String> currentAnswerTemplate = [];
  String sentenceKey = "";
  int currentIndex = 0;
  User? user;
  bool isLoading = true;
  Map<String, String> fetchedSentences = {'a': 'a'};
  Map<String, List> fetchedAnswers = {
    'a': ['a']
  };
  List<Map<String, dynamic>> completedSentences = [];
  List<Map<String, dynamic>> allCompletedSentences = [];
  String? _cachedToken;
  DateTime? _tokenExpirationTime;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    showLoadingDialog(context);
    await getCurrentUser();
    await fetchSentenceTemplatesFromAPI();
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
      return _cachedToken;
    } catch (e) {
      print("Error getting ID token: $e");
      return null;
    }
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

  Future<void> fetchSentenceTemplatesFromAPI() async {
    if (user == null) {
      print("No user is currently signed in.");
      // 적절한 처리 (예: 로그인 화면으로 리디렉션)
      return;
    }
    try {
      if (_cachedToken == null) {
        throw Exception('Failed to get authentication token');
      }

      final response = await http.get(
        Uri.parse("${NameBox.apiURL}/sentences"),
        headers: {
          'Authorization': 'Bearer $_cachedToken',
        },
      );
      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        List<dynamic> data = json.decode(responseBody);
        fetchedSentences = Map<String, String>.from(data[0]);
        fetchedAnswers = Map<String, List>.from(data[1]);
        sentenceKey = fetchedSentences.keys.toList()[currentIndex];
        setState(() {
          if (fetchedSentences.isNotEmpty) {
            currentSentenceTemplate = fetchedSentences[sentenceKey] as String;
            currentAnswerTemplate =
                List<String>.from(fetchedAnswers[sentenceKey] as List);
            print(currentAnswerTemplate);
          }
        });
        print('sucess');
      } else {
        throw Exception('Failed to load sentences from API');
      }
    } catch (e) {
      print("Error fetching sentence templates: $e");
      showErrorDialog('Data Load Error', 'Failed to load sentence templates.');
    }
  }

  void sendToAPI(List<Map<String, dynamic>> sentenceList) async {
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

    if (token == null) {
      print("User not authenticated");
      return;
    }
    var response = await http.post(
      Uri.parse('${NameBox.apiURL}/items/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id': DateTime.now().toString(),
        'sentence_list': sentenceList,
        'user_id': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }),
    );

    if (response.statusCode == 201) {
      print("Data sent successfully");
    } else {
      print("Failed to send data");
    }
  }

  void completeSentence(String answer) {
    String completedSentence =
        currentSentenceTemplate.replaceFirst("**", answer);
    setState(() {
      completedSentences
          .add({'sentence': completedSentence, 'theme': sentenceKey});
    });
  }

  void nextButtonPressed() async {
    await Future.delayed(Duration(milliseconds: 300));
    setState(() {
      allCompletedSentences.addAll(completedSentences);
      completedSentences.clear();
      currentIndex = (currentIndex + 1) % fetchedSentences.length;
      sentenceKey = fetchedSentences.keys.toList()[currentIndex];
      if (fetchedSentences.isNotEmpty) {
        currentSentenceTemplate = fetchedSentences[sentenceKey] as String;
        currentAnswerTemplate =
            List<String>.from(fetchedAnswers[sentenceKey] as List);
      }
    });
  }

  void completeButtonPressed() {
    allCompletedSentences.addAll(completedSentences);

    sendToAPI(allCompletedSentences);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Survey Completed!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
          content: Text(
              'Thank you for completing the Survey! \n Your personalized recommendations are ready. \n Click to use your personalized LLM now!',
              style: TextStyle(fontSize: 18)),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/chat');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choice your Taste!'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (user != null) SizedBox(height: 20),
                Text(
                  "Drag and drop the answer names to complete the sentence below:",
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width:
                      MediaQuery.of(context).size.width * 0.8, // 화면 너비의 80%로 설정
                  child: Wrap(
                    spacing: 20.0,
                    runSpacing: 20.0,
                    alignment: WrapAlignment.start,
                    children: currentAnswerTemplate
                        .map((answer) => Draggable<String>(
                              data: answer,
                              child: AnswerChip(label: answer),
                              feedback: Material(
                                child: AnswerChip(label: answer),
                                elevation: 4.0,
                              ),
                              childWhenDragging:
                                  AnswerChip(label: answer, isGhost: true),
                            ))
                        .toList(),
                  ),
                ),
                SizedBox(height: 20),
                DragTarget<String>(
                  onAccept: (receivedAnswer) {
                    completeSentence(receivedAnswer);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(30),
                          margin: EdgeInsets.only(top: 30),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 110, 57, 201),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currentSentenceTemplate.replaceFirst("**", "___"),
                            style: TextStyle(
                                fontSize: 24,
                                color: const Color.fromARGB(255, 255, 255, 255),
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 100),
                Expanded(
                  child: ListView.builder(
                    itemCount: completedSentences.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                            completedSentences[index]['sentence'] as String,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        leading: Icon(Icons.note_alt, color: Colors.deepPurple),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                if (currentIndex == fetchedSentences.length - 1)
                  ElevatedButton(
                    onPressed: completeButtonPressed,
                    child: Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: 40.0, vertical: 20.0),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: nextButtonPressed,
                    child: Text('Next'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: 40.0, vertical: 20.0),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnswerChip extends StatelessWidget {
  final String label;
  final bool isGhost;

  AnswerChip({required this.label, this.isGhost = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      // margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isGhost ? Colors.grey[200] : Color.fromARGB(255, 147, 103, 224),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          if (!isGhost)
            BoxShadow(
              color: Color.fromARGB(255, 147, 103, 224).withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 4,
            ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isGhost ? Colors.black54 : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
