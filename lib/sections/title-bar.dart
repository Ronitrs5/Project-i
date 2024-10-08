import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class TitleBar extends StatefulWidget {
  final Function(Directory) onFolderOpened;

  const TitleBar({super.key, required this.onFolderOpened});

  @override
  State<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<TitleBar> {
  // Function to select and open a folder
  Future<void> _selectFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      Directory folder = Directory(selectedDirectory);
      widget.onFolderOpened(folder); // Trigger callback to pass the opened folder
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(width: 10),
              // File menu with open folder functionality
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'Open Folder') {
                    _selectFolder(); // Open folder when 'Open Folder' is selected
                  }
                },
                child: Text(
                  'File',
                  style: TextStyle(color: Colors.white),
                ),
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'Open Folder',
                      child: Text('Open Folder'),
                    ),
                  ];
                },
              ),
              SizedBox(width: 10),
              Text('Code', style: TextStyle(color: Colors.white)),
              SizedBox(width: 10),
              Text('Build', style: TextStyle(color: Colors.white)),
              SizedBox(width: 10),
              Text('Run', style: TextStyle(color: Colors.white)),
              SizedBox(width: 10),
              Text('Help', style: TextStyle(color: Colors.white)),
              SizedBox(width: 10),
            ],
          ),
          Row(
            children: [
              SizedBox(width: 10),
              Text('Min', style: TextStyle(color: Colors.white)),
              SizedBox(width: 10),
              Text('Max', style: TextStyle(color: Colors.white)),
              SizedBox(width: 10),
              Text('Close', style: TextStyle(color: Colors.white)),
              SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }
}
