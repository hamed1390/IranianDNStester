import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const DnsTesterApp());
}

// Navy Color Constants
class AppColors {
  static const Color navy = Color(0xFF1E3A5F);
  static const Color navyLight = Color(0xFF2D4A6F);
  static const Color navyDark = Color(0xFF0F2A4A);
  static const Color white = Colors.white;
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyMedium = Color(0xFFE0E0E0);
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFF57C00);
}

class DnsTesterApp extends StatelessWidget {
  const DnsTesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DNS Tester',
      locale: const Locale('fa', 'IR'),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Vazirmatn',
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          primary: AppColors.navy,
          surface: AppColors.white,
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [DnsTestPage(), GuidePageContent()],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.greyMedium, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.navy,
          unselectedItemColor: Colors.grey,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dns_outlined),
              activeIcon: Icon(Icons.dns),
              label: 'تست DNS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'راهنما',
            ),
          ],
        ),
      ),
    );
  }
}

// DNS Range model
class DnsRange {
  final String name;
  final String prefix;
  bool selected;

  DnsRange({required this.name, required this.prefix, this.selected = true});
}

// Test domain options
class TestDomain {
  final String name;
  final String domain;

  const TestDomain({required this.name, required this.domain});
}

class DnsResult {
  final String ip;
  int latency;
  String status;
  bool isTesting;
  bool isFirewallBlocked;
  String? firewallIp;

  DnsResult({
    required this.ip,
    this.latency = -1,
    this.status = "در انتظار",
    this.isTesting = false,
    this.isFirewallBlocked = false,
    this.firewallIp,
  });
}

class DnsTestPage extends StatefulWidget {
  const DnsTestPage({super.key});

  @override
  State<DnsTestPage> createState() => _DnsTestPageState();
}

