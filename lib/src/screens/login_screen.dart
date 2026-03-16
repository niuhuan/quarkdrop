import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:quarkdrop/src/rust/api/app.dart';
import 'package:quarkdrop/src/state/app_store.dart';
import 'package:signals_flutter/signals_flutter.dart';

const String _quarkLoginUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDF6EC), Color(0xFFE9F4EF)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 900;
                  if (compact) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeroPanel(compact: true),
                          const SizedBox(height: 20),
                          _AuthPanel(store: store),
                        ],
                      ),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _HeroPanel(compact: false)),
                      const SizedBox(width: 20),
                      SizedBox(width: 380, child: _AuthPanel(store: store)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2628), Color(0xFF2D4B48), Color(0xFFCC6629)],
        ),
      ),
      child: Column(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) const Spacer(),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.cloud_sync_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            compact
                ? 'Encrypted relay transfer with a cleaner Quark workflow.'
                : 'Move whole projects through Quark like a polished relay inbox, not a raw cloud folder.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'QuarkDrop will collect cookies inside an embedded WebView, package jobs with manifest and commit markers, then clear the remote relay after a verified receive.',
            style: TextStyle(
              color: Color(0xFFECE5DB),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatPill(label: 'Automatic Cookie Capture'),
              _StatPill(label: 'Chunked Over 4GB'),
              _StatPill(label: 'Manifest + commit.ok.enc'),
            ],
          ),
          if (!compact) const Spacer(),
        ],
      ),
    );
  }
}

class _AuthPanel extends StatefulWidget {
  const _AuthPanel({required this.store});

  final AppStore store;

  @override
  State<_AuthPanel> createState() => _AuthPanelState();
}

class _AuthPanelState extends State<_AuthPanel> {
  late final TextEditingController _controller;

