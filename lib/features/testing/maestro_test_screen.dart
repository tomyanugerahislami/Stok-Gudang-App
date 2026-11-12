import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Model untuk satu file test Maestro
class MaestroTest {
  final String id;
  final String title;
  final String description;
  final String fileName;
  final String filePath;
  final IconData icon;
  final Color color;

  const MaestroTest({
    required this.id,
    required this.title,
    required this.description,
    required this.fileName,
    required this.filePath,
    required this.icon,
    required this.color,
  });
}

class MaestroTestScreen extends StatefulWidget {
  const MaestroTestScreen({super.key});

  @override
  State<MaestroTestScreen> createState() => _MaestroTestScreenState();
}

class _MaestroTestScreenState extends State<MaestroTestScreen> {
  static const String _maestroDir = 'maestro';

  final List<MaestroTest> _tests = const [
    MaestroTest(
      id: '01',
      title: 'Login Auth & Validasi',
      description: 'Menguji alur validasi field kosong, validasi format email salah, serta login sukses via role demo admin.',
      fileName: '01_login_auth_validasi.yaml',
      filePath: 'maestro/01_login_auth_validasi.yaml',
      icon: Icons.login_rounded,
      color: Color(0xFF1E3A8A),
    ),
    MaestroTest(
      id: '02',
      title: 'Navigasi Antar Menu',
      description: 'Menguji transisi mulus antar menu utama (Dashboard, Produk, Barang Masuk, Stok & Mutasi, dan Scan Barcode).',
      fileName: '02_navigasi_antar_menu.yaml',
      filePath: 'maestro/02_navigasi_antar_menu.yaml',
      icon: Icons.navigation_rounded,
      color: Color(0xFF0D9488),
    ),
    MaestroTest(
      id: '03',
      title: 'CRUD Produk',
      description: 'Menguji alur lengkap Create produk baru, pencarian Read, serta inspeksi detail produk di katalog.',
      fileName: '03_crud_produk.yaml',
      filePath: 'maestro/03_crud_produk.yaml',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF7C3AED),
    ),
    MaestroTest(
      id: '04',
      title: 'Scan & Mutasi Stok Gudang',
      description: 'Menguji fitur pemindaian barcode manual serta monitoring mutasi stok fisik di kartu stok gudang.',
      fileName: '04_scan_dan_mutasi_stok.yaml',
      filePath: 'maestro/04_scan_dan_mutasi_stok.yaml',
      icon: Icons.qr_code_scanner_rounded,
      color: Color(0xFFD97706),
    ),
  ];

  // State per test: null = idle, true = running, false = done
  final Map<String, _TestState> _testStates = {};
  final Map<String, String> _testLogs = {};
  final Map<String, String?> _yamlContents = {};

  String? _selectedTestId;
  bool _runningAll = false;

  @override
  void initState() {
    super.initState();
    for (final t in _tests) {
      _testStates[t.id] = _TestState.idle;
      _testLogs[t.id] = '';
    }
    // Baca YAML semua file di background
    _loadAllYaml();
  }

  File _resolveTestFile(MaestroTest t) {
    final direct = File(t.filePath);
    if (direct.existsSync()) return direct;
    final relative = File('maestro/${t.fileName}');
    if (relative.existsSync()) return relative;
    return direct;
  }

  Future<void> _loadAllYaml() async {
    for (final t in _tests) {
      try {
        final file = _resolveTestFile(t);
        if (await file.exists()) {
          final content = await file.readAsString();
          if (mounted) {
            setState(() => _yamlContents[t.id] = content);
          }
        } else {
          if (mounted) {
            setState(() => _yamlContents[t.id] = '# File tidak ditemukan:\n# ${t.filePath}\n# atau maestro/${t.fileName}');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _yamlContents[t.id] = '# Error membaca file: $e');
        }
      }
    }
  }

  Future<void> _runTest(MaestroTest test) async {
    setState(() {
      _testStates[test.id] = _TestState.running;
      _testLogs[test.id] = '⏳ Menjalankan ${test.fileName}...\n';
    });

    try {
      final file = _resolveTestFile(test);
      final workDir = Directory(_maestroDir).existsSync() ? _maestroDir : Directory.current.path;
      final result = await Process.run(
        'maestro',
        ['test', file.path],
        workingDirectory: workDir,
        runInShell: true,
      );
      final output = result.stdout.toString() + result.stderr.toString();
      final success = result.exitCode == 0;

      setState(() {
        _testStates[test.id] = success ? _TestState.passed : _TestState.failed;
        _testLogs[test.id] =
            '${success ? '✅ PASSED' : '❌ FAILED'} (exit code: ${result.exitCode})\n\n$output';
      });
    } catch (e) {
      setState(() {
        _testStates[test.id] = _TestState.error;
        _testLogs[test.id] =
            '⚠️ Error menjalankan test:\n$e\n\n'
            'Pastikan Maestro sudah terinstall.\n'
            'Install: iwr https://get.maestro.mobile.dev | iex';
      });
    }
  }

  Future<void> _runAllTests() async {
    setState(() => _runningAll = true);
    for (final test in _tests) {
      await _runTest(test);
    }
    setState(() => _runningAll = false);
  }

  void _resetTest(MaestroTest test) {
    setState(() {
      _testStates[test.id] = _TestState.idle;
      _testLogs[test.id] = '';
    });
  }

  void _resetAll() {
    setState(() {
      for (final t in _tests) {
        _testStates[t.id] = _TestState.idle;
        _testLogs[t.id] = '';
      }
      _runningAll = false;
    });
  }

  int get _passedCount =>
      _testStates.values.where((s) => s == _TestState.passed).length;
  int get _failedCount =>
      _testStates.values.where((s) => s == _TestState.failed || s == _TestState.error).length;
  int get _runningCount =>
      _testStates.values.where((s) => s == _TestState.running).length;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bug_report_rounded, size: 22),
            SizedBox(width: 8),
            Text('Maestro UI Tests'),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_runningCount == 0)
            IconButton(
              onPressed: _resetAll,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset semua',
            ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _runningAll || _runningCount > 0 ? null : _runAllTests,
              icon: _runningAll
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(_runningAll ? 'Menjalankan...' : 'Jalankan Semua'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          _SummaryBar(
            total: _tests.length,
            passed: _passedCount,
            failed: _failedCount,
            running: _runningCount,
          ),
          Expanded(
            child: isWide
                ? _buildWideLayout()
                : _buildNarrowLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Panel kiri: list test cards
        SizedBox(
          width: 340,
          child: _buildTestList(),
        ),
        const VerticalDivider(width: 1),
        // Panel kanan: detail / YAML / log
        Expanded(
          child: _selectedTestId != null
              ? _buildDetailPanel(_tests.firstWhere((t) => t.id == _selectedTestId))
              : _buildEmptyDetail(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return _selectedTestId != null
        ? Column(
            children: [
              // Back button
              Container(
                color: Colors.white,
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => setState(() => _selectedTestId = null),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali ke daftar test'),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _buildDetailPanel(
                  _tests.firstWhere((t) => t.id == _selectedTestId),
                ),
              ),
            ],
          )
        : _buildTestList();
  }

  Widget _buildTestList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _tests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final test = _tests[index];
        final state = _testStates[test.id] ?? _TestState.idle;
        final isSelected = _selectedTestId == test.id;

        return _TestCard(
          test: test,
          state: state,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedTestId = test.id),
          onRun: state == _TestState.running ? null : () => _runTest(test),
          onReset: state != _TestState.idle ? () => _resetTest(test) : null,
        );
      },
    );
  }

  Widget _buildEmptyDetail() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Pilih test di kiri untuk melihat detail',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(MaestroTest test) {
    final state = _testStates[test.id] ?? _TestState.idle;
    final log = _testLogs[test.id] ?? '';
    final yaml = _yamlContents[test.id];

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: test.color.withAlpha(20),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: test.color,
                  child: Icon(test.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        test.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StateChip(state: state),
              ],
            ),
          ),
          // File info + action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    test.filePath,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: test.filePath));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Path disalin!')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: 'Salin path',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          // Tabs
          TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.code_rounded), text: 'YAML'),
              Tab(icon: Icon(Icons.terminal_rounded), text: 'Output Log'),
            ],
            labelColor: test.color,
            indicatorColor: test.color,
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: YAML content
                _YamlViewer(
                  content: yaml ?? '⏳ Memuat...',
                  color: test.color,
                  fileName: test.fileName,
                ),
                // Tab 2: Log output
                _LogViewer(
                  log: log,
                  state: state,
                  onRun: state == _TestState.running ? null : () => _runTest(test),
                  onReset: state != _TestState.idle ? () => _resetTest(test) : null,
                  testColor: test.color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────────

enum _TestState { idle, running, passed, failed, error }

class _SummaryBar extends StatelessWidget {
  final int total, passed, failed, running;
  const _SummaryBar({
    required this.total,
    required this.passed,
    required this.failed,
    required this.running,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E3A8A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _SummaryItem(label: 'Total', value: total, color: Colors.white70),
          const SizedBox(width: 24),
          _SummaryItem(label: 'Passed', value: passed, color: const Color(0xFF34D399)),
          const SizedBox(width: 24),
          _SummaryItem(label: 'Failed', value: failed, color: const Color(0xFFF87171)),
          const SizedBox(width: 24),
          if (running > 0)
            _SummaryItem(label: 'Running', value: running, color: const Color(0xFFFBBF24)),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color.withAlpha(200), fontSize: 12)),
      ],
    );
  }
}

