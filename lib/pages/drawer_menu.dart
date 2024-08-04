import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/conversation.dart';

class DrawerMenu extends StatefulWidget {
  final String username;
  final String email;
  final String userId;
  final FirebaseAuth auth;
  final Function(Conversation) onConversationSelect;
  final List<Conversation> conversations;
  final Function(String) createConversation;
  final Function(String) deleteConversation;

  DrawerMenu({
    required this.username,
    required this.email,
    required this.userId,
    required this.auth,
    required this.onConversationSelect,
    required this.conversations,
    required this.createConversation,
    required this.deleteConversation,
  });

  @override
  _DrawerMenuState createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey _menuKey = GlobalKey();
  User? user;
  String? nickname;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    user = widget.auth.currentUser;
    if (user != null) {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userData =
          await _firestore.collection('users').doc(user!.uid).get();
      setState(() {
        nickname = userData['nickname'];
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch user data';
      });
    }
  }

  Future<void> _updatePassword(String oldPassword, String newPassword) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: oldPassword,
      );
      await user!.reauthenticateWithCredential(credential);
      await user!.updatePassword(newPassword);

      setState(() {
        _successMessage = 'Password updated successfully';
        _errorMessage = '';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Password update failed';
      });
    }
  }

  Future<void> _updateNickname(String newNickname) async {
    try {
      await _firestore
          .collection('users')
          .doc(user!.uid)
          .update({'nickname': newNickname});
      setState(() {
        nickname = newNickname;
        _successMessage = 'Nickname updated successfully';
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Nickname update failed';
      });
    }
  }

  Future<void> _showPasswordUpdateDialog() async {
    TextEditingController oldPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Password'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: oldPasswordController,
                  decoration: InputDecoration(labelText: 'Old Password'),
                  obscureText: true,
                ),
                TextField(
                  controller: newPasswordController,
                  decoration: InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                ),
                TextField(
                  controller: confirmPasswordController,
                  decoration:
                      InputDecoration(labelText: 'Confirm New Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Update'),
              onPressed: () {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  setState(() {
                    _errorMessage = 'New passwords do not match';
                  });
                  return;
                }
                _updatePassword(
                    oldPasswordController.text, newPasswordController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNicknameUpdateDialog() async {
    TextEditingController newNicknameController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Nickname'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: newNicknameController,
                  decoration: InputDecoration(labelText: 'New Nickname'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Update'),
              onPressed: () {
                _updateNickname(newNicknameController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          _buildUserAccountHeader(),
          _buildNewConversationTile(context),
          ..._buildConversationList(context),
          _buildLogoutTile(context),
        ],
      ),
    );
  }

  Widget _buildUserAccountHeader() {
    return UserAccountsDrawerHeader(
        key: _menuKey,
        // decoration: BoxDecoration(
        //   color: Color.fromARGB(255, 96, 77, 178),
        // ),
        accountName: Text(widget.username),
        accountEmail: Text(widget.email),
        // currentAccountPicture: CircleAvatar(
        //   child: Text(widget.username[0],),
        // ),
        onDetailsPressed: () {
          _showPopupMenu(context);
        },
        decoration: BoxDecoration(
            color: Color.fromARGB(255, 96, 77, 178),
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(40.0),
            )));
  }

  void _showPopupMenu(BuildContext context) async {
    final RenderBox renderBox =
        _menuKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    print(size);

    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + size.width / 11 * 10,
        offset.dy + size.height / 7 * 6,
        offset.dx + size.width,
        offset.dy,
      ),
      items: [
        PopupMenuItem(
          child: Text('Change Nickname'),
          value: 'change_nickname',
        ),
        PopupMenuItem(
          child: Text('Change Password'),
          value: 'change_password',
        ),
        PopupMenuItem(
          child: Text('Change Taste'),
          value: 'change_taste',
        ),
      ],
      elevation: 8.0,
    ).then((value) {
      if (value == 'change_nickname') {
        _showNicknameUpdateDialog();
      } else if (value == 'change_password') {
        _showPasswordUpdateDialog();
      } else if (value == 'change_taste') {
        Navigator.pushNamed(context, '/tastesurvey');
      }
    });
  }

  List<Widget> _buildConversationList(BuildContext context) {
    int conv_length = widget.conversations.length;
    if (conv_length != 0) {
      widget.conversations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    return conv_length != 0
        ? widget.conversations.map((conversation) {
            return ListTile(
              title: Text(conversation.title),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete,
                  size: 20,
                ),
                onPressed: () {
                  _showDeleteConfirmationDialog(context, conversation.id);
                },
              ),
              onTap: () {
                widget.onConversationSelect(conversation);
              },
            );
          }).toList()
        : [Text('No conversations available')];
  }

  Widget _buildNewConversationTile(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.add),
      title: Text("New Conversation"),
      onTap: () {
        _showNewConversationDialog(context);
      },
    );
  }

  void _showNewConversationDialog(BuildContext context) {
    TextEditingController newConversationController = TextEditingController();
    void createNewConversation() {
      Navigator.of(context).pop();
      widget.createConversation(newConversationController.text);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("New Conversation"),
          content: TextField(
            controller: newConversationController,
            decoration: InputDecoration(
              hintText: "Enter conversation title",
            ),
            onSubmitted: (val) {
              createNewConversation();
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Create"),
              style: TextButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 217, 213, 237)),
              onPressed: createNewConversation,
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, String conversationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Conversation"),
          content: Text("Are you sure you want to delete this conversation?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Delete"),
              style: TextButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 237, 213, 213)),
              onPressed: () {
                Navigator.of(context).pop();
                widget.deleteConversation(conversationId);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.exit_to_app),
      title: Text("Logout"),
      subtitle: Text("Sign out of this account"),
      onTap: () async {
        await widget.auth.signOut();
        Navigator.pushReplacementNamed(context, '/');
      },
      tileColor: Color.fromARGB(207, 215, 215, 215),
    );
  }
}
