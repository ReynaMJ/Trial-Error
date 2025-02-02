import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trialerror/screens/group_members_screen.dart'; // Screen to display group members
import 'package:trialerror/screens/add_group_screen.dart';
class GroupsScreen extends StatelessWidget {
  final supabase = Supabase.instance.client;

  // Fetch all groups from Supabase
  Future<List<Map<String, dynamic>>> fetchGroups() async {
    final response = await supabase.from('groups').select('*');
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Groups'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No groups found.'));
          } else {
            final groups = snapshot.data!;
            return ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  title: Text(group['name']),
                  trailing: IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: () {
                      // Navigate to the GroupMembersScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupMembersScreen(groupId: group['id']),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
  onPressed: () {
    // Navigate to AddGroupScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddGroupScreen()),
    );
  },
  child: Icon(Icons.add),
),

         
        
        
    
    );
  }
}
