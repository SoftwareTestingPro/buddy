import '../models/category_and_plans.dart';

/// Core system constants and configurations for the Buddy platform
class AppData {
  /// All official categories and activities available for companions
  static final List<BuddyCategory> categories = [
    const BuddyCategory(
      id: 'nightout',
      name: 'Nightout Buddy',
      description: 'Safe, fun company for your late-night outings, drives, and city night walks.',
      iconName: 'nightlight_round',
      startingPrice: '₹2000/hr',
    ),
    const BuddyCategory(
      id: 'movie',
      name: 'Movie Buddy',
      description: 'Enjoy films, IMAX shows, and cinema screenings with great company.',
      iconName: 'movie',
      startingPrice: '₹1000/hr',
    ),
    const BuddyCategory(
      id: 'shopping',
      name: 'Shopping Buddy',
      description: 'Personal styling assist and companion for a smarter, fun shopping spree.',
      iconName: 'shopping_bag',
      startingPrice: '₹1000/hr',
    ),
    const BuddyCategory(
      id: 'clubbing',
      name: 'Clubbing Buddy',
      description: 'Your go-to energetic partner for pub crawls, lounges, and a great party night.',
      iconName: 'nightlife',
      startingPrice: '₹2000/hr',
    ),
    const BuddyCategory(
      id: 'travel',
      name: 'Travel Buddy',
      description: 'A trusted, adventurous companion for day-trips, weekend getaways, and journeys.',
      iconName: 'flight',
      startingPrice: '₹1500/hr',
    ),
    const BuddyCategory(
      id: 'gaming',
      name: 'Gaming Buddy',
      description: 'Level up with a skilled co-op gaming partner for LAN cafes, PS5, and esports.',
      iconName: 'sports_esports',
      startingPrice: '₹1000/hr',
    ),
    const BuddyCategory(
      id: 'dance',
      name: 'Dance Buddy',
      description: 'Move to the beat with a dance partner for salsa, bachata, hip-hop, or garba.',
      iconName: 'directions_walk',
      startingPrice: '₹1000/hr',
    ),
    const BuddyCategory(
      id: 'fitness',
      name: 'Fitness Buddy',
      description: 'Expert motivation and workout companion for gym, running, and athletic goals.',
      iconName: 'fitness_center',
      startingPrice: '₹1000/hr',
    ),
    const BuddyCategory(
      id: 'driving',
      name: 'Driving Buddy',
      description: 'Reliable, safe driving companion and road-trip navigator whenever you need.',
      iconName: 'directions_car',
      startingPrice: '₹1000/hr',
    ),
    const BuddyCategory(
      id: 'language',
      name: 'Language Buddy',
      description: 'Practice and learn new languages naturally through friendly conversations.',
      iconName: 'translate',
      startingPrice: '₹1000/hr',
    ),
    const BuddyCategory(
      id: 'photography',
      name: 'Photography Buddy',
      description: 'Capture aesthetic Instagram portraits and perfect moments with a photo partner.',
      iconName: 'camera_alt',
      startingPrice: '₹2000/hr',
    ),
    const BuddyCategory(
      id: 'city_explorer',
      name: 'City Explorer Buddy',
      description: 'Discover hidden gems, monuments, and cultural spots with a city-savvy guide.',
      iconName: 'explore',
      startingPrice: '₹1000/hr',
    ),
    const BuddyCategory(
      id: 'interview',
      name: 'Interview Buddy',
      description: 'Ace your next job interview with mock sessions, behavioral drill, and feedback.',
      iconName: 'work',
      startingPrice: '₹500/hr',
    ),
    const BuddyCategory(
      id: 'cafe',
      name: 'Cafe Buddy',
      description: 'Great conversations, cozy vibes, and coffee tasting with a friendly companion.',
      iconName: 'coffee',
      startingPrice: '₹500/hr',
    ),
    const BuddyCategory(
      id: 'carpooling',
      name: 'Car Pooling Buddy',
      description: 'Share rides, split commuting costs, and travel safely with trusted companions.',
      iconName: 'commute',
      startingPrice: '₹300/trip',
    ),
    const BuddyCategory(
      id: 'study_coworking',
      name: 'Study & Coworking Buddy',
      description: 'Focus-mate for library sessions, coding sprints, and productive work sessions.',
      iconName: 'menu_book',
      startingPrice: '₹500/hr',
    ),
    const BuddyCategory(
      id: 'events_plusone',
      name: 'Events & Plus-One Buddy',
      description: 'Well-dressed, polite companion for weddings, family functions, and formal galas.',
      iconName: 'celebration',
      startingPrice: '₹1500/hr',
    ),
    const BuddyCategory(
      id: 'pet_walking',
      name: 'Pet & Dog Walking Buddy',
      description: 'Friendly companion for park walks, dog socializing, and pet-friendly hangouts.',
      iconName: 'pets',
      startingPrice: '₹500/hr',
    ),
    const BuddyCategory(
      id: 'food_crawl',
      name: 'Food Crawl & Dining Buddy',
      description: 'Explore trending street food, night markets, and gourmet dining spots together.',
      iconName: 'restaurant',
      startingPrice: '₹800/hr',
    ),
  ];

  /// Popular metropolitan and Tier-1 hubs across India
  static const List<String> popularCities = [
    'All India',
    'Delhi NCR',
    'Bengaluru',
    'Mumbai',
    'Pune',
    'Hyderabad',
    'Kolkata',
    'Jaipur',
    'Goa',
    'Chandigarh',
    'Ahmedabad',
    'Chennai',
  ];

  /// Platform membership plans and passes
  static const List<MembershipPlan> membershipPlans = [
    MembershipPlan(
      id: 'starter',
      title: 'Free Explorer',
      price: '₹0',
      billingPeriod: 'Forever free',
      features: [
        'Browse all verified profiles',
        'Standard booking requests',
        '1 Active booking at a time',
        'Standard chat messaging',
      ],
      isPopular: false,
    ),
    MembershipPlan(
      id: 'plus',
      title: 'Buddy Plus',
      price: '₹399',
      billingPeriod: 'per month',
      features: [
        'Unlimited simultaneous bookings',
        'Priority booking approval',
        'Zero platform service fees',
        'Direct phone number unlocking upon confirm',
        'Free rescheduling (up to 3 times/mo)',
      ],
      isPopular: true,
      badgeText: 'MOST POPULAR',
    ),
    MembershipPlan(
      id: 'vip',
      title: 'VIP Pass',
      price: '₹899',
      billingPeriod: 'per 3 months',
      features: [
        'All Plus benefits included',
        'Dedicated SOS concierge hotline',
        'Verified VIP badge on your profile',
        'Curated buddy matching concierge',
        'Exclusive weekend experiences access',
      ],
      isPopular: false,
      badgeText: 'BEST VALUE',
    ),
  ];
}
