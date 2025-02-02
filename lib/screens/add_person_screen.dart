import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPersonScreen extends StatefulWidget {
  @override
  _AddPersonScreenState createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final supabase = Supabase.instance.client;

  // Add a new person to the database
  Future<void> _addPerson() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;

      // Insert the person into the users table
      final response = await supabase
          .from('users')
          .insert({'name': name})
          ;

      if (response.error == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Person added successfully')));
        Navigator.pop(context); // Go back to the previous screen
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error adding person')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Person'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addPerson,
                child: Text('Add Person'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
