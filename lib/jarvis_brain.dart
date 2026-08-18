class JarvisBrain {
  String reply(String input) {
    final text = input.toLowerCase().trim();

    if (text.isEmpty) {
      return "I didn't hear you.";
    }

    if (text.contains('hello') ||
        text.contains('hi') ||
        text.contains('hey')) {
      return "Hello. Jarvis v2 is ready.";
    }

    if (text.contains('who are you')) {
      return "I am Jarvis v2, your personal assistant.";
    }

    if (text.contains('how are you')) {
      return "I am ready and waiting for your command.";
    }

    if (text.contains('time')) {
      final now = DateTime.now();
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      return "The current time is $hour:$minute.";
    }

    if (text.contains('date')) {
      final now = DateTime.now();
      return "Today's date is ${now.day}/${now.month}/${now.year}.";
    }

    if (text.contains('thank')) {
      return "You're welcome.";
    }

    return "I understand your command, but I don't have an answer for it yet.";
  }
}