  Future<void> _pasteCookie() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      return;
    }
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _clearCookie() {
    _controller.clear();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.store.loginCookieDraft.value,
    );
    _controller.addListener(() {
      widget.store.updateCookieDraft(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Watch((context) {
      final busy = widget.store.loginInProgress.value;
      final error = widget.store.lastErrorMessage.value;
      final loginUrl = widget.store.quarkLoginUrl.value;
      final rememberedDevices = widget.store.rememberedDevices.value;
      final currentDevice = widget.store.deviceSnapshot.value;
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE8DECF)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign In',
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use the embedded Quark login first. Manual cookie paste stays available as a fallback while the auth flow is still taking shape.',
              style: TextStyle(height: 1.45, color: Color(0xFF54635D)),
            ),
            const SizedBox(height: 18),
            if (rememberedDevices.isNotEmpty) ...[
              _RememberedDevicesCard(
                busy: busy,
                currentDeviceId: currentDevice?.deviceId,
                devices: rememberedDevices,
                onRestore: widget.store.restoreRememberedDevice,
              ),
              const SizedBox(height: 18),
            ],
            OutlinedButton.icon(
              onPressed: busy || loginUrl.isEmpty
                  ? null
                  : () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (context) {
                            return _WebViewLoginPage(
                              loginUrl: loginUrl,
                              store: widget.store,
                            );
                          },
                        ),
                      );
                    },
              icon: const Icon(Icons.public_rounded),
              label: const Text('Open Embedded Quark Login'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Or paste the current cookie string directly:',
                    style: TextStyle(
                      color: Color(0xFF54635D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: busy ? null : _pasteCookie,
                  icon: const Icon(Icons.content_paste_go_rounded),
                  label: const Text('Paste'),
                ),
                TextButton(
                  onPressed: busy ? null : _clearCookie,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _controller,
              minLines: 4,
              maxLines: 6,
              enabled: !busy,
              enableInteractiveSelection: true,
              autocorrect: false,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Quark Cookie',
                alignLabelWithHint: true,
                hintText: '__puus=...; kps=...;',
                border: OutlineInputBorder(),
              ),
              onSubmitted: busy
                  ? null
                  : (_) async {
                      await widget.store.submitManualCookie(_controller.text);
                    },
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F1E8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                loginUrl.isEmpty
                    ? 'Login URL unavailable.'
                    : 'Login URL: $loginUrl',
                style: const TextStyle(color: Color(0xFF596860), height: 1.45),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEE8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  error,
                  style: const TextStyle(
                    color: Color(0xFF9B3D16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            const _ChecklistTile(
              icon: Icons.cookie_outlined,
              title: 'Auto-capture when possible',
              subtitle:
                  'The embedded WebView can collect cookies directly from Quark before falling back to manual paste.',
            ),
            const SizedBox(height: 14),
            const _ChecklistTile(
              icon: Icons.inventory_2_outlined,
              title: 'Relay-safe naming stays internal',
              subtitle:
                  'Users see transfer jobs, not Quark auto-renamed objects or folder ids.',
            ),
            const SizedBox(height: 14),
            const _ChecklistTile(
              icon: Icons.lock_outline,
              title: 'Commit remains the visibility gate',
              subtitle:
                  'Inbox jobs only surface after blobs, manifest, and commit complete.',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        await widget.store.submitManualCookie(_controller.text);
                      },
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  busy ? 'Validating Cookie...' : 'Validate Cookie & Enter',
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _RememberedDevicesCard extends StatelessWidget {
  const _RememberedDevicesCard({
    required this.busy,
    required this.currentDeviceId,
    required this.devices,
    required this.onRestore,
  });

  final bool busy;
  final String? currentDeviceId;
  final List<RememberedDevice> devices;
  final Future<void> Function(String deviceId) onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Restore Device',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'If this install already used QuarkDrop before, choose which remembered device identity should come back before signing in again.',
            style: TextStyle(color: Color(0xFF596860), height: 1.45),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < devices.length; index++) ...[
            _RememberedDeviceTile(
              busy: busy,
              device: devices[index],
              isSelected:
                  devices[index].deviceId == currentDeviceId ||
                  devices[index].isCurrent,
              onRestore: onRestore,
            ),
            if (index != devices.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _RememberedDeviceTile extends StatelessWidget {
  const _RememberedDeviceTile({
    required this.busy,
    required this.device,
    required this.isSelected,
    required this.onRestore,
  });

  final bool busy;
  final RememberedDevice device;
  final bool isSelected;
  final Future<void> Function(String deviceId) onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFCC6629) : const Color(0xFFE3D8C8),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.deviceName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Device ${device.deviceId}',
                  style: const TextStyle(color: Color(0xFF596860)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: busy || isSelected
                ? null
                : () async {
                    await onRestore(device.deviceId);
                  },
            child: Text(isSelected ? 'Using This Device' : 'Restore'),
          ),
        ],
      ),
    );
  }
}

class _WebViewLoginPage extends StatefulWidget {
  const _WebViewLoginPage({required this.loginUrl, required this.store});

  final String loginUrl;
  final AppStore store;

  @override
  State<_WebViewLoginPage> createState() => _WebViewLoginPageState();
}

class _WebViewLoginPageState extends State<_WebViewLoginPage> {
  final _cookieManager = CookieManager.instance();
  final _progress = ValueNotifier<double>(0);
  String _status =
      'Sign in to Quark, then tap Complete Login to import the cookies.';
  bool _capturing = false;
  bool _preparing = true;

  @override
  void initState() {
    super.initState();
    _prepareWebView();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _prepareWebView() async {
    try {
      await _cookieManager.deleteAllCookies();
      if (!mounted) {
        return;
      }
      setState(() {
        _preparing = false;
        _status =
            'Fresh login session ready. Sign in to Quark, then tap Complete Login.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _preparing = false;
        _status = 'Failed to reset the embedded browser session: $error';
      });
    }
  }

  Future<void> _captureCookies(WebUri? currentUrl) async {
    if (_capturing) {
      return;
    }

    setState(() {
      _capturing = true;
      _status = 'Importing Quark cookies from the embedded browser...';
    });

    try {
      final candidates = <WebUri>[?currentUrl, WebUri(widget.loginUrl)];
      final visited = <String>{};
      for (final candidate in candidates) {
        final key = candidate.toString();
        if (!visited.add(key)) {
          continue;
        }

        final cookies = await _cookieManager.getCookies(url: candidate);
        final cookieHeader = _cookieHeader(cookies);
        if (cookieHeader.isEmpty) {
          continue;
        }

        final accepted = await widget.store.submitWebViewCookie(cookieHeader);
        if (!mounted) {
          return;
        }
        if (accepted) {
          Navigator.of(context).pop();
          return;
        }
      }

      if (mounted) {
        setState(() {
          _status =
              'No validated Quark session yet. Finish the login flow, then tap Complete Login again.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _status = 'Cookie capture failed: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
        });
      }
    }
  }

  String _cookieHeader(List<Cookie> cookies) {
    final seen = <String>{};
    final pairs = <String>[];
    for (final cookie in cookies) {
      if (cookie.name.isEmpty ||
          cookie.value.isEmpty ||
          !seen.add(cookie.name)) {
        continue;
      }
      pairs.add('${cookie.name}=${cookie.value}');
    }
    return pairs.join('; ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Embedded Quark Login'),
        actions: [
          ValueListenableBuilder<double>(
            valueListenable: _progress,
            builder: (context, value, _) {
              if (value <= 0 || value >= 1) {
                return const SizedBox.shrink();
              }
              return Center(
                child: SizedBox(
                  width: 120,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: LinearProgressIndicator(value: value),
                  ),
                ),
              );
            },
          ),
          TextButton.icon(
            onPressed: _preparing || _capturing
                ? null
                : () async {
                    await _captureCookies(WebUri(widget.loginUrl));
                  },
            icon: _capturing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: const Text('Complete Login'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            color: const Color(0xFFF6F1E8),
            child: Text(
              _status,
              style: const TextStyle(color: Color(0xFF596860), height: 1.45),
            ),
          ),
          Expanded(
            child: _preparing
                ? const Center(child: CircularProgressIndicator())
                : InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(widget.loginUrl)),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      thirdPartyCookiesEnabled: true,
                      userAgent: _quarkLoginUserAgent,
                      isInspectable: true,
                      clearCache: true,
                      transparentBackground: false,
                    ),
                    onProgressChanged: (controller, progress) {
                      _progress.value = progress / 100.0;
                    },
                    onLoadStop: (controller, url) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _status =
                            'Page loaded. Finish the Quark login flow, then tap Complete Login.';
                      });
                    },
                    onReceivedError: (controller, request, error) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _status =
                            'Web login failed to load: ${error.description}';
                      });
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF4EEE4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF5B6B64), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
