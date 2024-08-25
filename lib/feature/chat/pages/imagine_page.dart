import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import 'package:stability_image_generation/stability_image_generation.dart';
import 'package:whatsapp_messenger/common/enum/message_type.dart';
import 'package:whatsapp_messenger/feature/chat/controller/chat_controller.dart';

class ImaginePage extends ConsumerStatefulWidget {
  const ImaginePage({super.key, required this.receiverId,});

  final receiverId;
  
  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _ImaginePageState();
  }  
}

class _ImaginePageState extends ConsumerState<ImaginePage> {
  final StabilityAI _ai = StabilityAI();
  final ImageAIStyle imageAIStyle = ImageAIStyle.anime;
  Uint8List? imagineImage;
  TextEditingController textController = TextEditingController();
  Future<void> _generate(String query) async {
    /// Call the generateImage method with the required parameters.
    textController.clear();
    Uint8List image = await _ai.generateImage(
      apiKey: 'sk-c5DiZ0u0nAWvlYdUJbkdeQOSNFipAk62uiWva3t5Sn07UFYB',
      imageAIStyle: imageAIStyle,
      prompt: query,
    );
    setState(() {
      imagineImage = image;
    });
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
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 15, 27, 36),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                alignment: Alignment.center,
                height: 700,
                width: 300,
                child: Padding(
                  padding: const EdgeInsets.only(top: 150),
                  child: (imagineImage == null)
                      ? Column(
                          children: [
                            Image.asset(
                              'assets/images/google-gemini-icon.png',
                              height: 155,
                              width: 155,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 25),
                            const Text(
                              'What do you want to Imagine?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 25,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Image.memory(
                          imagineImage!,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 40, 60, 75),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Stack(
                        children: [
                          // Positioned non-editable text
                          const Positioned(
                            left: 20,
                            bottom: 8,
                            child: Text(
                              'Imagine',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          // TextField that appears after 'Imagine'
                          Positioned(
                            left: 90, // Offset to position text after "Imagine"
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: TextField(
                              controller: textController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '',
                                hintStyle: const TextStyle(color: Colors.grey),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.send,
                                      color: Colors.green),
                                  onPressed: () { 
                                    if( imagineImage != null){
                                      sendFileMessage(imagineImage, MessageType.image);
                                      Navigator.of(context).pop();
                                    }                                   
                                    _generate(textController.text);
                                  },
                                ),
                              ),
                              textAlign: TextAlign.start,
                              maxLines: null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
