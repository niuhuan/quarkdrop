part of 'home_shell.dart';

class _HomeShellState extends State<HomeShell> {
  final List<void Function()> _disposeEffects = [];

  @override
  void initState() {
    super.initState();
    _watchStatusSignal(widget.store.sendStatusMessage);
    _watchStatusSignal(widget.store.resumeStatusMessage);
    _watchStatusSignal(widget.store.transferActionStatusMessage);
    _watchStatusSignal(widget.store.receiveStatusMessage);
    _watchStatusSignal(widget.store.mailboxStatusMessage);
    _watchStatusSignal(widget.store.deviceNameStatusMessage);
    _watchStatusSignal(widget.store.localeStatusMessage);
  }

  void _watchStatusSignal(Signal<String?> signal) {
    String? prev;
    final dispose = effect(() {
      final msg = signal.value;
      if (msg != null && msg != prev) {
        prev = msg;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(msg),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              ),
            );
          Future.delayed(const Duration(seconds: 5), () {
            if (signal.value == msg) {
              signal.value = null;
            }
          });
        });
      } else if (msg == null) {
        prev = null;
      }
    });
    _disposeEffects.add(dispose);
  }

  @override
  void dispose() {
    for (final dispose in _disposeEffects) {
      dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final store = widget.store;
      final destination = store.destination.value;
      final destinations = _visibleDestinations(store.autoReceiveEnabled.value);
      return LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 980;
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(desktop ? 18 : 0),
                child: desktop
                    ? _DesktopScaffold(store: store)
                    : _MobileScaffold(store: store),
              ),
            ),
            bottomNavigationBar: desktop
                ? null
                : NavigationBar(
                    height: 72,
                    selectedIndex: _selectedDestinationIndex(
                      destination,
                      destinations,
                    ),
                    onDestinationSelected: (index) {
                      store.selectDestination(destinations[index]);
                    },
                    destinations: destinations
                        .map(
                          (destination) =>
                              _navigationDestinationFor(context, destination),
                        )
                        .toList(growable: false),
                  ),
          );
        },
      );
    });
  }
}

class _DesktopScaffold extends StatelessWidget {
  const _DesktopScaffold({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DesktopRail(store: store),
        const SizedBox(width: 18),
        Expanded(child: _MainWorkspace(store: store)),
      ],
    );
  }
}

class _MobileScaffold extends StatelessWidget {
  const _MobileScaffold({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return _MainWorkspace(store: store);
  }
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final l10n = context.l10n;
      final selected = store.destination.value;
      final values = _visibleDestinations(store.autoReceiveEnabled.value);
      var selectedIndex = values.indexOf(selected);
      if (selectedIndex == -1) {
        selectedIndex = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          store.selectDestination(values.first);
        });
      }

      return Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E4E4)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.appTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                itemCount: values.length,
                itemBuilder: (context, index) {
                  final dest = values[index];
                  final isSelected = selectedIndex == index;

                  IconData iconData;
                  IconData selectedIconData;
                  String label;
                  switch (dest) {
                    case AppDestination.send:
                      iconData = Icons.send_outlined;
                      selectedIconData = Icons.send_rounded;
                      label = l10n.navSend;
                      break;
                    case AppDestination.inbox:
                      iconData = Icons.inbox_outlined;
                      selectedIconData = Icons.inbox_rounded;
                      label = l10n.navMailbox;
                      break;
                    case AppDestination.transfers:
                      iconData = Icons.sync_alt_outlined;
                      selectedIconData = Icons.sync_alt_rounded;
                      label = l10n.navTransfers;
                      break;
                    case AppDestination.settings:
                      iconData = Icons.tune_outlined;
                      selectedIconData = Icons.tune_rounded;
                      label = l10n.navSettings;
                      break;
                  }

                  final theme = Theme.of(context);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () => store.selectDestination(dest),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? selectedIconData : iconData,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              label,
                              style: TextStyle(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

List<AppDestination> _visibleDestinations(bool autoReceiveEnabled) {
  return [
    AppDestination.send,
    if (!autoReceiveEnabled) AppDestination.inbox,
    AppDestination.transfers,
    AppDestination.settings,
  ];
}

int _selectedDestinationIndex(
  AppDestination current,
  List<AppDestination> visibleDestinations,
) {
  final index = visibleDestinations.indexOf(current);
  return index == -1 ? 0 : index;
}

NavigationDestination _navigationDestinationFor(
  BuildContext context,
  AppDestination destination,
) {
  final l10n = context.l10n;
  switch (destination) {
    case AppDestination.send:
      return NavigationDestination(
        icon: const Icon(Icons.send_outlined),
        selectedIcon: const Icon(Icons.send_rounded),
        label: l10n.navSend,
      );
    case AppDestination.inbox:
      return NavigationDestination(
        icon: const Icon(Icons.inbox_outlined),
        selectedIcon: const Icon(Icons.inbox_rounded),
        label: l10n.navMailbox,
      );
    case AppDestination.transfers:
      return NavigationDestination(
        icon: const Icon(Icons.sync_alt_outlined),
        selectedIcon: const Icon(Icons.sync_alt_rounded),
        label: l10n.navTransfers,
      );
    case AppDestination.settings:
      return NavigationDestination(
        icon: const Icon(Icons.tune_outlined),
        selectedIcon: const Icon(Icons.tune_rounded),
        label: l10n.navSettings,
      );
  }
}

class _MainWorkspace extends StatelessWidget {
  const _MainWorkspace({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      switch (store.destination.value) {
        case AppDestination.send:
          return _SendPane(store: store);
        case AppDestination.inbox:
          return _InboxPane(store: store);
        case AppDestination.transfers:
          return _TransfersPane(store: store);
        case AppDestination.settings:
          return _SettingsPane(store: store);
      }
    });
  }
}
