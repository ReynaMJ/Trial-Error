import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddGroupScreen extends StatefulWidget {
  @override
  _AddGroupScreenState createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];
  List<String> _selectedUserIds = [];

  // Fetch all users from Supabase
  Future<void> _fetchUsers() async {
    try {
      final response = await supabase.from('users').select();
      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $error')),
      );
    }
  }

  // Add a new group and its members
  Future<void> _addGroup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final groupName = _nameController.text;

      try {
        // Insert the group into the groups table
        final groupResponse = await supabase
            .from('groups')
            .insert({'name': groupName})
            .select()
            .single();

        final groupId = groupResponse['id'];

        // Batch insert selected users into the group_members table
        if (_selectedUserIds.isNotEmpty) {
          await supabase.from('group_members').insert(
            _selectedUserIds.map((userId) => {
              'group_id': groupId,
              'user_id': userId,
            }).toList(),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group created successfully')),
        );
        Navigator.pop(context); // Go back to the previous screen
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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
        title: Text('Add Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Group Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text(
                'Select Members:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: _users.isEmpty
                    ? Center(child: Text('No users available'))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return CheckboxListTile(
                            title: Text(user['name']),
                            value: _selectedUserIds.contains(user['id']),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedUserIds.add(user['id']);
                                } else {
                                  _selectedUserIds.remove(user['id']);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _addGroup,
                      child: Text('Create Group'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
