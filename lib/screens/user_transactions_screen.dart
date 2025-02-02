import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserTransactionsScreen extends StatefulWidget {
  final String userId;

  UserTransactionsScreen({required this.userId});

  @override
  _UserTransactionsScreenState createState() => _UserTransactionsScreenState();
}

class _UserTransactionsScreenState extends State<UserTransactionsScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<Map<String, dynamic>> _transactions = [];

  // Fetch transactions for the user
  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch groups the user is part of
      final groupsResponse = await supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', widget.userId);

      final groupIds = groupsResponse.map((group) => group['group_id']).toList();

      if (groupIds.isEmpty) {
        setState(() {
          _transactions = [];
        });
        return;
      }

      // Fetch expenses for those groups
      final expensesResponse = await supabase
          .from('expenses')
          .select('''
            *,
            groups (name),
            users!expenses_payer_id_fkey (name)
          ''')
          .inFilter('group_id', groupIds)
          .order('created_at', ascending: false);

      final expenses = List<Map<String, dynamic>>.from(expensesResponse);

      // Calculate transactions
      final transactions = await _calculateTransactions(expenses, widget.userId);

      setState(() {
        _transactions = transactions;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching transactions: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Calculate transactions for the user
  Future<List<Map<String, dynamic>>> _calculateTransactions(
      List<Map<String, dynamic>> expenses, String userId) async {
    final List<Map<String, dynamic>> transactions = [];

    for (final expense in expenses) {
      final group = expense['groups'];
      final payer = expense['users'];
      final amount = expense['amount'];
      final groupId = expense['group_id'];
      final payerId = expense['payer_id'];

      // Fetch group members
      final groupMembersResponse = await supabase
          .from('group_members')
          .select('users (id, name)')
          .eq('group_id', groupId);

      final groupMembers = List<Map<String, dynamic>>.from(groupMembersResponse);

      // Split amount equally
      final splitAmount = amount / groupMembers.length;

      if (payerId == userId) {
        // User is the payer
        for (final member in groupMembers) {
          final memberId = member['users']['id'];
          if (memberId != userId) {
            transactions.add({
              'type': 'owed',
              'amount': splitAmount,
              'to': member['users']['name'],
              'expense': expense['description'],
              'group': group['name'],
            });
          }
        }
      } else {
        // User is not the payer
        transactions.add({
          'type': 'owe',
          'amount': splitAmount,
          'to': payer['name'],
          'expense': expense['description'],
          'group': group['name'],
        });
      }
    }

    return transactions;
  }

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Transactions'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? Center(child: Text('No transactions found.'))
              : ListView.builder(
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _transactions[index];
                    return ListTile(
                      title: Text(transaction['expense']),
                      subtitle: Text(
                          'Group: ${transaction['group']}, ${transaction['type'] == 'owed' ? '${transaction['to']} owes you' : 'You owe ${transaction['to']}'}'),
                      trailing: Text(
                          '\$${transaction['amount'].toStringAsFixed(2)}'),
                    );
                  },
                ),
    );
  }
}