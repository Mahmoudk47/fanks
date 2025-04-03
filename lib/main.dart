import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:convert';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(const ButtonManagerApp());
}

class ButtonManagerApp extends StatefulWidget {
  const ButtonManagerApp({super.key});

  @override
  State<ButtonManagerApp> createState() => _ButtonManagerAppState();
}

class _ButtonManagerAppState extends State<ButtonManagerApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _setThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Button Manager',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: ButtonManagerHome(
        setThemeMode: _setThemeMode,
        themeMode: _themeMode,
      ),
    );
  }
}

class CustomButton {
  String id;
  String label;
  Color color;
  int count;

  CustomButton({
    required this.id,
    required this.label,
    required this.color,
    required this.count,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'color': color.value, 'count': count};
  }

  factory CustomButton.fromJson(Map<String, dynamic> json) {
    return CustomButton(
      id: json['id'],
      label: json['label'],
      color: Color(json['color']),
      count: json['count'],
    );
  }
}

class ButtonManagerHome extends StatefulWidget {
  final Function(ThemeMode) setThemeMode;
  final ThemeMode themeMode;

  const ButtonManagerHome({
    super.key,
    required this.setThemeMode,
    required this.themeMode,
  });

  @override
  State<ButtonManagerHome> createState() => _ButtonManagerHomeState();
}

class _ButtonManagerHomeState extends State<ButtonManagerHome> {
  List<CustomButton> buttons = [];
  bool hasUnsavedChanges = false;
  late ConfettiController _confettiController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _loadButtons();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadButtons() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final buttonsJson = prefs.getString('buttons');

