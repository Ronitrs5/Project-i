import 'dart:io';
import 'package:flutter/material.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:project_i/sections/title-bar.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:path/path.dart' as p;

class MainIde extends StatefulWidget {
  const MainIde({super.key});

  @override
  State<MainIde> createState() => _MainIdeState();
}

class _MainIdeState extends State<MainIde> with SingleTickerProviderStateMixin {
  late CodeController _codeController;
  double _sidebarWidth = 200;
  Directory? _currentDirectory;
  List<FileSystemEntity> _files = [];
  List<Node> _nodes = [];
  TreeViewController _treeViewController = TreeViewController(children: []);
  bool _isLoading = false; // Loading state

  List<Tab> _tabs = []; // List to keep track of open tabs (file names)
  Map<String, CodeController> _controllers = {}; // Controllers for each open file
  TabController? _tabController; // Tab controller for switching between tabs

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(text: '', language: javascript);
    _tabController = TabController(vsync: this, length: 0); // Initialize the TabController
  }

  // Function to list all files and folders with loading indication
  Future<void> _listFiles(Directory directory) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(Duration(seconds: 1)); // Optional: Simulate loading delay
      final files = directory.listSync(); // List all files and folders in the directory

      setState(() {
        _files = files;
        _currentDirectory = directory;
        _nodes = _createTreeNodes(directory);
        _treeViewController = TreeViewController(children: _nodes);
        _isLoading = false;
      });
    } on FileSystemException catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showAccessDeniedDialog(directory.path); // Show dialog if access is denied
    }
  }

  // Create tree nodes from the file system entities
  List<Node> _createTreeNodes(Directory directory) {
    List<Node> nodes = [];

    for (var entity in directory.listSync()) {
      final isDirectory = FileSystemEntity.isDirectorySync(entity.path);
      if (isDirectory) {
        Directory dir = Directory(entity.path);
        nodes.add(
          Node(
            key: entity.path,
            label: p.basename(entity.path), // Only show the folder name
            children: _createTreeNodes(dir),
          ),
        );
      } else {
        nodes.add(
          Node(
            key: entity.path,
            label: p.basename(entity.path),
          ),
        );
      }
    }

    return nodes;
  }

  // Function to show access denied dialog
  void _showAccessDeniedDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Access Denied'),
        content: Text('You do not have permission to access the folder: $path'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }


  void _openFileInEditor(File file) async {
    final supportedExtensions = ['.txt', '.js', '.jsx', '.ts', '.tsx', '.json'];
    final fileExtension = p.extension(file.path);

    if (supportedExtensions.contains(fileExtension)) {
      try {
        // Read the file content
        final fileContent = await file.readAsString();

        // Check if the file is already open in a tab
        if (!_controllers.containsKey(file.path)) {
          // Create a new CodeController for the file content
          final controller = CodeController(text: fileContent, language: javascript);

          setState(() {
            _controllers[file.path] = controller;
            _tabs.add(Tab(text: p.basename(file.path)));
            _tabController = TabController(
              vsync: this,
              length: _tabs.length,
              initialIndex: _tabs.length - 1,
            );
          });
        } else {
          // Switch to the tab that is already open for the file
          final index = _controllers.keys.toList().indexOf(file.path);
          _tabController!.animateTo(index);
        }
      } catch (e) {
        _showErrorDialog('Error reading file', 'Could not open the file: ${file.path}');
      }
    } else {
      _showErrorDialog('Unsupported file type', 'Cannot open files with this extension: $fileExtension');
    }
  }


  // Show error dialog for unsupported files or read errors
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Close the selected tab
  // Update your _closeTab function to dispose the controller properly
  void _closeTab(int index) {
    setState(() {
      final tabKey = _controllers.keys.elementAt(index);
      _controllers.remove(tabKey); // Remove the controller
      _tabs.removeAt(index); // Remove the tab

      // Dispose the TabController if it exists
      _tabController!.dispose();
      _tabController = TabController(
        vsync: this,
        length: _tabs.length,
        initialIndex: index < _tabs.length ? index : 0,
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: Column(
        children: [
          TitleBar(
            onFolderOpened: (Directory folder) {
              _listFiles(folder); // Update file structure when folder is opened
            },
          ),
          Expanded(
            child: Row(
              children: [
                GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _sidebarWidth += details.delta.dx;
                      if (_sidebarWidth < 100) _sidebarWidth = 100;
                      if (_sidebarWidth > 400) _sidebarWidth = 400;
                    });
                  },
                  child: Container(
                    width: _sidebarWidth,
                    color: Colors.black12,
                    child: Column(
                      children: [
                        // Display the name of the current folder
                        Text(
                          _currentDirectory != null
                              ? 'Opened: ${p.basename(_currentDirectory!.path)}'
                              : 'No folder opened',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : _buildFileTree(), // Show tree view when not loading
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _sidebarWidth += details.delta.dx;
                      if (_sidebarWidth < 100) _sidebarWidth = 100;
                      if (_sidebarWidth > 400) _sidebarWidth = 400;
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: Container(
                      width: 8,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      // Tabs for the opened files
                      if (_tabs.isNotEmpty)
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabs: _tabs.map((tab) {
                            return Row(
                              children: [
                                Tab(text: tab.text),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    final index = _tabs.indexOf(tab);
                                    _closeTab(index); // Close the tab
                                  },
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      Expanded(
                        child: _tabs.isNotEmpty
                            ? TabBarView(
                          controller: _tabController,
                          children: _controllers.values.map((controller) {
                            return CodeTheme(
                              data: CodeThemeData(),
                              child: CodeField(
                                controller: controller,
                                textStyle: const TextStyle(fontFamily: 'SourceCode'),
                                expands: true,
                                maxLines: null,
                                minLines: null,
                              ),
                            );
                          }).toList(),
                        )
                            : Center(child: Text('No file opened')),
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the tree view for the file structure
  // Build the tree view for the file structure
  Widget _buildFileTree() {
    if (_currentDirectory == null) {
      return Center(child: Text('No folder opened'));
    }
    if (_nodes.isEmpty) {
      return Center(child: Text('No files found'));
    }

    return TreeView(
      controller: _treeViewController,
      allowParentSelect: true,
      supportParentDoubleTap: true,
      onNodeTap: (key) {
        // Make 'file' nullable
        final FileSystemEntity? file = _files.firstWhere(
              (f) => f.path == key,
          orElse: () => null as FileSystemEntity, // Cast null to FileSystemEntity to avoid error
        );

        if (file == null) {
          _showErrorDialog('File Not Found', 'Could not find the selected file.');
          return; // Exit early if the file is not found
        }

        if (FileSystemEntity.isDirectorySync(file.path)) {
          _listFiles(Directory(file.path)); // Open folder
        } else {
          _openFileInEditor(File(file.path)); // Open file in code editor
        }
      },
      theme: TreeViewTheme(
        expanderTheme: ExpanderThemeData(
          type: ExpanderType.caret,
          modifier: ExpanderModifier.none,
          position: ExpanderPosition.start,
          color: Colors.black,
          size: 20,
        ),
        labelStyle: TextStyle(fontSize: 14, letterSpacing: 0.3),
        parentLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(size: 18, color: Colors.blue),
      ),
    );
  }

}
