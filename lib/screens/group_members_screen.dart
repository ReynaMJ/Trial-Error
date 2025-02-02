import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupMembersScreen extends StatelessWidget {
  final String groupId;
  final supabase = Supabase.instance.client;

  GroupMembersScreen({required this.groupId});

  // Fetch members of a group from Supabase
  Future<List<Map<String, dynamic>>> fetchGroupMembers() async {
    final response = await supabase
        .from('group_members')
        .select('''
          users (id, name)
        ''')
        .eq('group_id', groupId)
        ;

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Members'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchGroupMembers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No members found in this group.'));
          } else {
            final members = snapshot.data!;
            return ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index]['users'];
                return ListTile(
                  title: Text(member['name']),
                );
              },
            );
          }
        },
      ),
    );
  }
}