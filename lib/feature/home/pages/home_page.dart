import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatsapp_messenger/common/utils/coloors.dart';

import 'package:whatsapp_messenger/common/widgets/custom_icon_button.dart';

import 'package:whatsapp_messenger/feature/auth/controller/auth_controller.dart';

import 'package:whatsapp_messenger/feature/home/pages/call_home_page.dart';

import 'package:whatsapp_messenger/feature/home/pages/chat_home_page.dart';

import 'package:whatsapp_messenger/feature/home/pages/status_home_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late Timer timer;

  updateUserPresence() {
    ref.read(authControllerProvider).updateUserPresence();
  }

  @override
  void initState() {
    updateUserPresence();
    timer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) => setState(() {}),
    );
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var _selectedPageIndex = 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WhatsApp',
          style: TextStyle(
            letterSpacing: 1,
            fontSize: 21,
          ),
        ),
        elevation: 0,
        actions: [
          CustomIconButton(
            onPressed: () {},
            icon: Icons.qr_code_scanner,
          ),
          CustomIconButton(
            onPressed: () {},
            icon: Icons.camera_alt_outlined,
          ),
          CustomIconButton(
            onPressed: () {},
            icon: Icons.more_vert,
          ),
        ],
      ),
      body: const ChatHomePage(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (selectPage) {},
        currentIndex: _selectedPageIndex,
        items: [
          BottomNavigationBarItem(
            backgroundColor:
                (MediaQuery.of(context).platformBrightness == Brightness.dark)
                    ? Coloors.backgroundDark
                    : Colors.white,
            icon: const Icon(
              Icons.chat,
            ),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            backgroundColor:
                (MediaQuery.of(context).platformBrightness == Brightness.dark)
                    ? Coloors.backgroundDark
                    : Colors.white,
            icon: const Icon(
              Icons.update_sharp,
            ),
            label: 'Updates',
          ),
          BottomNavigationBarItem(
            backgroundColor:
                (MediaQuery.of(context).platformBrightness == Brightness.dark)
                    ? Coloors.backgroundDark
                    : Colors.white,
            icon: const Icon(
              Icons.people,
            ),
            label: 'Communities',
          ),
          BottomNavigationBarItem(
            backgroundColor:
                (MediaQuery.of(context).platformBrightness == Brightness.dark)
                    ? Coloors.backgroundDark
                    : Colors.white,
            icon: const Icon(
              Icons.call_outlined,
            ),
            label: 'Calls',
          ),
        ],
      ),
    );
  }
}
