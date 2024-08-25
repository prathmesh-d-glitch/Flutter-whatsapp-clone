import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_messenger/common/enum/message_type.dart';
import 'package:whatsapp_messenger/common/extension/custom_theme_extension.dart';
import 'package:whatsapp_messenger/common/models/user_model.dart';
import 'package:whatsapp_messenger/common/routes/routes.dart';
import 'package:whatsapp_messenger/common/utils/coloors.dart';
import 'package:whatsapp_messenger/common/widgets/custom_icon_button.dart';
import 'package:whatsapp_messenger/feature/chat/controller/chat_controller.dart';
import 'package:whatsapp_messenger/feature/contact/controller/contacts_controller.dart';

import 'package:whatsapp_messenger/feature/contact/widget/contact_card.dart';

class SendContactPage extends ConsumerStatefulWidget {
  const SendContactPage( {super.key, required this.receiverId,});

  final receiverId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _SendContactPageState();
  }
}

class _SendContactPageState extends ConsumerState<SendContactPage> {
  final List<UserModel> selectedContacts = [];

  void selectContact(UserModel contact) {
    if (selectedContacts.length >= 5) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('limit is only 5 contacts')));
      return;
    }
    setState(() {
      if (selectedContacts.contains(contact)) {
        selectedContacts.remove(contact);
        return;
      }
      selectedContacts.add(contact);
    });
  }

  void sendContactsMessage() {
    for(UserModel contacts in selectedContacts) {
      sendFileMessage(contacts, MessageType.contact);
    }
    Navigator.of(context).pop();
  }

  void sendFileMessage(var file, MessageType messageType) async {
    ref.read(chatControllerProvider).sendFileMessage(
          context,
          (file is UserModel) ? file.username : '',
          file,
          widget.receiverId,
          messageType,
        );
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contacts to send',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${selectedContacts.length} selected',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          CustomIconButton(onPressed: () {}, icon: Icons.search),
        ],
      ),
      body: ref.watch(contactsControllerProvider).when(
        data: (allContacts) {
          return ListView.builder(
            itemCount: allContacts[0].length + allContacts[1].length,
            itemBuilder: (context, index) {
              late UserModel phoneContacts;

              if (index < allContacts[0].length) {
                phoneContacts = allContacts[0][index];
              } else {
                phoneContacts = allContacts[1][index - allContacts[0].length];
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index == 0)
                    const Divider(
                      color:
                          Color.fromARGB(255, 52, 64, 74), // Color of the line
                      thickness: 1, // Thickness of the line
                      indent: 12, // Start padding
                      endIndent: 12, // End padding
                    ),
                  if (index == 0)
                    Row(
                      children: selectedContacts.map((contactSource) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    context.theme.greyColor!.withOpacity(.3),
                                radius: 20,
                                backgroundImage:
                                    contactSource.profileImageUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            contactSource.profileImageUrl)
                                        : null,
                                child: contactSource.profileImageUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                contactSource.username,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  if (index == 0 && selectedContacts.isNotEmpty)
                    const Divider(
                      color:
                          Color.fromARGB(255, 52, 64, 74), // Color of the line
                      thickness: 1, // Thickness of the line
                      indent: 12, // Start padding
                      endIndent: 12, // End padding
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    child: ContactCard(
                      contactSource: phoneContacts,
                      chat: false,
                      onTap: () {
                        selectContact(phoneContacts);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
        error: (e, t) {
          return null;
        },
        loading: () {
          return Center(
            child: CircularProgressIndicator(
              color: context.theme.authAppbarTextColor,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromRGBO(33, 192, 99, 1),
        onPressed: sendContactsMessage,
        child: Icon(
          Icons.arrow_forward,
          size: 28,
          color: (MediaQuery.of(context).platformBrightness == Brightness.dark)
                ? Colors.black
                : Colors.white
        ),
      ),
    );
  }

  ListTile myListTile({
    required IconData leading,
    required String text,
    IconData? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(top: 10, left: 20, right: 10),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Coloors.greenDark,
        child: Icon(
          leading,
          color: Colors.white,
        ),
      ),
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        trailing,
        color: Coloors.greyDark,
      ),
    );
  }
}
