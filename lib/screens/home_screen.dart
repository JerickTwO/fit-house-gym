import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';
import '../models/client_status.dart';
import '../models/client_summary.dart';
import '../models/subscription.dart';
import '../theme/app_theme.dart';
import '../utils/whatsapp_helper.dart';
import '../widgets/add_client_sheet.dart';
import '../widgets/client_card.dart';
import '../widgets/renew_sheet.dart';
import '../widgets/summary_header.dart';
import 'client_detail_screen.dart';
import 'payments_history_screen.dart';
import 'settings_screen.dart';

enum _QuickFilter { todos, activos, porVencer, vencidos }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ClientSummary> _allClients = [];
  Map<String, double> _todayTotals = {};
  bool _loading = true;
  String _searchQuery = '';
  _QuickFilter _filter = _QuickFilter.todos;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// "Lunes, 23 nov" en español, sin punto final en el mes abreviado.
  String _headerDate() {
    final now = DateTime.now();
    final weekday = DateFormat('EEEE', 'es').format(now);
    final dayMonth = DateFormat('d MMM', 'es').format(now).replaceAll('.', '');
    final capitalizedWeekday = weekday.isEmpty
        ? weekday
        : weekday[0].toUpperCase() + weekday.substring(1);
    return '$capitalizedWeekday, $dayMonth';
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final clients = await DBHelper.instance.getClientSummaries();
    final totals = await DBHelper.instance.getTodayTotals();
    if (!mounted) return;
    // Ordenados por vencimiento: primero lo más vencido/próximo a vencer;
    // quien nunca tuvo un plan queda al final.
    clients.sort((a, b) {
      final endA = a.latestSubscription?.endDate;
      final endB = b.latestSubscription?.endDate;
      if (endA == null && endB == null) return 0;
      if (endA == null) return 1;
      if (endB == null) return -1;
      return endA.compareTo(endB);
    });
    setState(() {
      _allClients = clients;
      _todayTotals = totals;
      _loading = false;
    });
  }

  List<ClientSummary> get _visibleClients {
    var list = _allClients;

    if (_filter == _QuickFilter.activos) {
      list = list.where((c) => c.status == ClientStatus.activo).toList();
    } else if (_filter == _QuickFilter.porVencer) {
      list = list.where((c) => c.status == ClientStatus.porVencer).toList();
    } else if (_filter == _QuickFilter.vencidos) {
      list = list.where((c) => c.status == ClientStatus.vencido).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      list = list
          .where((c) => c.client.name.toLowerCase().contains(query))
          .toList();
    }
    return list;
  }

  Future<void> _onRenovar(ClientSummary summary) async {
    final result = await showRenewSheet(context, summary);
    if (result == true) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Renovación registrada para ${summary.client.name}')),
      );
    }
  }

  Future<void> _onWhatsApp(ClientSummary summary) async {
    final endDate = summary.latestSubscription?.endDate;
    if (endDate == null) return;
    final opened = await openWhatsAppReminder(
      client: summary.client,
      endDate: endDate,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  Future<void> _onAddClient() async {
    final result = await showAddClientSheet(context);
    if (result == true) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente registrado y cobrado')),
      );
    }
  }

  Future<void> _onOpenDetail(ClientSummary summary) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClientDetailScreen(client: summary.client),
      ),
    );
    if (result == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activos =
        _allClients.where((c) => c.status == ClientStatus.activo).length;
    final porVencer =
        _allClients.where((c) => c.status == ClientStatus.porVencer).length;
    final vencidos =
        _allClients.where((c) => c.status == ClientStatus.vencido).length;
    final visible = _visibleClients;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _headerDate(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Fit House Gym',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.card,
              shape: const CircleBorder(),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PaymentsHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.card,
                shape: const CircleBorder(),
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                _loadData();
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: SummaryHeader(
                        totalEfectivo:
                            _todayTotals[PaymentMethod.efectivo.label] ?? 0,
                        totalTransferencia:
                            _todayTotals[PaymentMethod.transferencia.label] ??
                                0,
                        activos: activos,
                        porVencer: porVencer,
                        vencidos: vencidos,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Buscar cliente',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterChip(
                              label: 'Todos ${_allClients.length}',
                              selected: _filter == _QuickFilter.todos,
                              onTap: () =>
                                  setState(() => _filter = _QuickFilter.todos),
                            ),
                            const SizedBox(width: 6),
                            _FilterChip(
                              label: 'Activos',
                              selected: _filter == _QuickFilter.activos,
                              onTap: () => setState(
                                () => _filter = _QuickFilter.activos,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _FilterChip(
                              label: 'Por vencer',
                              selected: _filter == _QuickFilter.porVencer,
                              onTap: () => setState(
                                () => _filter = _QuickFilter.porVencer,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _FilterChip(
                              label: 'Vencidos',
                              selected: _filter == _QuickFilter.vencidos,
                              onTap: () => setState(
                                () => _filter = _QuickFilter.vencidos,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        '${visible.length} ${visible.length == 1 ? 'cliente' : 'clientes'} · ordenados por vencimiento',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (visible.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(hasClients: _allClients.isNotEmpty),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList.separated(
                        itemCount: visible.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final summary = visible[index];
                          return ClientCard(
                            summary: summary,
                            onTap: () => _onOpenDetail(summary),
                            onRenovar: () => _onRenovar(summary),
                            onWhatsApp: () => _onWhatsApp(summary),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddClient,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo cliente'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.background : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasClients;

  const _EmptyState({required this.hasClients});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasClients ? Icons.search_off : Icons.fitness_center,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              hasClients
                  ? 'No hay clientes con ese filtro'
                  : 'Todavía no hay clientes.\nToca "Nuevo cliente" para empezar.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
