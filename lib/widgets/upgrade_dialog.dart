import 'package:flutter/material.dart';

class UpgradeDialog extends StatelessWidget {
  final VoidCallback onUpgrade;
  final VoidCallback onCancel;

  const UpgradeDialog({
    Key? key,
    required this.onUpgrade,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Limit Reached',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 15),
          const Text(
            'You\'ve used all free credits for today. Upgrade to continue using premium features without limits.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          _buildUpgradeDetails(),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    'Not Now',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: onUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Upgrade to Pro',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeDetails() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildFeatureRow('Unlimited image enhancements'),
          _buildFeatureRow('Priority processing'),
          _buildFeatureRow('Advanced enhancement options'),
          _buildFeatureRow('No watermarks'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(feature, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
