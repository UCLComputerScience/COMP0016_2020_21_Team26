import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';

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
  Future<Null> _sendToSelected() async {
    final List<String> contactList = _contacts
        .asMap()
        .entries
        .where((element) => _selected[element.key])
        .map((e) => e.value.phones.first.value)
        .toList(growable: false);

    if (await canSendSMS()) {
      sendSMS(message: widget.toSend, recipients: contactList);
    } else {
      Scaffold.of(context).showSnackBar(
          SnackBar(content: Text("Could not send SMS on this device.")));
    }
  }

  Widget _getAvatar(Contact c) => c.avatar != null && c.avatar.length > 0
      ? CircleAvatar(
          backgroundImage: MemoryImage(c.avatar),
        )
      : CircleAvatar(child: Text(c.initials()));

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
          future: ContactsService.getContacts(),
          builder: (context, futureData) {
            if (futureData.hasData) {
              List<Contact> contacts = futureData.data.toList(growable: false);
              if (_contacts == null || contacts.length != _contacts.length) {
                // contacts must have updated
                _contacts = contacts;
                _selected = List<bool>.generate(
                    contacts.length, (index) => false,
                    growable: false);
              }

              return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, i) => CheckboxListTile(
                        title: Text(contacts[i].displayName != null
                            ? contacts[i].displayName
                            : contacts[i].givenName),
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