class _DnsTestPageState extends State<DnsTestPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _limitController = TextEditingController(
    text: "50",
  );
  List<DnsResult> _results = [];
  List<String> _allDnsServers = [];
  bool _isScanning = false;
  bool _isLoading = true;
  int _totalCount = 0;
  int _testedCount = 0;
  int _successCount = 0;
  int _firewallCount = 0;
  DnsResult? _bestResult;

  // Settings
  bool _filterFirewall = true;
  int _parallelWorkers = 10;
  int _selectedDomainIndex = 0;

  // Test domains
  final List<TestDomain> _testDomains = const [
    TestDomain(name: 'google.com', domain: 'google.com'),
    TestDomain(name: 'cloudflare.com', domain: 'cloudflare.com'),
    TestDomain(name: 'example.com', domain: 'example.com'),
  ];

  // Iranian firewall IPs
  static const Set<String> _firewallIps = {
    '10.10.34.34',
    '10.10.34.35',
    '10.10.34.36',
  };

  // DNS Ranges based on first octet groups
  final List<DnsRange> _dnsRanges = [
    DnsRange(name: 'رنج 2.x.x.x', prefix: '2.'),
    DnsRange(name: 'رنج 5.x.x.x', prefix: '5.'),
    DnsRange(name: 'رنج 31.x.x.x', prefix: '31.'),
    DnsRange(name: 'رنج 37.x.x.x', prefix: '37.'),
    DnsRange(name: 'رنج 46.x.x.x', prefix: '46.'),
    DnsRange(name: 'رنج 78.x.x.x', prefix: '78.'),
    DnsRange(name: 'رنج 79.x.x.x', prefix: '79.'),
    DnsRange(name: 'رنج 80.x.x.x', prefix: '80.'),
    DnsRange(name: 'رنج 85.x.x.x', prefix: '85.'),
    DnsRange(name: 'رنج 91.x.x.x', prefix: '91.'),
    DnsRange(name: 'رنج 94.x.x.x', prefix: '94.'),
    DnsRange(name: 'رنج 95.x.x.x', prefix: '95.'),
    DnsRange(name: 'رنج 109.x.x.x', prefix: '109.'),
    DnsRange(name: 'رنج 151.x.x.x', prefix: '151.'),
    DnsRange(name: 'رنج 176.x.x.x', prefix: '176.'),
    DnsRange(name: 'رنج 185.x.x.x', prefix: '185.'),
    DnsRange(name: 'رنج 188.x.x.x', prefix: '188.'),
    DnsRange(name: 'رنج 212.x.x.x', prefix: '212.'),
    DnsRange(name: 'رنج 217.x.x.x', prefix: '217.'),
    DnsRange(name: 'سایر', prefix: 'other'),
  ];

  @override
  void initState() {
    super.initState();
    _loadDnsServers();
  }

  Future<void> _loadDnsServers() async {
    try {
      final String fileContent = await rootBundle.loadString(
        'assets/dns_list.txt',
      );
      final List<String> allLines = const LineSplitter().convert(fileContent);

      _allDnsServers = [];
      for (var line in allLines) {
        final cleanIp = line.trim().split(':')[0];
        if (cleanIp.isNotEmpty && cleanIp.split('.').length == 4) {
          _allDnsServers.add(cleanIp);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _getFilteredServers() {
    final selectedPrefixes = _dnsRanges
        .where((r) => r.selected)
        .map((r) => r.prefix)
        .toList();

    if (selectedPrefixes.isEmpty) {
      return _allDnsServers;
    }

    return _allDnsServers.where((ip) {
      for (var prefix in selectedPrefixes) {
        if (prefix == 'other') continue;
        if (ip.startsWith(prefix)) return true;
      }

      // Check for "other" category
      if (selectedPrefixes.contains('other')) {
        bool matchesAny = false;
        for (var range in _dnsRanges) {
          if (range.prefix != 'other' && ip.startsWith(range.prefix)) {
            matchesAny = true;
            break;
          }
        }
        if (!matchesAny) return true;
      }

      return false;
    }).toList();
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.greyMedium,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'تنظیمات تست',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Test Domain Selection
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'دامنه تست:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: List.generate(_testDomains.length, (index) {
                            return ChoiceChip(
                              label: Text(_testDomains[index].name),
                              selected: _selectedDomainIndex == index,
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() {
                                    _selectedDomainIndex = index;
                                  });
                                  setState(() {});
                                }
                              },
                              selectedColor: AppColors.navy.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: _selectedDomainIndex == index
                                    ? AppColors.navy
                                    : Colors.grey,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Parallel Workers
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'تعداد تست موازی:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                            ),
                            Text(
                              '$_parallelWorkers',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _parallelWorkers.toDouble(),
                          min: 1,
                          max: 50,
                          divisions: 49,
                          activeColor: AppColors.navy,
                          onChanged: (value) {
                            setModalState(() {
                              _parallelWorkers = value.round();
                            });
                            setState(() {});
                          },
                        ),
                        const Text(
                          'مقدار بیشتر = سریع‌تر ولی ممکن است نتایج نادرست باشد',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Firewall Filter
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'فیلتر IP فایروال:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'حذف سرورهایی که 10.10.34.x برمی‌گردانند',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _filterFirewall,
                          activeColor: AppColors.navy,
                          onChanged: (value) {
                            setModalState(() {
                              _filterFirewall = value;
                            });
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('تایید'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRangeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.greyMedium,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'انتخاب رنج IP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _dnsRanges.map((range) {
                          return FilterChip(
                            label: Text(range.name),
                            selected: range.selected,
                            onSelected: (selected) {
                              setModalState(() {
                                range.selected = selected;
                              });
                              setState(() {});
                            },
                            selectedColor: AppColors.navy.withOpacity(0.2),
                            checkmarkColor: AppColors.navy,
                            labelStyle: TextStyle(
                              color: range.selected
                                  ? AppColors.navy
                                  : Colors.grey,
                              fontWeight: range.selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              for (var r in _dnsRanges) {
                                r.selected = true;
                              }
                            });
                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            side: const BorderSide(color: AppColors.navy),
                          ),
                          child: const Text('انتخاب همه'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              for (var r in _dnsRanges) {
                                r.selected = false;
                              }
                            });
                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            side: const BorderSide(color: AppColors.navy),
                          ),
                          child: const Text('حذف همه'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('تایید'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final filteredCount = _getFilteredServers().length;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'DNS Tester',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.navy,
        actions: [
          IconButton(
            onPressed: _isScanning ? null : _showSettingsSheet,
            icon: const Icon(Icons.settings),
            tooltip: 'تنظیمات',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            )
          : Column(
              children: [
                // Stats Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.greyLight,
                  child: Row(
                    children: [
                      _buildStatBox(
                        'کل سرورها',
                        _allDnsServers.length.toString(),
                      ),
                      const SizedBox(width: 8),
                      _buildStatBox('فیلتر شده', filteredCount.toString()),
                      const SizedBox(width: 8),
                      _buildStatBox('موفق', _successCount.toString()),
                      if (_firewallCount > 0) ...[
                        const SizedBox(width: 8),
                        _buildStatBox(
                          'فایروال',
                          _firewallCount.toString(),
                          isWarning: true,
                        ),
                      ],
                    ],
                  ),
                ),

                // Best DNS Card
                if (_bestResult != null && _bestResult!.latency != -1)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.star,
                            color: AppColors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'بهترین DNS',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _bestResult!.ip,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_bestResult!.latency} ms',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _bestResult!.ip),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('کپی شد!'),
                                duration: Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, color: AppColors.white),
                        ),
                      ],
                    ),
                  ),

                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _limitController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              enabled: !_isScanning,
                              decoration: InputDecoration(
                                labelText: 'تعداد',
                                labelStyle: const TextStyle(
                                  color: AppColors.navy,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.navy,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: OutlinedButton.icon(
                              onPressed: _isScanning
                                  ? null
                                  : _showRangeSelector,
                              icon: const Icon(Icons.filter_list),
                              label: const Text('انتخاب رنج'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.navy,
                                side: const BorderSide(color: AppColors.navy),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isScanning ? _stopScan : _startScan,
                          icon: _isScanning
                              ? const Icon(Icons.stop)
                              : const Icon(Icons.play_arrow),
                          label: Text(
                            _isScanning ? 'توقف' : 'شروع تست',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isScanning
                                ? AppColors.error
                                : AppColors.navy,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress
                if (_isScanning) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _totalCount > 0
                                ? _testedCount / _totalCount
                                : 0,
                            backgroundColor: AppColors.greyMedium,
                            color: AppColors.navy,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_testedCount / $_totalCount',
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Results List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return _buildResultItem(item);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatBox(String label, String value, {bool isWarning = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isWarning ? AppColors.warning : AppColors.greyMedium,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isWarning ? AppColors.warning : AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isWarning ? AppColors.warning : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(DnsResult item) {
    Color statusColor;
    IconData statusIcon;

    if (item.isTesting) {
      statusColor = AppColors.navy;
      statusIcon = Icons.sync;
    } else if (item.isFirewallBlocked) {
      statusColor = AppColors.warning;
      statusIcon = Icons.shield;
    } else if (item.latency != -1) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
    } else if (item.status == "در انتظار") {
      statusColor = Colors.grey;
      statusIcon = Icons.hourglass_empty;
    } else {
      statusColor = AppColors.error;
      statusIcon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyMedium),
      ),
      child: Row(
        children: [
          item.isTesting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: statusColor,
                  ),
                )
              : Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.ip,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navyDark,
                  ),
                ),
                if (item.isFirewallBlocked && item.firewallIp != null)
                  Text(
                    'فایروال: ${item.firewallIp}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            item.latency != -1 ? '${item.latency} ms' : item.status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (item.latency != -1 && !item.isFirewallBlocked) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: item.ip));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('کپی شد!'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.copy, size: 16, color: AppColors.navy),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _shouldStop = false;

  void _stopScan() {
    _shouldStop = true;
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _startScan() async {
    FocusScope.of(context).unfocus();
    _shouldStop = false;

    setState(() {
      _isScanning = true;
      _results = [];
      _testedCount = 0;
      _successCount = 0;
      _firewallCount = 0;
      _totalCount = 0;
      _bestResult = null;
    });

    try {
      final filteredServers = _getFilteredServers();

      int limit = int.tryParse(_limitController.text) ?? 50;
      if (limit <= 0) limit = 50;
      if (limit > filteredServers.length) limit = filteredServers.length;

      // Shuffle and take limit
      final shuffled = List<String>.from(filteredServers)..shuffle(Random());
      final selected = shuffled.take(limit).toList();

      final List<DnsResult> initialList = selected
          .map((ip) => DnsResult(ip: ip))
          .toList();

      setState(() {
        _results = initialList;
        _totalCount = initialList.length;
      });

      final testDomain = _testDomains[_selectedDomainIndex].domain;

      // Process in parallel batches
      for (
        int i = 0;
        i < _results.length && !_shouldStop;
        i += _parallelWorkers
      ) {
        final batch = _results.skip(i).take(_parallelWorkers).toList();

        // Mark batch as testing
        for (var item in batch) {
          if (mounted) {
            setState(() {
              item.isTesting = true;
              item.status = "در حال تست...";
            });
          }
        }

        // Test batch in parallel
        await Future.wait(
          batch.map((item) async {
            if (_shouldStop) return;

            try {
              final result = await DnsTester.measureLatency(
                item.ip,
                testDomain,
                _firewallIps,
              );

              if (mounted && !_shouldStop) {
                setState(() {
                  item.latency = result.latency;
                  item.isFirewallBlocked = result.isFirewallBlocked;
                  item.firewallIp = result.firewallIp;
                  item.isTesting = false;
                  _testedCount++;

                  if (result.isFirewallBlocked) {
                    _firewallCount++;
                    if (_filterFirewall) {
                      item.status = "فایروال";
                    } else {
                      _successCount++;
                      if (_bestResult == null ||
                          result.latency < _bestResult!.latency) {
                        _bestResult = item;
                      }
                    }
                  } else if (result.latency != -1) {
                    item.status = "موفق";
                    _successCount++;
                    if (_bestResult == null ||
                        result.latency < _bestResult!.latency) {
                      _bestResult = item;
                    }
                  } else {
                    item.status = "ناموفق";
                  }

                  // Sort results
                  _sortResults();
                });
              }
            } catch (e) {
              if (mounted && !_shouldStop) {
                setState(() {
                  item.latency = -1;
                  item.status = "خطا";
                  item.isTesting = false;
                  _testedCount++;
                });
              }
            }
          }),
        );

        // Small delay between batches
        if (!_shouldStop) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("خطا: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  void _sortResults() {
    _results.sort((a, b) {
      // Testing items first
      if (a.isTesting && !b.isTesting) return -1;
      if (!a.isTesting && b.isTesting) return 1;

      // Successful non-firewall items next
      bool aSuccess = a.latency != -1 && !a.isFirewallBlocked;
      bool bSuccess = b.latency != -1 && !b.isFirewallBlocked;
      if (aSuccess && !bSuccess) return -1;
      if (!aSuccess && bSuccess) return 1;

      // Sort by latency if both successful
      if (aSuccess && bSuccess) {
        return a.latency.compareTo(b.latency);
      }

      // Firewall items before failed
      if (a.isFirewallBlocked && !b.isFirewallBlocked) return -1;
      if (!a.isFirewallBlocked && b.isFirewallBlocked) return 1;

      return 0;
    });
  }
}

class DnsTestResult {
  final int latency;
  final bool isFirewallBlocked;
  final String? firewallIp;

  DnsTestResult({
    required this.latency,
    this.isFirewallBlocked = false,
    this.firewallIp,
  });
}

class DnsTester {
  static Future<DnsTestResult> measureLatency(
    String serverIp,
    String domain,
    Set<String> firewallIps,
  ) async {
    RawDatagramSocket? socket;
    try {
      final serverAddress = InternetAddress(serverIp);

      // Create socket with timeout
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      ).timeout(const Duration(seconds: 3));

      final int id = Random().nextInt(65535);
      final List<int> packet = _buildDnsQuery(id, domain);

      final stopwatch = Stopwatch()..start();

      // Send packet
      final sent = socket.send(packet, serverAddress, 53);
      if (sent <= 0) {
        return DnsTestResult(latency: -1);
      }

      // Wait for response
      final Completer<DnsTestResult> completer = Completer();

      late StreamSubscription sub;
      sub = socket.listen(
        (event) {
          if (event == RawSocketEvent.read) {
            final datagram = socket!.receive();
            if (datagram != null && datagram.data.length > 12) {
              // Check transaction ID matches
              if (datagram.data[0] == ((id >> 8) & 0xFF) &&
                  datagram.data[1] == (id & 0xFF)) {
                stopwatch.stop();

                // Parse response to check for firewall IPs
                final returnedIps = _parseResponseIps(datagram.data);
                String? foundFirewallIp;

                for (var ip in returnedIps) {
                  if (firewallIps.contains(ip)) {
                    foundFirewallIp = ip;
                    break;
                  }
                }

                if (!completer.isCompleted) {
                  completer.complete(
                    DnsTestResult(
                      latency: stopwatch.elapsedMilliseconds,
                      isFirewallBlocked: foundFirewallIp != null,
                      firewallIp: foundFirewallIp,
                    ),
                  );
                }
              }
            }
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            completer.complete(DnsTestResult(latency: -1));
          }
        },
        cancelOnError: false,
      );

      // Timeout after 2.5 seconds
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!completer.isCompleted) {
          completer.complete(DnsTestResult(latency: -1));
        }
      });

      final result = await completer.future;
      await sub.cancel();
      return result;
    } catch (e) {
      return DnsTestResult(latency: -1);
    } finally {
      socket?.close();
    }
  }

  static List<String> _parseResponseIps(List<int> data) {
    List<String> ips = [];
    try {
      // Skip header (12 bytes) and question section
      int pos = 12;

      // Skip question section
      while (pos < data.length && data[pos] != 0) {
        pos += data[pos] + 1;
      }
      pos += 5; // Skip null terminator + QTYPE (2) + QCLASS (2)

      // Parse answer section
      final answerCount = (data[6] << 8) | data[7];

      for (int i = 0; i < answerCount && pos < data.length - 10; i++) {
        // Skip name (pointer or label)
        if ((data[pos] & 0xC0) == 0xC0) {
          pos += 2; // Pointer
        } else {
          while (pos < data.length && data[pos] != 0) {
            pos += data[pos] + 1;
          }
          pos++;
        }

        if (pos + 10 > data.length) break;

        final type = (data[pos] << 8) | data[pos + 1];
        final rdLength = (data[pos + 8] << 8) | data[pos + 9];
        pos += 10;

        if (type == 1 && rdLength == 4 && pos + 4 <= data.length) {
          // A record - IPv4
          final ip =
              '${data[pos]}.${data[pos + 1]}.${data[pos + 2]}.${data[pos + 3]}';
          ips.add(ip);
        }

        pos += rdLength;
      }
    } catch (e) {
      // Parsing error, return what we have
    }
    return ips;
  }

  static List<int> _buildDnsQuery(int id, String domain) {
    // DNS Header (12 bytes)
    List<int> header = [
      (id >> 8) & 0xFF, // Transaction ID (high byte)
      id & 0xFF, // Transaction ID (low byte)
      0x01, // Flags: Standard query
      0x00, // Flags: Recursion desired
      0x00, // QDCOUNT (high byte)
      0x01, // QDCOUNT (low byte) - 1 question
      0x00, // ANCOUNT (high byte)
      0x00, // ANCOUNT (low byte)
      0x00, // NSCOUNT (high byte)
      0x00, // NSCOUNT (low byte)
      0x00, // ARCOUNT (high byte)
      0x00, // ARCOUNT (low byte)
    ];

    // Question section: domain name
    List<int> qname = [];
    for (var part in domain.split('.')) {
      qname.add(part.length);
      qname.addAll(part.codeUnits);
    }
    qname.add(0); // Null terminator

    // QTYPE (A = 1) and QCLASS (IN = 1)
    List<int> footer = [0x00, 0x01, 0x00, 0x01];

    return [...header, ...qname, ...footer];
  }
}

class GuidePageContent extends StatelessWidget {
  const GuidePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'راهنما',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.navy,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGuideStep(
            '۱',
            'دانلود HTTP Injector',
            'اپلیکیشن HTTP Injector برای اندروید یا آیفون دانلود کنید',
          ),
          _buildGuideStep(
            '۲',
            'دانلود فایل کانفیگ',
            'فایل کانفیگ نمونه را از اینجا (example.ehi) دانلود کنید',
          ),
          _buildGuideStep(
            '۳',
            'ایمپورت کانفیگ',
            'فایل کانفیگ رو در اپ ایمپورت کنید',
          ),
          _buildGuideStep(
            '۴',
            'تنظیم پسورد SSH',
            'بروید به تنظیمات اپ:\nSettings > Secure Shell (SSH) > Password\n\nپسوردی که برای یوزر dnstt روی سرور ساختید رو اینجا وارد کنید',
          ),
          _buildGuideStep(
            '۵',
            'تنظیمات DNSTT',
            'بروید به:\nSettings > DNSTT (DNS)',
          ),
          _buildGuideStep(
            '۶',
            'وارد کردن دامنه',
            'نام دامنه خود را در این قسمت وارد کنید:\nDNSTT Nameserver',
          ),
          _buildGuideStep(
            '۷',
            'وارد کردن کلید عمومی',
            'کلید عمومی که بعد از اجرای اسکریپت دریافت کردید را اینجا وارد کنید:\nDNSTT Public Key',
          ),
          _buildGuideStep(
            '۸',
            'وارد کردن DNS Resolver',
            'یک سرور DNS ایرانی را در قسمت DNS Resolver Address وارد کنید.\n\nمی‌توانید تمام DNS های ایرانی را با این برنامه تست کنید و بهترین را انتخاب کنید!',
            isHighlighted: true,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greyMedium),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 نکات مهم:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '• DNS هایی که IP فایروال (10.10.34.x) برمی‌گردانند قابل استفاده نیستند.',
                  style: TextStyle(height: 1.8),
                ),
                Text(
                  '• سرورهای با پینگ زیر 100ms بهترین هستند.',
                  style: TextStyle(height: 1.8),
                ),
                Text(
                  '• هر بار که اینترنت قطع شد، DNS جدید تست کنید.',
                  style: TextStyle(height: 1.8),
                ),
                Text(
                  '• از رنج‌های مختلف IP تست کنید تا بهترین را پیدا کنید.',
                  style: TextStyle(height: 1.8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildGuideStep(
    String number,
    String title,
    String description, {
    bool isHighlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.navy.withOpacity(0.05)
            : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? AppColors.navy : AppColors.greyMedium,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black87, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
