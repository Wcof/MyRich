import 'package:flutter/material.dart';
import 'package:myrich/models/fund_plan.dart';

class FundPlanDialog extends StatefulWidget {
  final int assetId;
  final String fundCode;
  final String fundName;

  const FundPlanDialog({
    Key? key,
    required this.assetId,
    required this.fundCode,
    required this.fundName,
  }) : super(key: key);

  @override
  _FundPlanDialogState createState() => _FundPlanDialogState();
}

class _FundPlanDialogState extends State<FundPlanDialog> {
  final TextEditingController _amountController = TextEditingController();
  FundPlanPeriod _period = FundPlanPeriod.monthly;
  int? _weekDay;
  int? _monthDay = 1;
  final List<int> _weekDays = [1, 2, 3, 4, 5, 6, 7];
  final List<int> _monthDays = List.generate(31, (i) => i + 1);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置定投计划'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基金: ${widget.fundName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '基金代码: ${widget.fundCode}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              maxLines: 1,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '定投金额',
                hintText: '请输入定投金额',
                suffixText: '元',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('定投周期'),
            const SizedBox(height: 8),
            Column(
              children: FundPlanPeriod.values.map((period) {
                return RadioListTile<FundPlanPeriod>(
                  title: Text(_getPeriodText(period)),
                  value: period,
                  groupValue: _period,
                  onChanged: (value) {
                    setState(() {
                      _period = value!;
                      if (_period == FundPlanPeriod.weekly || _period == FundPlanPeriod.biweekly) {
                        _weekDay = 1; // 默认周一
                        _monthDay = null;
                      } else if (_period == FundPlanPeriod.monthly) {
                        _monthDay = 1; // 默认1号
                        _weekDay = null;
                      } else {
                        _weekDay = null;
                        _monthDay = null;
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (_period == FundPlanPeriod.weekly || _period == FundPlanPeriod.biweekly) ...[
              const SizedBox(height: 16),
              const Text('选择周几'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _weekDays.map((day) {
                  return ChoiceChip(
                    label: Text(_getWeekDayText(day)),
                    selected: _weekDay == day,
                    onSelected: (selected) {
                      setState(() {
                        _weekDay = selected ? day : null;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            if (_period == FundPlanPeriod.monthly) ...[
              const SizedBox(height: 16),
              const Text('选择几号'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _monthDays.map((day) {
                  return ChoiceChip(
                    label: Text('$day号'),
                    selected: _monthDay == day,
                    onSelected: (selected) {
                      setState(() {
                        _monthDay = selected ? day : null;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            _submit();
          },
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF10B981),
          ),
          child: const Text('确认'),
        ),
      ],
    );
  }

  String _getPeriodText(FundPlanPeriod period) {
    switch (period) {
      case FundPlanPeriod.daily:
        return '每日';
      case FundPlanPeriod.weekly:
        return '每周';
      case FundPlanPeriod.biweekly:
        return '每两周';
      case FundPlanPeriod.monthly:
        return '每月';
    }
  }

  String _getWeekDayText(int day) {
    switch (day) {
      case 1:
        return '周一';
      case 2:
        return '周二';
      case 3:
        return '周三';
      case 4:
        return '周四';
      case 5:
        return '周五';
      case 6:
        return '周六';
      case 7:
        return '周日';
      default:
        return '未知';
    }
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text);
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的定投金额')),
      );
      return;
    }

    if ((_period == FundPlanPeriod.weekly || _period == FundPlanPeriod.biweekly) && _weekDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择周几')),
      );
      return;
    }

    if (_period == FundPlanPeriod.monthly && _monthDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择几号')),
      );
      return;
    }

    final plan = FundPlan(
      assetId: widget.assetId,
      fundCode: widget.fundCode,
      fundName: widget.fundName,
      amount: amount,
      period: _period,
      weekDay: _weekDay,
      monthDay: _monthDay,
      startDate: DateTime.now(),
      status: FundPlanStatus.active,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      nextExecuteAt: _calculateNextExecuteTime(),
    );

    Navigator.pop(context, plan);
  }

  int _calculateNextExecuteTime() {
    DateTime next = DateTime.now();
    
    switch (_period) {
      case FundPlanPeriod.daily:
        next = next.add(const Duration(days: 1));
        break;
      case FundPlanPeriod.weekly:
        while (next.weekday != _weekDay) {
          next = next.add(const Duration(days: 1));
        }
        break;
      case FundPlanPeriod.biweekly:
        while (next.weekday != _weekDay) {
          next = next.add(const Duration(days: 1));
        }
        break;
      case FundPlanPeriod.monthly:
        next = DateTime(next.year, next.month, _monthDay!);
        if (next.isBefore(DateTime.now())) {
          next = DateTime(next.year, next.month + 1, _monthDay!);
        }
        break;
    }
    
    return next.millisecondsSinceEpoch;
  }
}
