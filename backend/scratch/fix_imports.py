import os

def main():
    filepath = 'lib/features/tournaments/presentation/widgets/shareable_schedule_dialog.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    target = "import 'dart:io';"
    replacement = """import 'dart:io';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../data/models/tournament_standing.dart';"""

    if target in content and 'provider.dart' not in content:
        content = content.replace(target, replacement)
        print("Imports fixed!")
    else:
        print("Imports already fixed or target not found!")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    main()
