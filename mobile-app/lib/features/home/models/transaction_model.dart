import 'package:flutter/material.dart';

enum TransactionType { debit, credit }

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.merchant,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    required this.icon,
    required this.iconColor,
  });

  final String id;
  final String merchant;
  final String category;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final IconData icon;
  final Color iconColor;

  bool get isCredit => type == TransactionType.credit;

  static final fakeTransactions = <TransactionModel>[
    TransactionModel(
      id: '1',
      merchant: 'Salary Deposit',
      category: 'Income',
      amount: 3850.00,
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: TransactionType.credit,
      icon: Icons.account_balance_rounded,
      iconColor: Colors.green,
    ),
    TransactionModel(
      id: '2',
      merchant: 'Netflix',
      category: 'Entertainment',
      amount: 15.99,
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: TransactionType.debit,
      icon: Icons.play_circle_rounded,
      iconColor: Colors.red,
    ),
    TransactionModel(
      id: '3',
      merchant: 'Whole Foods Market',
      category: 'Groceries',
      amount: 94.32,
      date: DateTime.now().subtract(const Duration(days: 3)),
      type: TransactionType.debit,
      icon: Icons.shopping_basket_rounded,
      iconColor: Colors.orange,
    ),
    TransactionModel(
      id: '4',
      merchant: 'Shell Station',
      category: 'Transport',
      amount: 62.10,
      date: DateTime.now().subtract(const Duration(days: 4)),
      type: TransactionType.debit,
      icon: Icons.local_gas_station_rounded,
      iconColor: Colors.amber,
    ),
    TransactionModel(
      id: '5',
      merchant: 'Transfer from Savings',
      category: 'Transfer',
      amount: 500.00,
      date: DateTime.now().subtract(const Duration(days: 5)),
      type: TransactionType.credit,
      icon: Icons.swap_horiz_rounded,
      iconColor: Colors.blue,
    ),
    TransactionModel(
      id: '6',
      merchant: 'Spotify',
      category: 'Entertainment',
      amount: 9.99,
      date: DateTime.now().subtract(const Duration(days: 6)),
      type: TransactionType.debit,
      icon: Icons.music_note_rounded,
      iconColor: Colors.green,
    ),
    TransactionModel(
      id: '7',
      merchant: 'Amazon',
      category: 'Shopping',
      amount: 138.49,
      date: DateTime.now().subtract(const Duration(days: 8)),
      type: TransactionType.debit,
      icon: Icons.shopping_bag_rounded,
      iconColor: Colors.deepOrange,
    ),
  ];
}
