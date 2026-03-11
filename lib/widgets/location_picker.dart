import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationPicker extends StatefulWidget {
  final String? initialLocation;
  final Function(String) onLocationSelected;

  const LocationPicker({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.initialLocation ?? '');
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _openMap() async {
    String mapUrl;
    
    if (Platform.isMacOS || Platform.isIOS) {
      mapUrl = 'https://maps.apple.com/';
    } else if (Platform.isWindows || Platform.isAndroid || Platform.isLinux) {
      mapUrl = 'https://www.google.com/maps';
    } else {
      mapUrl = 'https://www.google.com/maps';
    }

    final uri = Uri.parse(mapUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开地图应用')),
        );
      }
    }
  }

  void _showLocationHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('如何选择位置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. 点击"打开地图"按钮'),
            const SizedBox(height: 8),
            const Text('2. 在地图中搜索或选择位置'),
            const SizedBox(height: 8),
            const Text('3. 复制地址信息'),
            const SizedBox(height: 8),
            const Text('4. 返回并粘贴到位置输入框'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _locationController,
            maxLines: 1,
            decoration: InputDecoration(
              labelText: '位置 (可选)',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.location_on),
              suffixIcon: _locationController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _locationController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              widget.onLocationSelected(value);
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.map),
          tooltip: '打开地图',
          onPressed: _openMap,
        ),
        IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: '帮助',
          onPressed: _showLocationHelp,
        ),
      ],
    );
  }
}
