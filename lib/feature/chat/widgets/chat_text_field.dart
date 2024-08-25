import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'package:record/record.dart';

import 'package:path/path.dart' as path;

import 'package:whatsapp_messenger/common/enum/message_type.dart';

import 'package:whatsapp_messenger/common/extension/custom_theme_extension.dart';

import 'package:whatsapp_messenger/common/helper/show_alert_dialog.dart';

import 'package:whatsapp_messenger/common/utils/coloors.dart';

import 'package:whatsapp_messenger/common/widgets/custom_icon_button.dart';

import 'package:whatsapp_messenger/feature/auth/pages/image_picker_page.dart';

import 'package:whatsapp_messenger/feature/chat/controller/chat_controller.dart';
import 'package:whatsapp_messenger/feature/chat/pages/camera_preview_page.dart';
import 'package:whatsapp_messenger/feature/chat/pages/imagine_page.dart';
import 'package:whatsapp_messenger/feature/contact/pages/send_contact_page.dart';

class ChatTextField extends ConsumerStatefulWidget {
  const ChatTextField({
    super.key,
    required this.receiverId,
    required this.scrollController,
  });

  final String receiverId;
  final ScrollController scrollController;

  @override
  ConsumerState<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends ConsumerState<ChatTextField> {
  late TextEditingController messageController;
  final AudioRecorder audioRecorder = AudioRecorder();
  late final GenerativeModel _model;
  String apiKey = 'AIzaSyBFjcrUSe3Q1ycmqOsOkkvbGX-YgW8XuM0';
  late final ChatSession _chat;
  ({Image? image, String? text, bool fromUser}) _generatedContent =
      (image: null, text: null, fromUser: false);

  bool isMessageIconEnabled = false;
  double cardHeight = 0;
  File? imageCamera;
  bool _isRecording = false;
  bool _loading = false;
  final FocusNode _textFieldFocus = FocusNode();
  String? recordFilePath;
  Position? location;
  Uint8List? imagineImage;

  get rootBundle => null;

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 750,
        ),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  Future<void> _sendImagePrompt(String source) async {
    if (source == 'Camera') {
      pickImageFromCamera();
    } else {
      sendImageMessageFromGallery();
    }

    setState(() {
      _loading = true;
    });

    try {
      if (imageCamera == null) {
        throw Exception('No image selected from camera.');
      }

      // Read image data from the file
      final imageBytes = await imageCamera!.readAsBytes();

      final content = [
        Content.multi([
          TextPart(messageController.text),
          // Use the image data from the camera
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      var response = await _model.generateContent(content);
      var text = response.text;
      print(text);

      if (text == null) {
        _showError('No response from API.');
        return;
      } else {
        setState(() {
          sendResponse(text);
          _loading = false;
          _scrollDown();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      messageController.clear();
      setState(() {
        _loading = false;
      });
      _textFieldFocus.requestFocus();
    }
  }

  Future<void> _sendChatMessage() async {
    setState(() {
      _loading = true;
    });

    try {
      _generatedContent = (
        image: null,
        text: messageController.text,
        fromUser: true,
      );
      final response = await _chat.sendMessage(
        Content.text(messageController.text),
      );

      print(response.text);

      final text = response.text;
      _generatedContent = (
        image: null,
        text: text,
        fromUser: false,
      );

      if (text == null) {
        _showError('No response from API.');
        return;
      } else {
        setState(() {
          _loading = false;
          sendTextMessage();
          sendResponse(text);
          _scrollDown();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      messageController.clear();
      setState(() {
        _loading = false;
      });
      _textFieldFocus.requestFocus();
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }

  bool isTextEmpty = true;

  void sendLocation() async {
    setState(() {
      cardHeight = 0;
    });

    location = await _determinePosition();
    // print('lat: ${location!.latitude} ');
    setState(() {
      ref.read(chatControllerProvider).sendFileMessage(
            context,
            location!.latitude.toString(),
            location,
            widget.receiverId,
            MessageType.location,
          );
    });
  }

  void imagine() async {
    setState(() {
      cardHeight = 0;
    });

    // Navigate to the new page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ImaginePage(receiverId: widget.receiverId),
      ),
    );
  }

  void sendImageMessageFromGallery() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        imageCamera = File(image!.path);
        // imageGallery = null;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CameraPreviewPage(
                receiverId: widget.receiverId, imageCamera: imageCamera!),
          ),
        );
        cardHeight = 0;
      });
    }
  }

  pickImageFromCamera() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      setState(
        () {
          imageCamera = File(image!.path);
          // imageGallery = null;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CameraPreviewPage(
                  receiverId: widget.receiverId, imageCamera: imageCamera!),
            ),
          );
          cardHeight = 0;
        },
      );
    } catch (e) {
      showAlertDialog(context: context, message: e.toString());
    }
  }

  void sendDocumentMessage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);

      // print(result.files.first.name);

      setState(() {
        ref.read(chatControllerProvider).sendFileMessage(
              context,
              result.files.first.name,
              file,
              widget.receiverId,
              MessageType.document,
            );
      });
      Navigator.of(context).pop();
    } else {
      showAlertDialog(context: context, message: "Files cannot be accessed");
    }
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
    SchedulerBinding.instance.addPostFrameCallback(
      (timeStamp) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
    );
  }

  void sendResponse(String text) async {
    ref.read(chatControllerProvider).sendResponse(
          context: context,
          textMessage: text,
          receiverId: FirebaseAuth.instance.currentUser!.uid,
        );
    messageController.clear();

    await Future.delayed(const Duration(milliseconds: 100));
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void sendTextMessage() async {
    if (isMessageIconEnabled) {
      ref.read(chatControllerProvider).sendTextMessage(
            context: context,
            textMessage: messageController.text,
            receiverId: widget.receiverId,
          );
      messageController.clear();
    }

    await Future.delayed(const Duration(milliseconds: 100));
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  iconWithText({
    required VoidCallback onPressed,
    required IconData icon,
    required String text,
    required Color background,
  }) {
    return Column(
      children: [
        CustomIconButton(
          onPressed: onPressed,
          icon: icon,
          background: background,
          minWidth: 50,
          iconColor: Colors.white,
          border: Border.all(
            color: Coloors.greyDark.withOpacity(.2),
            width: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: const TextStyle(
            color: Coloors.greyDark,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    messageController = TextEditingController();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
    );
    _chat = _model.startChat();
    super.initState();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: cardHeight,
          width: double.maxFinite,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color:
                (MediaQuery.of(context).platformBrightness == Brightness.dark)
                    ? const Color.fromRGBO(18, 27, 34, 1)
                    : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      iconWithText(
                        onPressed: sendDocumentMessage,
                        icon: Icons.edit_document,
                        text: 'Document',
                        background: const Color.fromRGBO(116, 92, 238, 1),
                      ),
                      iconWithText(
                        onPressed: pickImageFromCamera,
                        icon: Icons.camera_alt,
                        text: 'Camera',
                        background: const Color.fromRGBO(223, 45, 107, 1),
                      ),
                      iconWithText(
                        onPressed: sendImageMessageFromGallery,
                        icon: Icons.photo_outlined,
                        text: 'Gallery',
                        background: const Color.fromRGBO(182, 90, 225, 1),
                      ),
                      iconWithText(
                        onPressed: () {},
                        icon: Icons.headphones,
                        text: 'Audio',
                        background: const Color.fromRGBO(229, 92, 50, 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      iconWithText(
                        onPressed: () {
                          sendLocation();
                        },
                        icon: Icons.location_on,
                        text: 'Location',
                        background: const Color.fromRGBO(31, 153, 78, 1),
                      ),
                      iconWithText(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SendContactPage(
                                receiverId: widget.receiverId,
                              ),
                            ),
                          );
                        },
                        icon: Icons.person,
                        text: 'Contact',
                        background: const Color.fromRGBO(0, 144, 207, 1),
                      ),
                      iconWithText(
                        onPressed: () {},
                        icon: Icons.poll_outlined,
                        text: 'poll',
                        background: const Color.fromRGBO(1, 153, 138, 1),
                      ),
                      iconWithText(
                        onPressed: () {
                          imagine();
                        },
                        icon: Icons.image_search_outlined,
                        text: 'imagine',
                        background: const Color.fromRGBO(0, 69, 172, 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: messageController,
                  maxLines: 4,
                  minLines: 1,
                  onChanged: (value) {
                    value.isEmpty
                        ? setState(() => isMessageIconEnabled = false)
                        : setState(() => isMessageIconEnabled = true);
                  },
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(
                      color: (MediaQuery.of(context).platformBrightness ==
                              Brightness.dark)
                          ? Coloors.greyDark
                          : Coloors.greyLight,
                    ),
                    filled: true,
                    fillColor: (MediaQuery.of(context).platformBrightness ==
                            Brightness.dark)
                        ? Coloors.greyBackgound
                        : const Color(0xFFFFFFFF),
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
                        iconColor: _isRecording
                            ? Colors.red
                            : Theme.of(context).listTileTheme.iconColor,
                      ),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.receiverId != 'Google-Gemini')
                          CustomIconButton(
                            onPressed: () => setState(
                              () => cardHeight == 0
                                  ? cardHeight = 220
                                  : cardHeight = 0,
                            ),
                            icon: cardHeight == 0
                                ? Icons.attach_file
                                : Icons.close,
                            iconColor:
                                Theme.of(context).listTileTheme.iconColor,
                          ),
                        if (widget.receiverId != 'Google-Gemini')
                          CustomIconButton(
                            onPressed: pickImageFromCamera,
                            icon: Icons.camera_alt_outlined,
                            iconColor:
                                Theme.of(context).listTileTheme.iconColor,
                          ),
                        if (widget.receiverId == 'Google-Gemini')
                          CustomIconButton(
                            onPressed: () {
                              _sendImagePrompt('Camera');
                            },
                            icon: Icons.camera_alt_outlined,
                            iconColor:
                                Theme.of(context).listTileTheme.iconColor,
                          ),
                        if (widget.receiverId == 'Google-Gemini')
                          CustomIconButton(
                            onPressed: () {
                              _sendImagePrompt('Gallery');
                            },
                            icon: Icons.photo_outlined,
                            iconColor:
                                Theme.of(context).listTileTheme.iconColor,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              (isMessageIconEnabled)
                  ? CustomIconButton(
                      onPressed: (widget.receiverId == 'Google-Gemini')
                          ? _sendChatMessage
                          : sendTextMessage,
                      icon: Icons.send,
                      background: (MediaQuery.of(context).platformBrightness ==
                              Brightness.dark)
                          ? const Color.fromRGBO(30, 194, 99, 1)
                          : const Color.fromRGBO(27, 172, 97, 1),
                      iconColor: (MediaQuery.of(context).platformBrightness ==
                              Brightness.dark)
                          ? Colors.black
                          : Colors.white,
                    )
                  : (widget.receiverId != 'Google-Gemini')
                      ? GestureDetector(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color:
                                  (MediaQuery.of(context).platformBrightness ==
                                          Brightness.dark)
                                      ? const Color.fromRGBO(30, 194, 99, 1)
                                      : const Color.fromRGBO(27, 172, 97, 1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.mic,
                              size: 22.0,
                              color:
                                  (MediaQuery.of(context).platformBrightness ==
                                          Brightness.dark)
                                      ? Colors.black
                                      : Colors.white,
                            ),
                          ),
                          onPanDown: (_) async {
                            if (await audioRecorder.hasPermission()) {
                              final Directory dir =
                                  await getApplicationDocumentsDirectory();
                              final String filePath =
                                  path.join(dir.path, "recording.wav");
                              try {
                                print("Starting recording...");
                                try {
                                  await audioRecorder.start(
                                      const RecordConfig(),
                                      path: filePath);
                                } catch (e) {
                                  print('Error starting recording: $e');
                                }

                                print("Recording started.");
                                setState(() {
                                  _isRecording = true;
                                  recordFilePath = null;
                                });
                              } catch (e) {
                                setState(() {
                                  _isRecording = false;
                                });
                                showAlertDialog(
                                    context: context,
                                    message: "Failed to start recording: $e");
                              }
                            }
                          },
                          onPanEnd: (_) async {
                            String? filePath = await audioRecorder.stop();
                            if (filePath == null) {
                              print('Failed to stop recording');
                            } else {
                              print('Recording saved at $filePath');
                            }

                            if (filePath != null) {
                              setState(() {
                                recordFilePath = filePath;
                                ref
                                    .read(chatControllerProvider)
                                    .sendFileMessage(
                                      context,
                                      '${DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now())}.mp3',
                                      File(filePath),
                                      widget.receiverId,
                                      MessageType.audio,
                                    );
                                _isRecording = false;
                              });
                            }
                          },
                        )
                      : const SizedBox.shrink(),
              // CustomIconButton(
              //   onPressed: sendTextMessage,
              //   icon: isMessageIconEnabled ? Icons.send : Icons.mic,
              //   background: (MediaQuery.of(context).platformBrightness ==
              //           Brightness.dark)
              //       ? const Color.fromRGBO(30, 194, 99, 1)
              //       : const Color.fromRGBO(27, 172, 97, 1),
              //   iconColor: (MediaQuery.of(context).platformBrightness ==
              //           Brightness.dark)
              //       ? Colors.black
              //       : Colors.white,
              // ),
            ],
          ),
        ),
      ],
    );
  }
}
