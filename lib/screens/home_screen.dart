import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trialerror/screens/add_expense_screen.dart';
import 'package:trialerror/screens/add_person_screen.dart';
import 'package:trialerror/screens/groups_screen.dart';
import 'package:trialerror/screens/user_transactions_screen.dart';  // Import your user transactions screen

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  String? _selectedUserId;
  bool _isLoading = false;

  // Fetch all users from Supabase
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await supabase.from('users').select('*');
      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch expenses with group and payer information
  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    try {
      final response = await supabase
          .from('expenses')
          .select(''' 
            *,
            groups (name),
            users!expenses_payer_id_fkey (name)
          ''')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('Error fetching expenses: $error');
      return []; // Return an empty list in case of error
    }
  }

  // Delete an expense
  Future<void> _deleteExpense(String expenseId) async {
    try {
      await supabase.from('expenses').delete().eq('id', expenseId);
    } catch (error) {
      throw 'Error deleting expense: $error';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FairShareApp'),
        actions: [
          // Dropdown to select the current user
          DropdownButton<String>(
            value: _selectedUserId,
            hint: Text('Select User'),
            onChanged: (value) {
              setState(() {
                _selectedUserId = value;
              });
            },
            items: _users.map((user) {
              return DropdownMenuItem<String>(
                value: user['id'],
                child: Text(user['name']),
              );
            }).toList(),
          ),
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddPersonScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.group),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GroupsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_selectedUserId != null)
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchExpenses(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text('No expenses found.'));
                        } else {
                          final expenses = snapshot.data!;
                          return ListView.builder(
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              final expense = expenses[index];
                              final group = expense['groups'];
                              final payer = expense['users'];
                              return ListTile(
                                title: Text(expense['description']),
                                subtitle: Text(
                                    'Amount: \$${expense['amount']}, Group: ${group['name']}, Paid by: ${payer['name']}'),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () async {
                                    try {
                                      await _deleteExpense(expense['id']);
                                      setState(() {}); // Refresh the list
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Expense deleted')));
                                    } catch (error) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $error')));
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                if (_selectedUserId == null)
                  Center(
                    child: Text('Please select a user to view expenses.'),
                  ),
              ],
            ),
      // Floating Action Buttons at the bottom
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_selectedUserId != null)
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddExpenseScreen()),
                );
              },
              child: Icon(Icons.add),
            ),
          SizedBox(height: 16), // Space between buttons
          if (_selectedUserId != null)
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserTransactionsScreen(userId: _selectedUserId!)),
                );
              },
              child: Icon(Icons.history),
            ),
        ],
      ),
    );
  }
}