import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final String companyId;
  final String employeeId;
  final Map<String, dynamic> employeeData;
  final String companyName;

  const EmployeeDetailScreen({
    super.key,
    required this.companyId,
    required this.employeeId,
    required this.employeeData,
    required this.companyName,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  int selectedYear = DateTime.now().year;

  void _showPayslipForm({DocumentSnapshot? slip}) {
    final bonusController = TextEditingController(
      text: slip != null ? slip['bonus'].toString() : '',
    );
    final descriptionController = TextEditingController(
      text: slip != null ? (slip['description'] ?? '') : '',
    );
    DateTime? paymentDate =
        slip != null ? (slip['paymentDate'] as Timestamp).toDate() : null;
    final now = DateTime.now();
    final selectedMonth =
        slip != null ? slip['month'] : DateFormat('MMMM yyyy').format(now);
    final baseSalary =
        slip != null
            ? slip['baseSalary']
            : widget.employeeData['salary'] ?? 0.0;

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
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payslip for ${widget.employeeData['fullName']} ($selectedMonth)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text('Base Salary: KD ${baseSalary.toStringAsFixed(2)}'),
                      TextField(
                        controller: bonusController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Bonus (optional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              text: 'Payment Date ',
                              style: const TextStyle(color: Colors.black),
                              children: const [
                                TextSpan(
                                  text: '*',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: paymentDate ?? now,
                                firstDate: DateTime(now.year - 1),
                                lastDate: DateTime(now.year + 1),
                              );
                              if (picked != null) {
                                setModalState(() => paymentDate = picked);
                              }
                            },
                            child: Text(
                              paymentDate == null
                                  ? 'Pick Payment Date'
                                  : 'Paid: ${DateFormat('yyyy-MM-dd').format(paymentDate!)}',
                            ),
                          ),
                        ],
                      ),

                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final bonus =
                              double.tryParse(bonusController.text.trim()) ??
                              0.0;
                          final description = descriptionController.text.trim();

                          if (paymentDate == null) return;

                          final payslipRef = FirebaseFirestore.instance
                              .collection('companies')
                              .doc(widget.companyId)
                              .collection('employees')
                              .doc(widget.employeeId)
                              .collection('payslips');

                          if (slip == null) {
                            await payslipRef.add({
                              'month': selectedMonth,
                              'baseSalary': baseSalary,
                              'bonus': bonus,
                              'paymentDate': paymentDate,
                              'description': description,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          } else {
                            await payslipRef.doc(slip.id).update({
                              'bonus': bonus,
                              'paymentDate': paymentDate,
                              'description':
                                  description.isNotEmpty ? description : null,
                            });
                          }

                          Navigator.pop(context);
                        },
                        child: Text(
                          slip == null ? 'Save Payslip' : 'Update Payslip',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }

  void _deletePayslip(String payslipId) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('employees')
        .doc(widget.employeeId)
        .collection('payslips')
        .doc(payslipId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final emp = widget.employeeData;
    final doj =
        emp['dateOfJoining'] != null
            ? (emp['dateOfJoining'] as Timestamp).toDate()
            : null;

    return Scaffold(
      appBar: AppBar(title: Text(emp['fullName'] ?? 'Employee Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company: ${widget.companyName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Position: ${emp['position']}'),
            Text('Contract Type: ${emp['contractType']}'),
            Text('Salary: KD ${emp['salary']}'),
            Text('Age: ${emp['age']}'),
            if (doj != null)
              Text('Joined: ${DateFormat('yyyy-MM-dd').format(doj)}'),
            const SizedBox(height: 16),
            const Text(
              'Payslips:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: selectedYear,
              onChanged: (int? newValue) {
                setState(() {
                  selectedYear = newValue!;
                });
              },
              items:
                  List.generate(10, (index) => DateTime.now().year - index)
                      .map<DropdownMenuItem<int>>(
                        (int value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        ),
                      )
                      .toList(),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('companies')
                        .doc(widget.companyId)
                        .collection('employees')
                        .doc(widget.employeeId)
                        .collection('payslips')
                        .where(
                          'paymentDate',
                          isGreaterThanOrEqualTo: Timestamp.fromDate(
                            DateTime(selectedYear, 1, 1),
                          ),
                        )
                        .where(
                          'paymentDate',
                          isLessThan: Timestamp.fromDate(
                            DateTime(selectedYear + 1, 1, 1),
                          ),
                        )
                        .orderBy('paymentDate', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final payslips = snapshot.data!.docs;

                  return Column(
                    children: [
                      if (payslips.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Center(
                            child: Text('No payslips available for this year.'),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: payslips.length,
                            itemBuilder: (context, index) {
                              final slip = payslips[index];
                              final payDate =
                                  (slip['paymentDate'] as Timestamp).toDate();
                              final base = slip['baseSalary'] ?? 0;
                              final bonus = slip['bonus'] ?? 0;
                              final total = base + bonus;

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: ListTile(
                                  title: Text('Month: ${slip['month']}'),
                                  subtitle: Text(
                                    'Base Salary: KD ${base.toStringAsFixed(2)}\n'
                                    'Bonus: KD ${bonus.toStringAsFixed(2)}\n'
                                    'Total Salary: KD ${total.toStringAsFixed(2)}\n'
                                    'Paid on: ${DateFormat('yyyy-MM-dd').format(payDate)}\n'
                                    '${slip.data().toString().contains('description') ? 'Note: ${slip['description']}' : ''}',
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showPayslipForm(slip: slip);
                                      } else if (value == 'delete') {
                                        _deletePayslip(slip.id);
                                      }
                                    },
                                    itemBuilder:
                                        (context) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => _showPayslipForm(),
                        child: const Text('Add Payslip'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
