import 'package:flutter/material.dart';

class AuthInputCard extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController? cookieController;
  final bool enabled;

  const AuthInputCard({
    super.key,
    required this.controller,
    this.cookieController,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Authorization Token',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              enabled: enabled,
              decoration: const InputDecoration(
                hintText: '请输入Bearer Token',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            const Text(
              '请输入完整的Bearer Token，用于API认证',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            
            if (cookieController != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Cookie (可选)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cookieController!,
                enabled: enabled,
                decoration: const InputDecoration(
                  hintText: 'rememberMe=true; username=...; Admin-Token=...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cookie),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              const Text(
                '如果遇到认证问题，请输入完整的Cookie信息',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 