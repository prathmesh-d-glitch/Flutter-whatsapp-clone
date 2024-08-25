import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_clippers/custom_clippers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:latlong2/latlong.dart';
import 'package:whatsapp_messenger/common/enum/message_type.dart' as my_type;
import 'package:whatsapp_messenger/common/extension/custom_theme_extension.dart';
import 'package:whatsapp_messenger/common/models/message_model.dart';
import 'package:whatsapp_messenger/common/utils/coloors.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({
    super.key,
    required this.isSender,
    required this.haveNip,
    required this.message,
  });

  final bool isSender;
  final bool haveNip;
  final MessageModel message;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.message.type == my_type.MessageType.audio) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() => _isLoading = true);
      await _audioPlayer.setUrl(widget.message.textMessage ?? '');
      _duration = _audioPlayer.duration ?? Duration.zero;
      _audioPlayer.positionStream.listen((position) {
        setState(() {
          _position = position;
        });
      });
      _audioPlayer.playbackEventStream.listen((event) {
        setState(() {
          _isPlaying = false;
          _isLoading = false;
        });
      });
    } catch (e) {
      // Handle error
      print('Error initializing audio player: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _buildMessageContent(context, message) {
    if (message.type == my_type.MessageType.image) {
      return Padding(
        padding: const EdgeInsets.only(
          right: 3,
          top: 3,
          left: 3,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image(
            image: CachedNetworkImageProvider(message.textMessage),
          ),
        ),
      );
    } else if (message.type == my_type.MessageType.document) {
      return Padding(
        padding: const EdgeInsets.only(
          right: 4,
          top: 4,
          left: 4,
          bottom: 20,
        ),
        child: InkWell(
          onTap: () {
            // Implement document view or download functionality here
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  (MediaQuery.of(context).platformBrightness == Brightness.dark)
                      ? (widget.isSender)
                          ? const Color.fromRGBO(19, 67, 51, 1)
                          : const Color.fromRGBO(30, 40, 49, 1)
                      : (widget.isSender)
                          ? const Color.fromRGBO(213, 243, 207, 1)
                          : const Color.fromRGBO(246, 245, 243, 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned(
                        child: Text(
                          message.name, // or extract the filename from the path
                          style: TextStyle(
                            fontSize: 13,
                            color: (MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark)
                                ? Colors.white
                                : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (message.type == my_type.MessageType.contact) {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          decoration: BoxDecoration(
            color:
                (MediaQuery.of(context).platformBrightness == Brightness.dark)
                    ? (widget.isSender)
                        ? const Color.fromRGBO(19, 67, 51, 1)
                        : const Color.fromRGBO(30, 40, 49, 1)
                    : (widget.isSender)
                        ? const Color.fromRGBO(213, 243, 207, 1)
                        : const Color.fromRGBO(246, 245, 243, 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 40,
                  color: Colors.grey,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        message.textMessage ?? 'Unknown Number',
                        style: TextStyle(
                          fontSize: 14,
                          color: (MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark)
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.person_add,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    Contact contact = Contact.fromVCard('BEGIN:VCARD\n'
                        'VERSION:3.0\n'
                        'N:;${message.name};;;\n'
                        'TEL;TYPE=HOME:${message.textMessage}\n'
                        'END:VCARD');

                    contact.insert();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else if (message.type == my_type.MessageType.location) {
      return Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        height: 400,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(
                double.parse(message.name), double.parse(message.textMessage)), // Correct latitude and longitude values
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(
                    double.parse(message.name),
                    double.parse(message.textMessage),
                  ), // Provide a valid point here
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.location_pin,
                    size: 50,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (message.type == my_type.MessageType.audio) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color:
                (MediaQuery.of(context).platformBrightness == Brightness.dark)
                    ? (widget.isSender)
                        ? const Color.fromRGBO(19, 67, 51, 1)
                        : const Color.fromRGBO(30, 40, 49, 1)
                    : (widget.isSender)
                        ? const Color.fromRGBO(213, 243, 207, 1)
                        : const Color.fromRGBO(246, 245, 243, 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: (MediaQuery.of(context).platformBrightness ==
                              Brightness.dark)
                          ? Colors.white
                          : Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_isPlaying) {
                          _audioPlayer.pause();
                        } else {
                          _audioPlayer.play();
                        }
                        _isPlaying = !_isPlaying;
                      });
                    },
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _duration.inSeconds > 0
                          ? _position.inSeconds / _duration.inSeconds
                          : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(
                        color: (MediaQuery.of(context).platformBrightness ==
                                Brightness.dark)
                            ? Colors.white
                            : Colors.black,
                        fontSize: 12.0),
                  ),
                  Text(
                    _formatDuration(_duration - _position),
                    style: TextStyle(
                        color: (MediaQuery.of(context).platformBrightness ==
                                Brightness.dark)
                            ? Colors.white
                            : Colors.black,
                        fontSize: 12.0),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(
          top: 5,
          bottom: 5,
          left: widget.isSender ? 10 : 15,
          right: widget.isSender ? 65 : 55,
        ),
        child: MarkdownBody(
          data: "${message.textMessage}              ",
          styleSheet: MarkdownStyleSheet(
            h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            p: TextStyle(
              fontSize: 16,
              color:
                  (MediaQuery.of(context).platformBrightness == Brightness.dark)
                      ? Colors.white
                      : Colors.black,
            ),
          ),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: widget.isSender ? Alignment.centerRight : Alignment.centerLeft,
      margin: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: widget.isSender
            ? 80
            : widget.haveNip
                ? 10
                : 15,
        right: widget.isSender
            ? widget.haveNip
                ? 10
                : 15
            : 80,
      ),
      child: ClipPath(
        clipper: widget.haveNip
            ? UpperNipMessageClipperTwo(
                widget.isSender ? MessageType.send : MessageType.receive,
                nipWidth: 8,
                nipHeight: 10,
                bubbleRadius: widget.haveNip ? 12 : 0,
              )
            : null,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: (MediaQuery.of(context).platformBrightness ==
                        Brightness.dark)
                    ? (widget.isSender)
                        ? const Color.fromRGBO(19, 77, 55, 1)
                        : const Color.fromRGBO(31, 44, 52, 1)
                    : (widget.isSender)
                        ? const Color.fromRGBO(216, 253, 210, 1)
                        : const Color.fromRGBO(255, 255, 255, 1),
                borderRadius: widget.haveNip ? null : BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black38),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: _buildMessageContent(context, widget.message),
              ),
            ),
            Positioned(
              bottom: widget.message.type == my_type.MessageType.text ? 5 : -9,
              right: widget.message.type == my_type.MessageType.text
                  ? widget.isSender
                      ? 25
                      : 10
                  : 25,
              child: widget.message.type == my_type.MessageType.text
                  ? Padding(
                    padding: (widget.isSender) ? const EdgeInsets.only(right: 8) : const EdgeInsets.only(right: 1),
                    child: Text(
                        DateFormat.Hm().format(widget.message.timeSent),
                        style: TextStyle(
                          fontSize: 10.8,
                          color: context.theme.greyColor,
                        ),
                      ),
                  )
                  : Container(
                      padding: EdgeInsets.only(
                          left: 90, right: 10, bottom: (widget.message.type != my_type.MessageType.image) ? 10 : 14, top: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: const Alignment(0, -1),
                          end: const Alignment(1, 1),
                          colors: [
                            context.theme.greyColor!.withOpacity(0),
                            context.theme.greyColor!.withOpacity(0),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(300),
                          bottomRight: Radius.circular(100),
                        ),
                      ),
                      child: Text(
                        DateFormat.Hm().format(widget.message.timeSent),
                        style: TextStyle(
                          fontSize: 10.8,
                          color: (MediaQuery.of(context).platformBrightness ==
                              Brightness.light && widget.message.type != my_type.MessageType.image)
                          ? Coloors.greyLight
                          : Colors.white,
                        ),
                      ),
                    ),
            ),
            if(widget.isSender)
            Positioned(
              bottom: widget.message.type == my_type.MessageType.text ? 6 : (widget.message.type != my_type.MessageType.image) ? 2 : 6,
              right: 12,
              child: Icon(
                Icons.done_all_outlined,
                color: widget.message.isSeen ? Colors.lightBlue : (MediaQuery.of(context).platformBrightness ==
                              Brightness.light && widget.message.type != my_type.MessageType.image)
                          ? Coloors.greyLight
                          : Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
