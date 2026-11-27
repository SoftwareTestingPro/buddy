class BuddyCategory {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String startingPrice;

  const BuddyCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.startingPrice,
  });
}

class MembershipPlan {
  final String id;
  final String title;
  final String price;
  final String billingPeriod;
  final List<String> features;
  final bool isPopular;
  final String badgeText;

  const MembershipPlan({
    required this.id,
    required this.title,
    required this.price,
    required this.billingPeriod,
    required this.features,
    this.isPopular = false,
    this.badgeText = '',
  });
}
