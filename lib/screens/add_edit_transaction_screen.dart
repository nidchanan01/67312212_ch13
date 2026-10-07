// lib/screens/add_edit_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/my_transaction.dart';
import '../providers/transaction_provider.dart';

/// หน้าฟอร์มเดียวใช้ได้ทั้งเพิ่มและแก้ไข
/// ถ้าส่ง [transaction] เข้ามา = แก้ไข, ถ้าไม่ส่ง = เพิ่มใหม่
class AddEditTransactionScreen extends StatefulWidget {
  final MyTransaction? transaction;
  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late DateTime _date;
  late TransactionType _type;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _amountCtrl = TextEditingController(text: t?.amount.toString() ?? '');
    _noteCtrl = TextEditingController(text: t?.note ?? '');
    _date = t?.date ?? DateTime.now();
    _type = t?.type ?? TransactionType.expense;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TransactionProvider>();
    final title = _titleCtrl.text.trim();
    final amount = double.parse(_amountCtrl.text);
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    if (_isEdit) {
      final old = widget.transaction!;
      await provider.updateTransaction(
        old.id!,
        MyTransaction(
          id: old.id,
          title: title,
          amount: amount,
          date: _date,
          type: _type,
          note: note,
        ),
      );
    } else {
      await provider.addTransaction(title, amount, _date, _type, note: note);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'แก้ไขรายการ' : 'เพิ่มรายการ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อรายการ'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'กรุณาป้อนชื่อรายการ'
                    : null,
              ),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null) return 'กรุณาป้อนตัวเลขที่ถูกต้อง';
                  if (n <= 0) return 'จำนวนเงินต้องมากกว่า 0';
                  return null;
                },
              ),
              TextFormField(
                controller: _noteCtrl,
                decoration:
                    const InputDecoration(labelText: 'บันทึกเพิ่มเติม (ไม่บังคับ)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                      value: TransactionType.income, label: Text('รายรับ')),
                  ButtonSegment(
                      value: TransactionType.expense, label: Text('รายจ่าย')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(DateFormat.yMMMd().format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _save, child: const Text('บันทึก')),
            ],
          ),
        ),
      ),
    );
  }
}
