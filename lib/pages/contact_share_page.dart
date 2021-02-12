import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';

/// Displays list of user contacts, that user can select to send.
class ContactSharePage extends StatefulWidget {
  final String toSend;

  const ContactSharePage(this.toSend);

  @override
  State<StatefulWidget> createState() => _ContactSharePageState();
}

class _ContactSharePageState extends State<ContactSharePage> {
  List<bool> _selected;

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton(
      child: Icon(Icons.send),
      tooltip: "Send to selected",
      onPressed: () {
        // TODO: send toSend to selected contacts
      },
    );

    return Scaffold(
      body: FutureBuilder(
          future: ContactsService.getContacts(),
          builder: (context, futureData) {
            if (futureData.hasData) {
              List<Contact> contacts = futureData.data.toList(growable: false);
              _selected = List<bool>.generate(contacts.length, (index) => false,
                  growable: false);

              return ListView.builder(
                  itemBuilder: (context, i) => ListTile(
                        title: Text(contacts[i].displayName),
                        trailing: Checkbox(
                          value: false,
                          onChanged: (val) => _selected[i] = val,
                        ),
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
