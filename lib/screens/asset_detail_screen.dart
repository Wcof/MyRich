import 'package:flutter/material.dart';

class AssetDetailScreen extends StatelessWidget {
  final int assetId;

  const AssetDetailScreen({
    super.key,
    required this.assetId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资产详情'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Text('资产详情页面 - 资产ID: $assetId'),
      ),
    );
  }
}
