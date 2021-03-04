import 'dart:io';

import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';

/// Displays list of user contacts that can be selected to send.
/// The 'Share link using SMS' button on the Support Network page opens this page.
class ContactSharePage extends StatefulWidget {
  final String toSend;

  const ContactSharePage(this.toSend);

  @override
  State<StatefulWidget> createState() => _ContactSharePageState();
}

class _ContactSharePageState extends State<ContactSharePage> {
  List<ContactSelection> _contactSelection;

  /// Sends sms to currently selected contacts.
  Future<Null> _sendToSelected() async {
    final List<String> contactList = _contactSelection
        .where((selection) => selection.selected)
        .map((e) => e.contact.phones.first.value)
        .toList(growable: false);

    if (await canSendSMS()) {
      sendSMS(message: widget.toSend, recipients: contactList);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not send SMS on this device.")));
    }
  }

  Widget _getAvatar(Contact c) => c.avatar != null && c.avatar.length > 0
      ? CircleAvatar(
          backgroundImage: MemoryImage(c.avatar),
        )
      : CircleAvatar(child: Text(c.initials()));

  /// updates the avatars (if on Android:)
  /// https://github.com/lukasgit/flutter_contacts/issues/155
  void _updateAvatars() async {
    if (Platform.isAndroid) {
      _contactSelection.forEach((contactSelection) async {
        final avatar = await ContactsService.getAvatar(contactSelection.contact,
            photoHighRes: false);
        if (avatar != null) {
          setState(() {
            contactSelection.contact.avatar = avatar;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ///Send button as [FloatingActionButton]
    final fab = FloatingActionButton(
      child: Icon(Icons.send),
      tooltip: "Send to selected",
      onPressed: () {
        _sendToSelected();
        Navigator.pop(context);
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Select contacts"),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: () => showSearch(
                    context: context,
                    delegate: ContactSelectionSearch(_contactSelection))
                .then((_) => setState(() {})),
          ),
        ],
      ),
      body: FutureBuilder(
          future: ContactsService.getContacts(withThumbnails: Platform.isIOS),
          builder: (context, futureData) {
            if (futureData.hasData) {
              List<Contact> contacts = futureData.data.toList(growable: false);
              if (_contactSelection == null ||
                  contacts.length != _contactSelection.length) {
                // contacts must have updated
                _contactSelection = contacts
                    .map((contact) => ContactSelection(contact))
                    .toList();
                _updateAvatars();
              }

              ///List of contacts
              return ListView.builder(
                  itemCount: _contactSelection.length,
                  itemBuilder: (context, i) => CheckboxListTile(
                        title: Text(
                            _contactSelection[i].contact.displayName != null
                                ? _contactSelection[i].contact.displayName
                                : _contactSelection[i].contact.givenName),
                        secondary: _getAvatar(contacts[i]),
                        selected: _contactSelection[i].selected,
                        value: _contactSelection[i].selected,
                        onChanged: (bool value) => setState(
                            () => _contactSelection[i].selected = value),
                      ));
            } else if (futureData.hasError) {
              print(futureData.error);
              return Text("Could not fetch contacts.");
            }
            return LinearProgressIndicator();
          }),
      floatingActionButton: fab,
    );
  }
}

class ContactSelection {
  final Contact contact;
  bool selected = false;

  ContactSelection(this.contact);
}

class ContactSelectionSearch extends SearchDelegate<ContactSelection> {
  final List<ContactSelection> _contactSelection;

  ContactSelectionSearch(this._contactSelection);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => query = '',
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  bool _matchesQuery(Contact contact, String q) {
    q = q.toLowerCase();
    return (contact.displayName != null &&
            contact.displayName.toLowerCase().contains(q)) ||
        (contact.givenName != null &&
            contact.givenName.toLowerCase().contains(q));
  }

  Widget _getStatefulListView() => StatefulBuilder(
        builder: (context, StateSetter setState) {
          final items = _contactSelection
              .where((selection) => _matchesQuery(selection.contact, query))
              .toList();
          return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) => CheckboxListTile(
                    title: Text(items[i].contact.displayName != null
                        ? items[i].contact.displayName
                        : items[i].contact.givenName),
                    selected: items[i].selected,
                    value: items[i].selected,
                    onChanged: (bool value) =>
                        setState(() => items[i].selected = value),
                  ));
        },
      );

  @override
  Widget buildResults(BuildContext context) {
    return _getStatefulListView();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _getStatefulListView();
  }
}
