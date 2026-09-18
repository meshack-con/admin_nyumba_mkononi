class AnalyticsSummary {
  final int totalBuyers;
  final int totalSellers;
  final int totalUsers;
  final int pendingProperties;
  final int registrationsToday;
  final int registrationsThisWeek;
  final int registrationsThisMonth;
  final int registrationsThisYear;
  final int loginsToday;
  final int loginsThisWeek;
  final int loginsThisMonth;
  final int loginsThisYear;

  AnalyticsSummary({
    required this.totalBuyers,
    required this.totalSellers,
    required this.totalUsers,
    required this.pendingProperties,
    required this.registrationsToday,
    required this.registrationsThisWeek,
    required this.registrationsThisMonth,
    required this.registrationsThisYear,
    required this.loginsToday,
    required this.loginsThisWeek,
    required this.loginsThisMonth,
    required this.loginsThisYear,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalBuyers: json['total_buyers'] as int,
      totalSellers: json['total_sellers'] as int,
      totalUsers: json['total_users'] as int,
      pendingProperties: json['pending_properties'] as int,
      registrationsToday: json['registrations_today'] as int,
      registrationsThisWeek: json['registrations_this_week'] as int,
      registrationsThisMonth: json['registrations_this_month'] as int,
      registrationsThisYear: json['registrations_this_year'] as int,
      loginsToday: json['logins_today'] as int,
      loginsThisWeek: json['logins_this_week'] as int,
      loginsThisMonth: json['logins_this_month'] as int,
      loginsThisYear: json['logins_this_year'] as int,
    );
  }
}

class MonthlyPoint {
  final String period; // "2026-01"
  final int buyer;
  final int seller;
  final int total;

  MonthlyPoint({
    required this.period,
    required this.buyer,
    required this.seller,
    required this.total,
  });

  factory MonthlyPoint.fromJson(Map<String, dynamic> json) {
    return MonthlyPoint(
      period: json['period'] as String,
      buyer: json['buyer'] as int,
      seller: json['seller'] as int,
      total: json['total'] as int,
    );
  }
}
