class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    required this.maskedNumber,
  });

  final String id;
  final String name;
  final String type;
  final String balance;
  final String currency;
  final String maskedNumber;
}
