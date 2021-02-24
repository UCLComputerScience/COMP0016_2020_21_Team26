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
  List<ContactSelection> _contactSelection;

  /// send sms to currently selected contacts.
  Future<Null> _sendToSelected() async {
    final List<String> contactList = _contactSelection
        .where((selection) => selection.selected)
        .map((e) => e.contact.phones.first.value)
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

  void _updateAvatars() async {
    _contactSelection.forEach((contactSelection) async {
      final avatar =
          await ContactsService.getAvatar(contactSelection.contact, photoHighRes: false);
      if (avatar != null) {
        setState(() {
          contactSelection.contact.avatar = avatar;
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
              if (_contactSelection == null || contacts.length != _contactSelection.length) {
                // contacts must have updated
                _contactSelection = contacts.map((contact) => ContactSelection(contact));
                _updateAvatars();
              }

              return ListView.builder(
                  itemCount: _contactSelection.length,
                  itemBuilder: (context, i) => CheckboxListTile(
                        title: Text(_contactSelection[i].contact.displayName != null
                            ? _contactSelection[i].contact.displayName
                            : _contactSelection[i].contact.givenName),
                        secondary: _getAvatar(contacts[i]),
                        selected: _contactSelection[i].selected,
                        value: _contactSelection[i].selected,
                        onChanged: (bool value) =>
                            setState(() => _contactSelection[i].selected = value),
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

class ContactSelection {
  final Contact contact;
  bool selected = false;

  ContactSelection(this.contact);
}
