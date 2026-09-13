import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class TsConv extends StatefulWidget {
  const TsConv({super.key});

  @override
  State<TsConv> createState() => _TsConvState();
}

class _TsConvState extends State<TsConv>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _tsController = TextEditingController();
  final TextEditingController _localResultController = TextEditingController();
  final TextEditingController _utcResultController = TextEditingController();
  bool _isMillis = false;
  String? _errorKey;

  DateTime _pickedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tsController.dispose();
    _localResultController.dispose();
    _utcResultController.dispose();
    super.dispose();
  }

  void _convertToDate() {
    final String input = _tsController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorKey = 'tsconv_error_empty';
        _localResultController.text = '';
        _utcResultController.text = '';
      });
      return;
    }
    final int? value = int.tryParse(input);
    if (value == null) {
      setState(() {
        _errorKey = 'tsconv_error_invalid';
        _localResultController.text = '';
        _utcResultController.text = '';
      });
      return;
    }
    try {
      final DateTime dt = _isMillis
          ? DateTime.fromMillisecondsSinceEpoch(value)
          : DateTime.fromMillisecondsSinceEpoch(value * 1000);
      final String local = _formatLocal(dt.toLocal());
      final String utc = _formatUtc(dt.toUtc());
      setState(() {
        _localResultController.text = local;
        _utcResultController.text = utc;
        _errorKey = null;
      });
    } catch (_) {
      setState(() {
        _errorKey = 'tsconv_error_invalid';
        _localResultController.text = '';
        _utcResultController.text = '';
      });
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatLocal(DateTime dt) {
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} '
        '${_two(dt.hour)}:${_two(dt.minute)}:${_two(dt.second)}';
  }

  String _formatUtc(DateTime dt) {
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} '
        '${_two(dt.hour)}:${_two(dt.minute)}:${_two(dt.second)} UTC';
  }

  void _useNow() {
    final DateTime now = _tabController.index == 0
        ? DateTime.now()
        : _pickedDateTime;
    if (_tabController.index == 0) {
      final int ts = _isMillis
          ? now.millisecondsSinceEpoch
          : now.millisecondsSinceEpoch ~/ 1000;
      setState(() {
        _tsController.text = ts.toString();
      });
      _convertToDate();
    } else {
      setState(() {
        _pickedDateTime = now;
      });
      _convertFromDate();
    }
  }

  Future<void> _pickDate() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _pickedDateTime,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      _pickedDateTime = DateTime(
        d.year,
        d.month,
        d.day,
        _pickedDateTime.hour,
        _pickedDateTime.minute,
        _pickedDateTime.second,
      );
    });
    _convertFromDate();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_pickedDateTime),
    );
    if (t == null) return;
    setState(() {
      _pickedDateTime = DateTime(
        _pickedDateTime.year,
        _pickedDateTime.month,
        _pickedDateTime.day,
        t.hour,
        t.minute,
      );
    });
    _convertFromDate();
  }

  void _convertFromDate() {
    final int ts = _isMillis
        ? _pickedDateTime.millisecondsSinceEpoch
        : _pickedDateTime.millisecondsSinceEpoch ~/ 1000;
    setState(() {
      _tsController.text = ts.toString();
    });
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('tsconv_copied'))),
    );
  }

  Widget _buildUnixToDate() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _tsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.t('tsconv_ts_hint'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _useNow,
                icon: const Icon(Icons.access_time),
                tooltip: context.t('tsconv_now'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: <ButtonSegment<bool>>[
              ButtonSegment<bool>(
                value: false,
                label: Text(context.t('tsconv_seconds')),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text(context.t('tsconv_millis')),
              ),
            ],
            selected: <bool>{_isMillis},
            onSelectionChanged: (Set<bool> s) {
              setState(() {
                _isMillis = s.first;
              });
              if (_tsController.text.trim().isNotEmpty) {
                _convertToDate();
              }
            },
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _convertToDate,
            child: Text(context.t('tsconv_convert')),
          ),
          const SizedBox(height: 16),
          if (_errorKey != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                context.t(_errorKey!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          TextField(
            controller: _localResultController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: context.t('tsconv_local'),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () => _copy(_localResultController.text),
                icon: const Icon(Icons.copy),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _utcResultController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: context.t('tsconv_utc'),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () => _copy(_utcResultController.text),
                icon: const Icon(Icons.copy),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateToUnix() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _formatLocal(_pickedDateTime),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(context.t('tsconv_pick_date')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule),
                          label: Text(context.t('tsconv_pick_time')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _useNow,
                      icon: const Icon(Icons.access_time),
                      label: Text(context.t('tsconv_now')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: <ButtonSegment<bool>>[
              ButtonSegment<bool>(
                value: false,
                label: Text(context.t('tsconv_seconds')),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text(context.t('tsconv_millis')),
              ),
            ],
            selected: <bool>{_isMillis},
            onSelectionChanged: (Set<bool> s) {
              setState(() {
                _isMillis = s.first;
              });
              _convertFromDate();
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tsController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: context.t('tsconv_result'),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () => _copy(_tsController.text),
                icon: const Icon(Icons.copy),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('tsconv_title')),
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: context.t('tsconv_tab_to_date')),
            Tab(text: context.t('tsconv_tab_to_ts')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildUnixToDate(),
          _buildDateToUnix(),
        ],
      ),
    );
  }
}