class _TestCard extends StatelessWidget {
  final MaestroTest test;
  final _TestState state;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onRun;
  final VoidCallback? onReset;

  const _TestCard({
    required this.test,
    required this.state,
    required this.isSelected,
    this.onTap,
    this.onRun,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: test.color, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: test.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(test.icon, color: test.color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          test.fileName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StateChip(state: state, compact: true),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                test.description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReset != null)
                    TextButton.icon(
                      onPressed: onReset,
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('Reset', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  const SizedBox(width: 6),
                  FilledButton.icon(
                    onPressed: onRun,
                    icon: state == _TestState.running
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 16),
                    label: Text(
                      state == _TestState.running ? 'Running...' : 'Jalankan',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: test.color,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  final _TestState state;
  final bool compact;
  const _StateChip({required this.state, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (state) {
      _TestState.idle => ('Idle', Colors.grey, Icons.circle_outlined),
      _TestState.running => ('Running', Colors.amber, Icons.autorenew_rounded),
      _TestState.passed => ('Passed', const Color(0xFF059669), Icons.check_circle_rounded),
      _TestState.failed => ('Failed', const Color(0xFFDC2626), Icons.cancel_rounded),
      _TestState.error => ('Error', const Color(0xFFD97706), Icons.warning_rounded),
    };

    if (compact) {
      return Icon(icon, color: color, size: 20);
    }

    return Chip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withAlpha(20),
      side: BorderSide(color: color.withAlpha(80)),
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.only(right: 8),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _YamlViewer extends StatelessWidget {
  final String content;
  final Color color;
  final String fileName;

  const _YamlViewer({
    required this.content,
    required this.color,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF1E1E2E),
          child: Row(
            children: [
              const Icon(Icons.code_rounded, color: Colors.white54, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('YAML disalin!')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, color: Colors.white54, size: 16),
                tooltip: 'Salin YAML',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFF1E1E2E),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                content,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Color(0xFFCDD6F4),
                  height: 1.6,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogViewer extends StatelessWidget {
  final String log;
  final _TestState state;
  final VoidCallback? onRun;
  final VoidCallback? onReset;
  final Color testColor;

  const _LogViewer({
    required this.log,
    required this.state,
    required this.testColor,
    this.onRun,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Action bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              const Icon(Icons.terminal_rounded, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              const Text('Output', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const Spacer(),
              if (onReset != null)
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Reset', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onRun,
                icon: state == _TestState.running
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 16),
                label: Text(
                  state == _TestState.running ? 'Running...' : 'Jalankan Test',
                  style: const TextStyle(fontSize: 12),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: testColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Log output
        Expanded(
          child: Container(
            color: const Color(0xFF0D1117),
            child: log.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_outline_rounded,
                            size: 48, color: Colors.grey.shade700),
                        const SizedBox(height: 12),
                        Text(
                          'Tekan "Jalankan Test" untuk melihat output',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      log,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Color(0xFFE6EDF3),
                        height: 1.5,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

