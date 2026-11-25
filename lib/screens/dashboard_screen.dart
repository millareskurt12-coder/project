import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_card.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.user,
    required this.onLogout,
    this.database,
  });

  final UserModel user;
  final Future<void> Function() onLogout;
  final DatabaseHelper? database;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final _overviewKey = GlobalKey<_OverviewScreenState>();

  @override
  Widget build(BuildContext context) {
    final database = widget.database ?? DatabaseHelper.instance;
    final pages = [
      _OverviewScreen(key: _overviewKey, user: widget.user, database: database),
      TransactionsScreen(userId: widget.user.id, database: database),
      ReportsScreen(userId: widget.user.id, database: database),
      SettingsScreen(user: widget.user, onLogout: widget.onLogout),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index == 0) _overviewKey.currentState?.reload();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _OverviewScreen extends StatefulWidget {
  const _OverviewScreen({
    super.key,
    required this.user,
    required this.database,
  });

  final UserModel user;
  final DatabaseHelper database;

  @override
  State<_OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<_OverviewScreen> {
  late Future<
    ({List<TransactionModel> transactions, double income, double expenses})
  >
  _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  Future<
    ({List<TransactionModel> transactions, double income, double expenses})
  >
  _loadData() async {
    final transactions = await widget.database.getTransactions(widget.user.id);
    final income = transactions
        .where((transaction) => transaction.type == 'Income')
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    final expenses = transactions
        .where((transaction) => transaction.type == 'Expense')
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    return (transactions: transactions, income: income, expenses: expenses);
  }

  void reload() {
    setState(() => _loadFuture = _loadData());
  }

  Future<void> _refresh() async {
    reload();
    await _loadFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body:
          FutureBuilder<
            ({
              List<TransactionModel> transactions,
              double income,
              double expenses,
            })
          >(
            future: _loadFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Could not load overview: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;
              final transactions = data.transactions;
              final income = data.income;
              final expenses = data.expenses;
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  children: [
                    Text(
                      'Hello, ${widget.user.fullName.split(' ').first}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text('Here is your money at a glance.'),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101D2D),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Net balance',
                            style: TextStyle(color: Color(0xFFC1CED8)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '\$${(income - expenses).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SummaryCard(
                            label: 'Total income',
                            amount: '\$${income.toStringAsFixed(2)}',
                            icon: Icons.south_west_rounded,
                            color: const Color(0xFF138A5B),
                          ),
                          const SizedBox(width: 12),
                          SummaryCard(
                            label: 'Total spending',
                            amount: '\$${expenses.toStringAsFixed(2)}',
                            icon: Icons.north_east_rounded,
                            color: const Color(0xFFCA5B48),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent activity',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () {
                            final dashboard = context
                                .findAncestorStateOfType<
                                  _DashboardScreenState
                                >();
                            dashboard?.setState(
                              () => dashboard._selectedIndex = 1,
                            );
                          },
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    if (transactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 22),
                        child: Center(
                          child: Text(
                            'No activity yet. Add your first transaction.',
                          ),
                        ),
                      )
                    else
                      ...transactions
                          .take(5)
                          .map(
                            (transaction) =>
                                TransactionCard(transaction: transaction),
                          ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
