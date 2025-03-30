import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_employee.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _addCompany() async {
    final user = FirebaseAuth.instance.currentUser;
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (user == null || name.isEmpty || description.isEmpty) return;

    await FirebaseFirestore.instance.collection('companies').add({
      'name': name,
      'description': description,
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _nameController.clear();
    _descriptionController.clear();
    Navigator.pop(context);
  }

  void _deleteCompany(String docId) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(docId)
        .delete();
  }

  void _showEditDialog(DocumentSnapshot doc) {
    final nameController = TextEditingController(text: doc['name']);
    final descController = TextEditingController(
      text:
          doc.data().toString().contains('description')
              ? doc['description']
              : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Company'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('companies')
                    .doc(doc.id)
                    .update({
                      'name': nameController.text.trim(),
                      'description': descController.text.trim(),
                    });
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCompanyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _addCompany,
                    child: const Text('Save Company'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Companies')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('companies')
                .where('ownerId', isEqualTo: user?.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                docs.isEmpty
                    ? 'No companies yet.'
                    : 'My Companies (${docs.length}):',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...docs.map((doc) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => EmployeeScreen(
                                companyId: doc.id,
                                companyName: doc['name'],
                              ),
                        ),
                      );
                    },
                    title: Text(doc['name']),
                    subtitle: Text(
                      doc.data().toString().contains('description')
                          ? doc['description']
                          : 'No description',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditDialog(doc);
                        } else if (value == 'delete') {
                          _deleteCompany(doc.id);
                        }
                      },
                      itemBuilder:
                          (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                    ),
                  ),
                );
              }),
              const Divider(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: () => _showAddCompanyBottomSheet(context),
                  child: const Text('Add Company'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
