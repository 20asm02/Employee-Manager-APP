import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'employee_details_screen.dart';

class EmployeeScreen extends StatefulWidget {
  final String companyId;
  final String companyName;

  const EmployeeScreen({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _positionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _notesController = TextEditingController();

  String selectedContractType = 'Full-time';
  DateTime? selectedDate;

  final List<String> contractTypes = [
    'Full-time',
    'Part-time',
    'Temporary',
    'Freelancer',
  ];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _addEmployee() async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final position = _positionController.text.trim();
    final salary = double.tryParse(_salaryController.text.trim()) ?? 0;
    final notes = _notesController.text.trim();
    final contractType = selectedContractType;
    final date = selectedDate;

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('employees')
        .add({
          'fullName': name,
          'age': age,
          'position': position,
          'salary': salary,
          'notes': notes,
          'contractType': contractType,
          'dateOfJoining': date,
          'createdAt': FieldValue.serverTimestamp(),
        });

    _clearForm();
    Navigator.pop(context);
  }

  void _clearForm() {
    _nameController.clear();
    _ageController.clear();
    _positionController.clear();
    _salaryController.clear();
    _notesController.clear();
    selectedDate = null;
    selectedContractType = 'Full-time';
    setState(() {});
  }

  void _showEditEmployeeDialog(DocumentSnapshot emp) {
    final nameController = TextEditingController(text: emp['fullName']);
    final ageController = TextEditingController(text: emp['age'].toString());
    final positionController = TextEditingController(text: emp['position']);
    final salaryController = TextEditingController(
      text: emp['salary'].toString(),
    );
    final notesController = TextEditingController(
      text: emp.data().toString().contains('notes') ? emp['notes'] : '',
    );
    String contractType =
        emp.data().toString().contains('contractType')
            ? emp['contractType']
            : 'Full-time';
    DateTime? joinDate =
        emp.data().toString().contains('dateOfJoining')
            ? (emp['dateOfJoining'] as Timestamp).toDate()
            : null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Employee'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  keyboardType: TextInputType.name,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                ),
                TextField(
                  controller: positionController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(labelText: 'Position'),
                ),
                TextField(
                  controller: salaryController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Salary'),
                ),
                DropdownButtonFormField(
                  value: contractType,
                  items:
                      contractTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => contractType = value!,
                  decoration: const InputDecoration(labelText: 'Contract Type'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      joinDate == null
                          ? 'Pick joining date'
                          : 'Joined: ${DateFormat('yyyy-MM-dd').format(joinDate!)}',
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: joinDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => joinDate = picked);
                        }
                      },
                      child: const Text('Pick Date'),
                    ),
                  ],
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
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
                    .doc(widget.companyId)
                    .collection('employees')
                    .doc(emp.id)
                    .update({
                      'fullName': nameController.text.trim(),
                      'age': int.tryParse(ageController.text.trim()) ?? 0,
                      'position': positionController.text.trim(),
                      'salary':
                          double.tryParse(salaryController.text.trim()) ?? 0,
                      'contractType': contractType,
                      'notes': notesController.text.trim(),
                      'dateOfJoining': joinDate,
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

  void _deleteEmployee(String empId) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('employees')
        .doc(empId)
        .delete();
  }

  void _showAddFormBottomSheet(BuildContext context) {
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                      ),
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Required'
                                  : null,
                    ),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age *'),
                      validator: (value) {
                        final age = int.tryParse(value ?? '');
                        if (age == null || age <= 0) return 'Enter valid age';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _positionController,
                      decoration: const InputDecoration(
                        labelText: 'Position *',
                      ),
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Required'
                                  : null,
                    ),
                    TextFormField(
                      controller: _salaryController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Salary *'),
                      validator: (value) {
                        final salary = double.tryParse(value ?? '');
                        if (salary == null || salary <= 0)
                          return 'Enter valid salary';
                        return null;
                      },
                    ),
                    DropdownButtonFormField(
                      value: selectedContractType,
                      items:
                          contractTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) =>
                              setState(() => selectedContractType = value!),
                      decoration: const InputDecoration(
                        labelText: 'Contract Type *',
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          selectedDate == null
                              ? 'Select joining date *'
                              : 'Joining: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                          style: TextStyle(
                            color:
                                selectedDate == null
                                    ? Colors.red
                                    : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _pickDate,
                          child: const Text('Pick Date'),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate() &&
                            selectedDate != null) {
                          _addEmployee();
                        } else if (selectedDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a joining date.'),
                            ),
                          );
                        }
                      },
                      child: const Text('Save Employee'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Employees - ${widget.companyName}')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('companies')
                .doc(widget.companyId)
                .collection('employees')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          final employees = snapshot.data?.docs ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                employees.isEmpty
                    ? 'No employees yet.'
                    : 'All Employees (${employees.length}):',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (employees.isNotEmpty)
                ...employees.map((emp) {
                  final dojRaw =
                      emp.data().toString().contains('dateOfJoining')
                          ? emp['dateOfJoining']
                          : null;
                  final doj = dojRaw is Timestamp ? dojRaw.toDate() : null;

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
                                (_) => EmployeeDetailScreen(
                                  companyId: widget.companyId,
                                  companyName: widget.companyName,
                                  employeeId: emp.id,
                                  employeeData:
                                      emp.data() as Map<String, dynamic>,
                                ),
                          ),
                        );
                      },
                      title: Text(emp['fullName']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Position: ${emp['position']}'),
                          Text('Contract: ${emp['contractType']}'),
                          if (doj != null)
                            Text(
                              'Joined: ${DateFormat('yyyy-MM-dd').format(doj)}',
                            ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditEmployeeDialog(emp);
                          } else if (value == 'delete') {
                            _deleteEmployee(emp.id);
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
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: () => _showAddFormBottomSheet(context),
                  child: const Text('Add Employee'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
