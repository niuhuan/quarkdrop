import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quarkdrop/src/configs/launch_at_startup.dart' as startup;
import 'package:quarkdrop/src/l10n/app_locale.dart';
import 'package:quarkdrop/src/l10n/l10n.dart';
import 'package:quarkdrop/src/models/pending_send_item.dart';
import 'package:quarkdrop/src/models/transfer_job.dart';
import 'package:quarkdrop/src/rust/api/app.dart' as rust_api;
import 'package:quarkdrop/src/state/app_store.dart';
import "manage_devices_card.dart";
import 'package:signals_flutter/signals_flutter.dart';

part 'home_shell_scaffold.dart';
part 'home_shell_send.dart';
part 'home_shell_transfers.dart';
part 'home_shell_settings.dart';
part 'home_shell_mailbox.dart';
part 'home_shell_shared.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});

  final AppStore store;

  @override
  State<HomeShell> createState() => _HomeShellState();
}
