import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/rfid_reader_controller.dart';
import '../domain/reader_config.dart';
import '../domain/reader_status.dart';
import '../domain/reader_vendor.dart';

class ReaderSettingsScreen extends ConsumerStatefulWidget {
  const ReaderSettingsScreen({super.key});

  @override
  ConsumerState<ReaderSettingsScreen> createState() =>
      _ReaderSettingsScreenState();
}

class _ReaderSettingsScreenState extends ConsumerState<ReaderSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _powerCtrl;
  late final TextEditingController _antennaMaskCtrl;
  ReaderVendor _vendor = ReaderVendor.sensormaticIdx4000;
  bool _preventDuplicates = true;
  bool _saving = false;

  bool get _vendorOverridesRf => !_vendor.honorsRfOverrides;

  @override
  void initState() {
    super.initState();
    final current = ref.read(rfidReaderControllerProvider).config;
    _vendor = current?.vendor ?? ReaderVendor.sensormaticIdx4000;
    _hostCtrl = TextEditingController(text: current?.host ?? '');
    _portCtrl = TextEditingController(text: '${current?.port ?? 5084}');
    _powerCtrl = TextEditingController(
      text: (current?.txPowerDbm ?? 30.0).toStringAsFixed(1),
    );
    _antennaMaskCtrl = TextEditingController(
      text:
          '0x${(current?.antennaMask ?? 0xFFFF).toRadixString(16).toUpperCase()}',
    );
    _preventDuplicates = current?.preventDuplicates ?? true;
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _powerCtrl.dispose();
    _antennaMaskCtrl.dispose();
    super.dispose();
  }

  /// Apply the form values to the current runtime only — does not connect and
  /// does NOT persist. On the next app start the reader is re-initialized from
  /// the kiosk's server `rfid_config`, overriding whatever is set here.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final mask = _parseHexOrInt(_antennaMaskCtrl.text);
    final config = ReaderConfig(
      vendor: _vendor,
      host: _hostCtrl.text.trim(),
      port: int.parse(_portCtrl.text.trim()),
      antennaMask: mask,
      txPowerDbm: double.parse(_powerCtrl.text.trim()),
      preventDuplicates: _preventDuplicates,
    );
    try {
      await ref
          .read(rfidReaderControllerProvider.notifier)
          .applyConfig(config, connect: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Applied for this session (resets on restart)'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Multifunctional connection action, based on the current reader status:
  ///   - not connected → connect (using the currently saved config)
  ///   - connecting    → cancel the in-flight attempt
  ///   - connected     → disconnect
  ///
  /// Does not save the form; connect uses whatever config was last persisted.
  Future<void> _toggleConnection() async {
    final notifier = ref.read(rfidReaderControllerProvider.notifier);
    final status = ref.read(rfidReaderControllerProvider).status;

    setState(() => _saving = true);
    try {
      if (status == ReaderStatus.connecting) {
        // CANCEL an in-flight attempt — aborts without waiting the timeout.
        await notifier.cancelConnect();
      } else if (status.isConnected) {
        // DISCONNECT a live connection.
        await notifier.disconnect();
      } else {
        if (ref.read(rfidReaderControllerProvider).config == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Save a config first')));
          return;
        }
        await notifier.connect();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Label for the multifunctional connection button per current status.
  String _connectionActionLabel(ReaderStatus status) {
    if (status == ReaderStatus.connecting) return 'CANCEL';
    if (status.isConnected) return 'DISCONNECT';
    return 'CONNECT';
  }

  int _parseHexOrInt(String input) {
    final trimmed = input.trim();
    if (trimmed.toLowerCase().startsWith('0x')) {
      return int.parse(trimmed.substring(2), radix: 16);
    }
    return int.parse(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(rfidReaderControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  KioskTokens.spaceL,
                  0,
                  KioskTokens.spaceL,
                  KioskTokens.spaceL,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: KioskTokens.maxContentWidth,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StatusCard(
                            status: state.status,
                            message: state.lastError,
                            vendorLabel:
                                state.config?.vendor.displayName ?? '—',
                          ),
                          const SizedBox(height: KioskTokens.spaceL),
                          _SectionLabel(label: 'Vendor'),
                          const SizedBox(height: KioskTokens.spaceS),
                          DropdownButtonFormField<ReaderVendor>(
                            initialValue: _vendor,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: ReaderVendor.values
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v.displayName),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _vendor = v!),
                          ),
                          const SizedBox(height: KioskTokens.spaceL),
                          _SectionLabel(label: 'Network'),
                          const SizedBox(height: KioskTokens.spaceS),
                          TextFormField(
                            controller: _hostCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Host / IP',
                              hintText: '192.168.1.50',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: KioskTokens.spaceM),
                          TextFormField(
                            controller: _portCtrl,
                            decoration: const InputDecoration(
                              labelText: 'LLRP Port',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n <= 0 || n > 65535) {
                                return 'Invalid port';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: KioskTokens.spaceL),
                          _SectionLabel(label: 'RF Parameters'),
                          const SizedBox(height: KioskTokens.spaceS),
                          TextFormField(
                            controller: _powerCtrl,
                            decoration: InputDecoration(
                              labelText: _vendorOverridesRf
                                  ? 'Tx Power (dBm) — reader-managed'
                                  : 'Tx Power (dBm)',
                              helperText: _vendorOverridesRf
                                  ? 'This reader ignores LLRP power overrides. Configure on the reader itself.'
                                  : 'Driver clamps to vendor range',
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            enabled: !_vendorOverridesRf,
                            validator: (v) {
                              final n = double.tryParse(v ?? '');
                              if (n == null || n < 0 || n > 36) {
                                return 'Enter 0–36 dBm';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: KioskTokens.spaceM),
                          TextFormField(
                            controller: _antennaMaskCtrl,
                            decoration: InputDecoration(
                              labelText: _vendorOverridesRf
                                  ? 'Antenna Mask — reader-managed'
                                  : 'Antenna Mask',
                              helperText: _vendorOverridesRf
                                  ? 'This reader ignores LLRP antenna selection. Configure on the reader itself.'
                                  : 'Hex (0xFFFF) or decimal; bit 0 = antenna 1',
                              border: const OutlineInputBorder(),
                            ),
                            enabled: !_vendorOverridesRf,
                            validator: (v) {
                              try {
                                final n = _parseHexOrInt(v ?? '');
                                if (n <= 0) return 'Must be > 0';
                                return null;
                              } catch (_) {
                                return 'Invalid';
                              }
                            },
                          ),
                          const SizedBox(height: KioskTokens.spaceL),
                          _SectionLabel(label: 'Reporting'),
                          const SizedBox(height: KioskTokens.spaceS),
                          SwitchListTile(
                            value: _preventDuplicates,
                            onChanged: (v) =>
                                setState(() => _preventDuplicates = v),
                            title: const Text('Prevent Duplicates'),
                            subtitle: const Text(
                              'Report each EPC only once per inventory run. '
                              'List clears on every START INVENTORY.',
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: KioskTokens.spaceXL),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _saving ? null : _save,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                  ),
                                  child: const Text('SAVE'),
                                ),
                              ),
                              const SizedBox(width: KioskTokens.spaceM),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _saving ? null : _toggleConnection,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    backgroundColor:
                                        state.status.isConnected ||
                                            state.status ==
                                                ReaderStatus.connecting
                                        ? scheme.error
                                        : null,
                                  ),
                                  child: Text(
                                    _saving
                                        ? 'WORKING…'
                                        : _connectionActionLabel(state.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: KioskTokens.spaceL),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: state.status.canStop
                                      ? () => ref
                                            .read(
                                              rfidReaderControllerProvider
                                                  .notifier,
                                            )
                                            .stopInventory()
                                      : (state.status.canStart
                                            ? () => ref
                                                  .read(
                                                    rfidReaderControllerProvider
                                                        .notifier,
                                                  )
                                                  .startInventory()
                                            : null),
                                  icon: Icon(
                                    state.status == ReaderStatus.reading
                                        ? Icons.stop_circle_outlined
                                        : Icons.play_circle_outline,
                                  ),
                                  label: Text(
                                    state.status == ReaderStatus.reading
                                        ? 'STOP INVENTORY'
                                        : 'START INVENTORY',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    foregroundColor: scheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kiosk-style header matching the catalog/session screens: back button, a
/// section icon + title on the start edge. No trailing action.
class _Header extends StatelessWidget {
  const _Header();

  static const double _appBarHeight = 96;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      height: 1.0,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KioskTokens.spaceL,
        KioskTokens.spaceL,
        KioskTokens.spaceL,
        KioskTokens.spaceM,
      ),
      child: SizedBox(
        height: _appBarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 40,
              icon: const Icon(Icons.arrow_back_rounded),
              color: scheme.onSurfaceVariant,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
            ),
            const SizedBox(width: KioskTokens.spaceM),
            Flexible(
              child: Text(
                'Reader Settings',
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        letterSpacing: 2,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.vendorLabel,
    this.message,
  });

  final ReaderStatus status;
  final String vendorLabel;
  final String? message;

  Color _color(ColorScheme scheme) {
    switch (status) {
      case ReaderStatus.reading:
      case ReaderStatus.connected:
      case ReaderStatus.idle:
        return scheme.tertiary;
      case ReaderStatus.connecting:
        return scheme.secondary;
      case ReaderStatus.error:
        return scheme.error;
      case ReaderStatus.offline:
      case ReaderStatus.disconnected:
        return scheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _color(scheme);
    return Container(
      padding: const EdgeInsets.all(KioskTokens.spaceM),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: KioskTokens.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.name.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  vendorLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (message != null && message!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
