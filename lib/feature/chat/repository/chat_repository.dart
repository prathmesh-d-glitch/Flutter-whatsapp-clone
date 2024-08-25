import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
// ignore: depend_on_referenced_packages
import 'package:uuid/uuid.dart';
import 'package:whatsapp_messenger/common/enum/message_type.dart';
import 'package:whatsapp_messenger/common/helper/show_alert_dialog.dart';
import 'package:whatsapp_messenger/common/models/last_message_model.dart';
import 'package:whatsapp_messenger/common/models/message_model.dart';
import 'package:whatsapp_messenger/common/models/user_model.dart';
import 'package:whatsapp_messenger/feature/auth/repository/firebase_storage_repository.dart';

final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class ChatRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ChatRepository({
    required this.firestore,
    required this.auth,
  });

  void sendFileMessage({
    required var file,
    required BuildContext context,
    String? name,
    required String receiverId,
    required UserModel senderData,
    required Ref ref,
    required MessageType messageType,
  }) async {
    try {
      final timeSent = DateTime.now();
      final messageId = const Uuid().v1();

      // Check if the file is null or not valid
      if (file == null) {
        throw Exception("File cannot be null");
      }

      var imageUrl = await ref
          .read(firebaseStorageRepositoryProvider)
          .storeFileToFirebase(
              'chats/${messageType.type}/${senderData.uid}/$receiverId/$messageId',
              file);

      if (receiverId != 'Google-Gemini') {
        final userMap =
            await firestore.collection('users').doc(receiverId).get();

        final receverUserData = UserModel.fromMap(userMap.data()!);

        String lastMessage;

        switch (messageType) {
          case MessageType.image:
            lastMessage = '📸 Photo message';
            break;
          case MessageType.audio:
            lastMessage = '🎵 Voice message';
            break;
          case MessageType.video:
            lastMessage = '📹 Video message';
            break;
          case MessageType.gif:
            lastMessage = '🎥 GIF message';
            break;
          case MessageType.document:
            lastMessage = '📄 Document message';
            break;
          case MessageType.contact:
            lastMessage = ' Contact ';
          case MessageType.location:
            lastMessage = ' Location ';
          default:
            lastMessage = '📦 File message';
            break;
        }

        if (messageType == MessageType.contact && file is UserModel) {
          imageUrl = file.phoneNumber;
        } else if (messageType == MessageType.location && file is Position) {
          imageUrl = file.longitude.toString();
        }

        saveToMessageCollection(
          name: name,
          receiverId: receiverId,
          textMessage: imageUrl,
          timeSent: timeSent,
          textMessageId: messageId,
          senderUsername: senderData.username,
          receiverUsername: receverUserData.username,
          messageType: messageType,
        );

        saveAsLastMessage(
          senderUserData: senderData,
          receiverUserData: receverUserData,
          lastMessage: lastMessage,
          timeSent: timeSent,
          receiverId: receiverId,
        );
      }
      else {
        saveToMessageCollection(
          receiverId: receiverId,
          textMessage: imageUrl,
          timeSent: timeSent,
          textMessageId: messageId,
          senderUsername: senderData.username,
          receiverUsername: 'Gemini AI',
          messageType: MessageType.image,
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      showAlertDialog(context: context, message: e.toString());
    }
  }

  Stream<List<MessageModel>> getAllOneToOneMessage(String receiverId) {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(receiverId)
        .collection('messages')
        .orderBy('timeSent')
        .snapshots()
        .map((event) {
      List<MessageModel> messages = [];
      for (var message in event.docs) {
        messages.add(MessageModel.fromMap(message.data()));
      }
      return messages;
    });
  }

  Stream<List<LastMessageModel>> getAllLastMessageList() {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .snapshots()
        .asyncMap((event) async {
      List<LastMessageModel> contacts = [];
      for (var document in event.docs) {
        final lastMessage = LastMessageModel.fromMap(document.data());
        final userData = await firestore
            .collection('users')
            .doc(lastMessage.contactId)
            .get();
        final user = UserModel.fromMap(userData.data()!);
        contacts.add(
          LastMessageModel(
            username: user.username,
            profileImageUrl: user.profileImageUrl,
            contactId: lastMessage.contactId,
            timeSent: lastMessage.timeSent,
            lastMessage: lastMessage.lastMessage,
          ),
        );
      }
      return contacts;
    });
  }

  void sendResponse({
    required BuildContext context,
    required String textMessage,
    required String receiverId,
  }) async {
    try {
      final timeSent = DateTime.now();
      final textMessageId = const Uuid().v1();

      final message = MessageModel(
        name: '',
        senderId: 'Google-Gemini',
        receiverId: auth.currentUser!.uid,
        textMessage: textMessage,
        type: MessageType.text,
        timeSent: timeSent,
        messageId: textMessageId,
        isSeen: false,
      );

      // saveToMessageCollection(
      //   receiverId: receiverId,
      //   textMessage: textMessage,
      //   timeSent: timeSent,
      //   textMessageId: textMessageId,
      //   senderUsername: 'Gemini AI',
      //   receiverUsername: auth.currentUser!.uid,
      //   messageType: MessageType.text,
      // );
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc('Google-Gemini')
          .collection('messages')
          .doc(textMessageId)
          .set(message.toMap());
    } catch (e) {
      // ignore: use_build_context_synchronously
      showAlertDialog(context: context, message: e.toString());
    }
  }

  void sendTextMessage({
    required BuildContext context,
    required String textMessage,
    required String receiverId,
    required UserModel senderData,
  }) async {
    try {
      final timeSent = DateTime.now();
      final textMessageId = const Uuid().v1();
      if (receiverId != 'Google-Gemini') {
        final receiverDataMap =
            await firestore.collection('users').doc(receiverId).get();
        final receiverData = UserModel.fromMap(receiverDataMap.data()!);

        saveToMessageCollection(
          receiverId: receiverId,
          textMessage: textMessage,
          timeSent: timeSent,
          textMessageId: textMessageId,
          senderUsername: senderData.username,
          receiverUsername: receiverData.username,
          messageType: MessageType.text,
        );

        saveAsLastMessage(
          senderUserData: senderData,
          receiverUserData: receiverData,
          lastMessage: textMessage,
          timeSent: timeSent,
          receiverId: receiverId,
        );
      } else {
        saveToMessageCollection(
          receiverId: receiverId,
          textMessage: textMessage,
          timeSent: timeSent,
          textMessageId: textMessageId,
          senderUsername: senderData.username,
          receiverUsername: 'Gemini AI',
          messageType: MessageType.text,
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      showAlertDialog(context: context, message: e.toString());
    }
  }

  void saveToMessageCollection({
    String? name,
    required String receiverId,
    required String textMessage,
    required DateTime timeSent,
    required String textMessageId,
    required String senderUsername,
    required String receiverUsername,
    required MessageType messageType,
  }) async {
    final message = MessageModel(
      name: name,
      senderId: auth.currentUser!.uid,
      receiverId: receiverId,
      textMessage: textMessage,
      type: messageType,
      timeSent: timeSent,
      messageId: textMessageId,
      isSeen: false,
    );

    // sender
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(receiverId)
        .collection('messages')
        .doc(textMessageId)
        .set(message.toMap());

    // receiver
    if (receiverId != 'Google-Gemini') {
      await firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(textMessageId)
          .set(message.toMap());
    }
  }

  void saveAsLastMessage({
    required UserModel senderUserData,
    required UserModel receiverUserData,
    required String lastMessage,
    required DateTime timeSent,
    required String receiverId,
  }) async {
    final receiverLastMessage = LastMessageModel(
      username: senderUserData.username,
      profileImageUrl: senderUserData.profileImageUrl,
      contactId: senderUserData.uid,
      timeSent: timeSent,
      lastMessage: lastMessage,
    );

    await firestore
        .collection('users')
        .doc(receiverId)
        .collection('chats')
        .doc(auth.currentUser!.uid)
        .set(receiverLastMessage.toMap());

    final senderLastMessage = LastMessageModel(
      username: receiverUserData.username,
      profileImageUrl: receiverUserData.profileImageUrl,
      contactId: receiverUserData.uid,
      timeSent: timeSent,
      lastMessage: lastMessage,
    );

    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(receiverId)
        .set(senderLastMessage.toMap());
  }
}