      if (buttonsJson != null) {
        final List<dynamic> decodedButtons = jsonDecode(buttonsJson);
        setState(() {
          buttons = decodedButtons
              .map((buttonJson) => CustomButton.fromJson(buttonJson))
              .toList();
        });
      }
    } catch (e) {
      // Handle error
      debugPrint('Error loading buttons: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveButtons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final buttonsJson = jsonEncode(
        buttons.map((button) => button.toJson()).toList(),
      );
      await prefs.setString('buttons', buttonsJson);
      setState(() {
        hasUnsavedChanges = false;
      });
    } catch (e) {
      // Handle error
      debugPrint('Error saving buttons: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save changes')));
    }
  }

  int get totalCount {
    return buttons.fold(0, (sum, button) => sum + button.count);
  }

  void _decrementButtonCount(int index) {
    if (buttons[index].count > 0) {
      setState(() {
        buttons[index].count--;
        hasUnsavedChanges = true;
      });

      if (buttons[index].count == 0) {
        _confettiController.play();
      }
    }
  }

  void _showButtonDialog({CustomButton? button, int? editIndex}) {
    final isEditing = button != null;
    final TextEditingController labelController = TextEditingController(
      text: button?.label ?? '',
    );
    final TextEditingController countController = TextEditingController(
      text: button?.count.toString() ?? '1',
    );

    Color selectedColor = button?.color ?? Colors.blue;
    bool useCustomColor = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Button' : 'Create New Button'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Button Label',
                        hintText: 'Enter a label (max 20 characters)',
                      ),
                      maxLength: 20,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: countController,
                      decoration: const InputDecoration(
                        labelText: 'Count',
                        hintText: 'Enter initial count',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text('Button Color:'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: useCustomColor,
                          onChanged: (value) {
                            setState(() {
                              useCustomColor = value!;
                            });
                          },
                        ),
                        const Text('Use custom color'),
                      ],
                    ),
                    if (!useCustomColor)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Colors.blue,
                          Colors.red,
                          Colors.green,
                          Colors.yellow,
                          Colors.purple,
                        ].map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == color
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    else
                      ColorPicker(
                        pickerColor: selectedColor,
                        onColorChanged: (color) {
                          setState(() {
                            selectedColor = color;
                          });
                        },
                        pickerAreaHeightPercent: 0.8,
                        displayThumbColor: true,
                        enableAlpha: false,
                      ),
                  ],
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _deleteButton(editIndex!);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final label = labelController.text.trim();
                    if (label.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Label cannot be empty')),
                      );
                      return;
                    }

                    final count = int.tryParse(countController.text) ?? 0;
                    if (count < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Count cannot be negative'),
                        ),
                      );
                      return;
                    }

                    if (isEditing) {
                      _updateButton(editIndex!, label, selectedColor, count);
                    } else {
                      _addButton(label, selectedColor, count);
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addButton(String label, Color color, int count) {
    setState(() {
      buttons.add(
        CustomButton(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          label: label,
          color: color,
          count: count,
        ),
      );
      hasUnsavedChanges = true;
    });
  }

  void _updateButton(int index, String label, Color color, int count) {
    setState(() {
      buttons[index].label = label;
      buttons[index].color = color;
      buttons[index].count = count;
      hasUnsavedChanges = true;
    });
  }

  void _deleteButton(int index) {
    setState(() {
      buttons.removeAt(index);
      hasUnsavedChanges = true;
    });
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Theme Mode:'),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Light'),
                leading: Radio<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: widget.themeMode,
                  onChanged: (ThemeMode? value) {
                    Navigator.pop(context);
                    widget.setThemeMode(value!);
                  },
                ),
              ),
              ListTile(
                title: const Text('Dark'),
                leading: Radio<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: widget.themeMode,
                  onChanged: (ThemeMode? value) {
                    Navigator.pop(context);
                    widget.setThemeMode(value!);
                  },
                ),
              ),
              ListTile(
                title: const Text('System'),
                leading: Radio<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: widget.themeMode,
                  onChanged: (ThemeMode? value) {
                    Navigator.pop(context);
                    widget.setThemeMode(value!);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About'),
          content: const Text(
            'Button Manager Application\n\n'
            'this app is develobed by Mahmoud Essam El-sayed Mohamed Mahmoud Kenesh'
            'A counter application that allows users to create, edit, and track multiple buttons. '
            'Each button has a custom label, color, and count value. '
            'Pressing a button decreases its count, and when a count reaches zero, '
            'a confetti animation is triggered as a reward.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final isMediumScreen = MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 900;

    int crossAxisCount = isSmallScreen ? 2 : (isMediumScreen ? 3 : 4);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[200]
          : Colors.grey[900],
      appBar: AppBar(
        title: const Text('Button Manager'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'settings') {
                _showSettingsDialog();
              } else if (value == 'about') {
                _showAboutDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem(value: 'about', child: Text('About')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                child: Column(
                  children: [
                    // Total Counter Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Total Count',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: 1.0 + (value * 0.2),
                                  child: child,
                                );
                              },
                              child: Text(
                                totalCount.toString(),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Button Grid
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : buttons.isEmpty
                              ? Center(
                                  child: Text(
                                    'No buttons yet. Create your first button!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.2,
                                  ),
                                  itemCount: buttons.length,
                                  itemBuilder: (context, index) {
                                    final button = buttons[index];
                                    return GestureDetector(
                                      onLongPress: () {
                                        _showButtonDialog(
                                          button: button,
                                          editIndex: index,
                                        );
                                      },
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween<double>(
                                          begin: 0.8,
                                          end: 1.0,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        builder: (context, value, child) {
                                          return Transform.scale(
                                            scale: value,
                                            child: child,
                                          );
                                        },
                                        child: Card(
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          color: button.color,
                                          child: InkWell(
                                            onTap: () =>
                                                _decrementButtonCount(index),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    button.label,
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.3),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        20,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      button.count.toString(),
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),

                    // Save Changes Button
                    if (hasUnsavedChanges)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: SizedBox(
                          width: isSmallScreen ? double.infinity : 300,
                          child: ElevatedButton.icon(
                            onPressed: _saveButtons,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Changes'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showButtonDialog(),
        tooltip: 'Add Button',
        child: const Icon(Icons.add),
      ),
    );
  }
}
