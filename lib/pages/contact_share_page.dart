import 'dart:io';

import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Displays list of user contacts that can be selected to send.
class ContactSharePage extends StatefulWidget {
  final String toSend;

  const ContactSharePage(this.toSend);

  @override
  State<StatefulWidget> createState() => _ContactSharePageState();
}

class _ContactSharePageState extends State<ContactSharePage> {
  List<Contact> _contacts;
  List<bool> _selected;

  /// send sms to currently selected contacts.
  /// Note: doesn't actually execute the sending, just prepares it for the user
  /// and they can hit send themself.
  Future<Null> _sendToSelected() async {
    final csvNumbers = _contacts
        .asMap()
        .entries
        .where((element) => _selected[element.key])
        .map((e) => e.value.phones.first.value)
        .join(",");
    // HACK: Android and iOS parse the sms scheme differently:
    final sep = Platform.isIOS ? '&' : '?';
    // NOTE: this may not work with some messaging apps, in particular, the message
    //       body may not be parse correctly. THIS IS THE MESSAGING APPS'S FAULT,
    //       they aren't following the IANA sms scheme.
    final uri = "sms:$csvNumbers${sep}body=${Uri.encodeComponent(widget.toSend)}";

    if (await canLaunch(uri)) {
      launch(uri);
      print("Launched: $uri");
    }
  }

  Widget _getAvatar(Contact c) => c.avatar != null && c.avatar.length > 0
      ? CircleAvatar(
          backgroundImage: MemoryImage(c.avatar),
        )
      : CircleAvatar(child: Text(c.initials()));

  void _updateAvatars() async {
    _contacts.forEach((contact) async {
        final avatar = await ContactsService.getAvatar(contact, photoHighRes: false);
        if (avatar != null) {
          setState(() {
              contact.avatar = avatar;
          });
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton(
      child: Icon(Icons.send),
      tooltip: "Send to selected",
      onPressed: () {
        _sendToSelected();
        Navigator.pop(context);
      },
    );

    return Scaffold(
      body: FutureBuilder(
          future: ContactsService.getContacts(withThumbnails: false),
          builder: (context, futureData) {
            if (futureData.hasData) {
              List<Contact> contacts = futureData.data.toList(growable: false);
              if (_contacts == null || contacts.length != _contacts.length) {
                // contacts must have updated
                _contacts = contacts;
                _updateAvatars();
                _selected = List<bool>.generate(
                    contacts.length, (index) => false,
                    growable: false);
              }

              return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, i) => CheckboxListTile(
                        title: Text(contacts[i].displayName),
                        secondary: _getAvatar(contacts[i]),
                        selected: _selected[i],
                        value: _selected[i],
                        onChanged: (bool value) =>
                            setState(() => _selected[i] = value),
                      ));
            } else if (futureData.hasError) {
              print(futureData.error);
              return Text("Could not fetch contacts.");
            }
            return LinearProgressIndicator();
          }),
      appBar: AppBar(
        title: Text("Select contacts"),
      ),
      floatingActionButton: fab,
    );
  }
}
