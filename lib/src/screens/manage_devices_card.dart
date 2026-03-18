import 'package:flutter/material.dart';
import 'package:quarkdrop/src/state/app_store.dart';
import "package:quarkdrop/src/l10n/l10n.dart";
import 'manage_devices_screen.dart';

class ManageDevicesCard extends StatelessWidget {
  const ManageDevicesCard({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7DED0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ManageDevicesScreen(store: store),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.devices_outlined, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.existingDevicesTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_right_rounded,
                color: Color(0xFF5C6A64),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
