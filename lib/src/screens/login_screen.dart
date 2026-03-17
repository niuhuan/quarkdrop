import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:quarkdrop/src/l10n/l10n.dart';
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _AuthPanel(store: store),
          ),
        ),
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
  bool _showCookieInput = false;

  Future<void> _pasteCookie() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
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
    final l10n = context.l10n;
    return Watch((context) {
      final busy = widget.store.loginInProgress.value;
      final error = widget.store.lastErrorMessage.value;
      final loginUrl = widget.store.quarkLoginUrl.value;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.cloud_sync_rounded,
            size: 48,
            color: Color(0xFFB44818),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.appTitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.loginSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF54635D)),
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEE8),
                borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: busy || loginUrl.isEmpty
                  ? null
                  : () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => _WebViewLoginPage(
                            loginUrl: loginUrl,
                            store: widget.store,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.public_rounded),
              label: Text(l10n.actionUseBrowserLogin),
            ),
          ),
          const SizedBox(height: 12),
          if (!_showCookieInput)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => setState(() => _showCookieInput = true),
                icon: const Icon(Icons.cookie_outlined),
                label: Text(l10n.actionUseCookieLogin),
              ),
            )
          else ...[
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              enabled: !busy,
              autocorrect: false,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: l10n.quarkCookieLabel,
                alignLabelWithHint: true,
                hintText: '__puus=...; kps=...;',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: busy ? null : _pasteCookie,
                  icon: const Icon(Icons.content_paste_go_rounded),
                  tooltip: l10n.actionPaste,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: busy
                    ? null
                    : () => widget.store.submitManualCookie(_controller.text),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(busy ? l10n.actionValidating : l10n.actionSignIn),
              ),
            ),
          ],
        ],
      );
    });
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
  String _status = '';
  bool _capturing = false;
  bool _preparing = true;
  bool _initializedStatus = false;

  @override
  void initState() {
    super.initState();
    _prepareWebView();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedStatus) {
      _status = context.l10n.webLoginInitialStatus;
      _initializedStatus = true;
    }
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
        _status = context.l10n.webLoginFreshSessionReady;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _preparing = false;
        _status = context.l10n.webLoginResetFailed('$error');
      });
    }
  }

  Future<void> _captureCookies(WebUri? currentUrl) async {
    if (_capturing) {
      return;
    }

    setState(() {
      _capturing = true;
      _status = context.l10n.webLoginImportingCookies;
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
          _status = context.l10n.webLoginNoValidatedSession;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _status = context.l10n.webLoginCookieCaptureFailed('$error');
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.embeddedQuarkLoginTitle),
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
            label: Text(l10n.actionCompleteLogin),
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
                        _status = l10n.webLoginPageLoaded;
                      });
                    },
                    onReceivedError: (controller, request, error) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _status = l10n.webLoginLoadFailed(error.description);
                      });
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
