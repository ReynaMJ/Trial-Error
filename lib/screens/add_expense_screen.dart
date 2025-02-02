import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddExpenseScreen extends StatefulWidget {
  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<Map<String, dynamic>> _groups = [];
  String? _selectedGroupId;
  List<Map<String, dynamic>> _groupMembers = [];
  String? _selectedPayerId;

  // Fetch all groups from Supabase
  Future<void> _fetchGroups() async {
    try {
      final response = await supabase.from('groups').select('*');
      setState(() {
        _groups = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching groups: $error')),
      );
    }
  }

  // Fetch members of the selected group
  Future<void> _fetchGroupMembers(String groupId) async {
    try {
      final response = await supabase
          .from('group_members')
          .select('users (id, name)')
          .eq('group_id', groupId);

      setState(() {
        _groupMembers = List<Map<String, dynamic>>.from(response);
        _selectedPayerId = null; // Reset the selected payer
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching group members: $error')),
      );
    }
  }

  // Add a new expense
  Future<void> _addExpense() async {
    if (_formKey.currentState!.validate() &&
        _selectedGroupId != null &&
        _selectedPayerId != null) {
      setState(() {
        _isLoading = true;
      });

      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;

      try {
        // Insert the expense into the expenses table
        await supabase.from('expenses').insert({
          'amount': amount,
          'description': description,
          'group_id': _selectedGroupId,
          'payer_id': _selectedPayerId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense added successfully')),
        );
        Navigator.pop(context); // Go back to the previous screen
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding expense: $error')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Expense'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedGroupId,
                onChanged: (value) {
                  setState(() {
                    _selectedGroupId = value;
                  });
                  _fetchGroupMembers(value!); // Fetch members of the selected group
                },
                items: _groups.map((group) {
                  return DropdownMenuItem<String>(
                    value: group['id'],
                    child: Text(group['name']),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Select Group'),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a group';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedPayerId,
                onChanged: (value) {
                  setState(() {
                    _selectedPayerId = value;
                  });
                },
                items: _groupMembers.map((member) {
                  final user = member['users'];
                  return DropdownMenuItem<String>(
                    value: user['id'],
                    child: Text(user['name']),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Select Payer'),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a payer';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _addExpense,
                      child: Text('Add Expense'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}