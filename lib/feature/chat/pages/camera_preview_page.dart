import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_messenger/common/enum/message_type.dart';
import 'package:whatsapp_messenger/common/extension/custom_theme_extension.dart';
import 'package:whatsapp_messenger/common/utils/coloors.dart';
import 'package:whatsapp_messenger/common/widgets/custom_icon_button.dart';
import 'package:whatsapp_messenger/feature/chat/controller/chat_controller.dart';

// ignore: must_be_immutable
class CameraPreviewPage extends ConsumerStatefulWidget {
  CameraPreviewPage({super.key, this.imageCamera, required this.receiverId});
  File? imageCamera;
  String receiverId;

  @override
  ConsumerState<CameraPreviewPage> createState() => _CameraPreviewPageState();
}

class _CameraPreviewPageState extends ConsumerState<CameraPreviewPage> {
  late TextEditingController messageController;

  void sendTextMessage() async {
    ref.read(chatControllerProvider).sendTextMessage(
          context: context,
          textMessage: messageController.text,
          receiverId: widget.receiverId,
        );
    messageController.clear();

    await Future.delayed(const Duration(milliseconds: 100));
  }

  void sendFileMessage(var file, MessageType messageType) async {
    ref.read(chatControllerProvider).sendFileMessage(
          context,
          '',
          file,
          widget.receiverId,
          messageType,
        );
    await Future.delayed(const Duration(milliseconds: 500));
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    messageController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          alignment: Alignment.center,
          // margin: const EdgeInsets.only(top: 45),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image(
                  height: double.maxFinite,
                  width: double.maxFinite,
                  image: FileImage(widget.imageCamera!) as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: CustomIconButton(
                  onPressed: () {},
                  icon: Icons.clear,
                ),
              ),
              Positioned(
                top: 0,
                right: 180,
                child: CustomIconButton(
                  onPressed: () {},
                  icon: Icons.hd_outlined,
                  iconSize: 30,
                  background: Colors.black12,
                  iconColor: Colors.white,
                ),
              ),
              Positioned(
                top: 0,
                right: 135,
                child: CustomIconButton(
                  onPressed: () {},
                  icon: Icons.crop_rotate,
                  iconSize: 25,
                  background: Colors.transparent,
                  iconColor: Colors.white,
                ),
              ),
              Positioned(
                top: 0,
                right: 90,
                child: CustomIconButton(
                  onPressed: () {},
                  icon: Icons.emoji_emotions_outlined,
                  iconSize: 25,
                  background: Colors.transparent,
                  iconColor: Colors.white,
                ),
              ),
              Positioned(
                top: 0,
                right: 45,
                child: CustomIconButton(
                  onPressed: () {},
                  icon: Icons.title,
                  iconSize: 25,
                  background: Colors.transparent,
                  iconColor: Colors.white,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: CustomIconButton(
                  onPressed: () {},
                  icon: Icons.edit_outlined,
                  iconSize: 25,
                  background: Colors.transparent,
                  iconColor: Colors.white,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 5.0,
                right: 5.0,
                child: SingleChildScrollView(
                  reverse: true,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: messageController,
                            maxLines: 4,
                            minLines: 1,
                            onChanged: (value) {},
                            decoration: InputDecoration(
                              hintText: 'Message',
                              hintStyle:
                                  TextStyle(color: context.theme.greyColor),
                              filled: true,
                              fillColor: context.theme.chatTextFieldBg,
                              isDense: true,
                              border: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  style: BorderStyle.none,
                                  width: 0,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              prefixIcon: Material(
                                color: Colors.transparent,
                                child: CustomIconButton(
                                  onPressed: () {},
                                  icon: Icons.emoji_emotions_outlined,
                                  iconColor:
                                      Theme.of(context).listTileTheme.iconColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        CustomIconButton(
                          onPressed: () {
                            sendFileMessage(
                              widget.imageCamera,
                              MessageType.image,
                            );
                            if (messageController.text.length > 0){
                              sendTextMessage();
                            }                            
                          },
                          icon: Icons.send_outlined,
                          background: Coloors.greenDark,
                          iconColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
