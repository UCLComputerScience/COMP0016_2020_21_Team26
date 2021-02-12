import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';

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

  Future<Null> _sendToSelected() {
    // TODO
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
