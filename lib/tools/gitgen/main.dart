import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'models.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _warning = Color(0xFFFFC24B);
const Color _success = Color(0xFF4BD68B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class GitGen extends StatefulWidget {
  const GitGen({super.key});

  @override
  State<GitGen> createState() => _GitGenState();
}

class _GitGenState extends State<GitGen> {
  final TextEditingController _searchCtrl = TextEditingController();
  GitCategory? _category;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<GitScenario> get _filtered {
    return kGitScenarios.where((GitScenario s) {
      if (_category != null && s.category != _category) return false;
      if (_query.isEmpty) return true;

      final String title = context.t(s.titleKey).toLowerCase();
      final String desc = context.t(s.descriptionKey).toLowerCase();
      final String command = s.command.toLowerCase();
      final String id = s.id.toLowerCase();

      return title.contains(_query) ||
          desc.contains(_query) ||
          command.contains(_query) ||
          id.contains(_query);
    }).toList();
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showSnack(context.t('gitgen_copied'));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.75),
        content: Text(message),
      ),
    );
  }

  Color _dangerColor(GitDanger d) {
    switch (d) {
      case GitDanger.safe:
        return _success;
      case GitDanger.warning:
        return _warning;
      case GitDanger.danger:
        return _danger;
    }
  }

  IconData _dangerIcon(GitDanger d) {
    switch (d) {
      case GitDanger.safe:
        return Icons.check_circle_rounded;
      case GitDanger.warning:
        return Icons.warning_amber_rounded;
      case GitDanger.danger:
        return Icons.dangerous_rounded;
    }
  }

  IconData _categoryIcon(GitCategory c) {
    switch (c) {
      case GitCategory.undo:
        return Icons.undo_rounded;
      case GitCategory.branch:
        return Icons.account_tree_rounded;
      case GitCategory.remote:
        return Icons.cloud_outlined;
      case GitCategory.stash:
        return Icons.inventory_2_outlined;
      case GitCategory.advanced:
        return Icons.build_rounded;
      case GitCategory.inspect:
        return Icons.search_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<GitScenario> scenarios = _filtered;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('gitgen_title')),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_bgTop, _bgMid, _bgBot],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(top: -80, left: -60, child: _blurBlob(220, _accentA)),
            Positioned(
              bottom: -100,
              right: -60,
              child: _blurBlob(260, _accentB),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  _searchBar(),
                  _categoryBar(),
                  const SizedBox(height: 4),
                  Expanded(
                    child: scenarios.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        24,
                      ),
                      itemCount: scenarios.length,
                      itemBuilder: (BuildContext context, int i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _scenarioCard(scenarios[i]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 72, 16, 8),
      child: _GlassCard(
        padding: EdgeInsets.zero,
        radius: 14,
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: context.t('gitgen_search_hint'),
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 18,
              color: Colors.white54,
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
              onPressed: () => _searchCtrl.clear(),
              icon: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.white54,
              ),
              splashRadius: 14,
            ),
            isDense: true,
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: _accentB, width: 1.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryBar() {
    final List<Widget> chips = <Widget>[];

    chips.add(
      _categoryChip(
        label: context.t('gitgen_cat_all'),
        icon: Icons.apps_rounded,
        selected: _category == null,
        onTap: () => setState(() => _category = null),
      ),
    );

    for (final GitCategory c in GitCategory.values) {
      chips.add(
        _categoryChip(
          label: context.t(c.labelKey),
          icon: _categoryIcon(c),
          selected: _category == c,
          onTap: () => setState(() => _category = c),
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int i) => chips[i],
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
            colors: <Color>[_accentA, _accentB],
          )
              : null,
          color: selected ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scenarioCard(GitScenario s) {
    final Color dc = _dangerColor(s.danger);

    return _GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: dc.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: dc.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(_dangerIcon(s.danger), size: 11, color: dc),
                    const SizedBox(width: 4),
                    Text(
                      context.t(s.danger.labelKey),
                      style: TextStyle(
                        color: dc,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _accentA.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _accentA.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      _categoryIcon(s.category),
                      size: 11,
                      color: _accentB,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.t(s.category.labelKey),
                      style: const TextStyle(
                        color: _accentB,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.t(s.titleKey),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.t(s.descriptionKey),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _commandBlock(s.command),
          if (s.warningKey != null) ...<Widget>[
            const SizedBox(height: 10),
            _warningBox(s.warningKey!),
          ],
          const SizedBox(height: 10),
          _explanationBox(s.explanationKey),
          if (s.alternatives.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _alternativesBox(s.alternatives),
          ],
        ],
      ),
    );
  }

  Widget _commandBlock(String command) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentB.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.terminal_rounded,
              size: 14,
              color: _accentB,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              command,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.55,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _copy(command),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.copy_rounded,
                size: 16,
                color: _accentB,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningBox(String warningKey) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _warning.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: _warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.t(warningKey),
              style: const TextStyle(
                color: Color(0xFFFFE1A8),
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _explanationBox(String explanationKey) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: Colors.white54,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.t(explanationKey),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alternativesBox(List<String> alternatives) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _accentA.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentA.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.alt_route_rounded,
                size: 13,
                color: _accentB,
              ),
              const SizedBox(width: 6),
              Text(
                context.t('gitgen_alternatives'),
                style: const TextStyle(
                  color: _accentB,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final String alt in alternatives) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.circle,
                      size: 4,
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      alt,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.25),
            ),
            const SizedBox(height: 12),
            Text(
              context.t('gitgen_no_results'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blurBlob(double size, Color color) {
    return IgnorePointer(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}