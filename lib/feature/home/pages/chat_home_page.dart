import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_messenger/common/extension/custom_theme_extension.dart';
import 'package:whatsapp_messenger/common/models/last_message_model.dart';
import 'package:whatsapp_messenger/common/models/user_model.dart';
import 'package:whatsapp_messenger/common/routes/routes.dart';
import 'package:whatsapp_messenger/common/utils/coloors.dart';
import 'package:whatsapp_messenger/feature/chat/controller/chat_controller.dart';
import 'package:whatsapp_messenger/feature/chat/pages/gemini_chat.dart';

class ChatHomePage extends ConsumerWidget {
  const ChatHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            decoration: BoxDecoration(
              color:
                  (MediaQuery.of(context).platformBrightness == Brightness.dark)
                      ? const Color.fromRGBO(36, 43, 49, 1)
                      : const Color.fromRGBO(246, 245, 243, 1),
              shape: BoxShape.rectangle,
              borderRadius: const BorderRadius.all(
                Radius.circular(50),
              ),
            ),
            child: TextFormField(
              decoration: InputDecoration(
                  prefixIcon: IconButton(
                    icon: Image.asset(
                      "assets/images/google-gemini-icon.png",
                      width: 30,
                      height: 30,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => GeminiChat(),
                        ),
                      );
                    },
                  ),
                  hintText: 'Search',
                  hintStyle: const TextStyle(fontSize: 17),
                  suffixIcon: const Icon(Icons.search),
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
          StreamBuilder<List<LastMessageModel>>(
            stream: ref.watch(chatControllerProvider).getAllLastMessageList(),
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Coloors.greenDark,
                  ),
                );
              }
              return ListView.builder(
                itemCount: snapshot.data!.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final lastMessageData = snapshot.data![index];
                  return ListTile(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.chat,
                        arguments: UserModel(
                          username: lastMessageData.username,
                          uid: lastMessageData.contactId,
                          profileImageUrl: lastMessageData.profileImageUrl,
                          active: true,
                          phoneNumber: '0',
                          groupId: [],
                        ),
                      );
                    },
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(lastMessageData.username),
                        Text(
                          DateFormat.Hm().format(lastMessageData.timeSent),
                          style: TextStyle(
                            fontSize: 13,
                            color: context.theme.greyColor,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        lastMessageData.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.theme.greyColor),
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundImage: lastMessageData.profileImageUrl.isEmpty
                          ? const AssetImage('assets/images/blank.png')
                          : CachedNetworkImageProvider(
                              lastMessageData.profileImageUrl,
                            ),
                      radius: 24,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromRGBO(30, 194, 99, 1),
        onPressed: () {
          Navigator.pushNamed(context, Routes.contact);
        },
        child: Icon(
          Icons.chat,
          color: (MediaQuery.of(context).platformBrightness == Brightness.dark)
              ? Colors.black
              : Colors.white,
        ),
      ),
    );
  }
}
