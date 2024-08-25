enum MessageType {
  text('text'),
  image('image'),
  audio('audio'),
  video('video'),
  gif('gif'),
  contact('contact'),
  location('location'),
  document('document');

  final String type;

  const MessageType(this.type);
}

extension ConvertMessage on String {
  MessageType toEnum() {
    switch (this) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      case 'gif':
        return MessageType.gif;
      case 'document':
        return MessageType.document;
      case 'contact':
        return MessageType.contact;
        case 'location':
        return MessageType.location;
      default:
        return MessageType.text;
    }
  }
}