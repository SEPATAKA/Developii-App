import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/features/investor/domain/investor_project_content.dart';

enum ProjectCategory {
  residential,
  commercial,
  hospitality,
  industrial,
  retail,
}

enum ProjectSort {
  trending,
  newest,
  closingSoon,
  returnRate,
  minimumInvestment,
  fundingProgress,
}

enum ProjectFundingStatus { open, targetReached, newToday }

extension ProjectCategoryLabel on ProjectCategory {
  String get label => '${name[0].toUpperCase()}${name.substring(1)}';
}

extension ProjectSortLabel on ProjectSort {
  String get label => switch (this) {
    ProjectSort.trending => 'Trending',
    ProjectSort.newest => 'Newest',
    ProjectSort.closingSoon => 'Closing Soon',
    ProjectSort.returnRate => 'Highest ROI',
    ProjectSort.minimumInvestment => 'Lowest Minimum',
    ProjectSort.fundingProgress => 'Funding Progress',
  };
}

final class InvestorProject {
  const InvestorProject({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    required this.area,
    required this.category,
    required this.imageAsset,
    this.thumbnailAsset,
    this.heroAsset,
    required this.target,

    required this.maximumInvestment,
    required this.annualReturnBasisPoints,
    required this.durationMonths,
    required this.raised,
    this.acceptingInvestments = true,
    required this.description,
    required this.developer,
    this.investorCount = 1284,
    this.isFavourite = false,
    this.publishedAt,
    this.closesAt,
    this.exploreOrder = 0,
    this.content,
  });

  final String id;
  final String name;
  final String city;
  final String country;
  final String area;
  final ProjectCategory category;
  final String imageAsset;
  final String? thumbnailAsset;
  final String? heroAsset;
  final MonetaryAmount target;
  MonetaryAmount get minimumInvestment => InvestmentPolicy.minimum;
  final MonetaryAmount maximumInvestment;
  final int annualReturnBasisPoints;
  final int durationMonths;
  final MonetaryAmount? raised;
  final bool acceptingInvestments;
  bool get hasValidFunding =>
      target.currency == InvestmentPolicy.currency &&
      target.minorUnits > 0 &&
      raised != null &&
      raised!.currency == target.currency &&
      raised!.minorUnits >= 0;
  bool get fullyFunded =>
      hasValidFunding && raised!.minorUnits >= target.minorUnits;
  int get fundedBasisPoints => !hasValidFunding
      ? 0
      : (raised!.minorUnits * 10000 ~/ target.minorUnits).clamp(0, 10000);
  MonetaryAmount? get remainingCapacity => !hasValidFunding
      ? null
      : MonetaryAmount(
          (target.minorUnits - raised!.minorUnits).clamp(0, target.minorUnits),
          target.currency,
        );
  bool get supportsProjection =>
      durationMonths > 0 && annualReturnBasisPoints >= 0;
  String? get investmentUnavailableReason {
    if (!hasValidFunding) {
      return 'Funding information is unavailable. Please try again.';
    }
    if (raised!.minorUnits >= target.minorUnits) {
      return 'This project is fully funded.';
    }
    if (!acceptingInvestments) {
      return 'This project is not accepting investments.';
    }
    if (!supportsProjection) {
      return 'The project distribution schedule is unavailable.';
    }
    if (remainingCapacity!.minorUnits < InvestmentPolicy.minimum.minorUnits) {
      return 'The remaining capacity is below the ${InvestmentPolicy.minimumLabel} minimum investment.';
    }
    return null;
  }

  bool get canInvest => investmentUnavailableReason == null;
  String? validateInvestment(MonetaryAmount amount) {
    if (investmentUnavailableReason != null) return investmentUnavailableReason;
    if (amount.currency != InvestmentPolicy.currency ||
        amount.minorUnits < InvestmentPolicy.minimum.minorUnits) {
      return 'The minimum investment is ${InvestmentPolicy.minimumLabel}.';
    }
    if (amount.minorUnits > maximumInvestment.minorUnits) {
      return 'This amount exceeds the project investment limit.';
    }
    if (amount.minorUnits > remainingCapacity!.minorUnits) {
      return 'This amount exceeds the remaining project capacity.';
    }
    return null;
  }

  InvestorProject withFunding({
    required MonetaryAmount? raised,
    bool? acceptingInvestments,
  }) => InvestorProject(
    id: id,
    name: name,
    city: city,
    country: country,
    area: area,
    category: category,
    imageAsset: imageAsset,
    thumbnailAsset: thumbnailAsset,
    heroAsset: heroAsset,
    target: target,
    maximumInvestment: maximumInvestment,
    annualReturnBasisPoints: annualReturnBasisPoints,
    durationMonths: durationMonths,
    raised: raised,
    acceptingInvestments: acceptingInvestments ?? this.acceptingInvestments,
    description: description,
    developer: developer,
    investorCount: investorCount,
    isFavourite: isFavourite,
    publishedAt: publishedAt,
    closesAt: closesAt,
    exploreOrder: exploreOrder,
    content: content,
  );
  final String description;
  final String developer;
  final int investorCount;
  final bool isFavourite;
  final DateTime? publishedAt;
  final DateTime? closesAt;
  final int exploreOrder;
  final InvestorProjectContent? content;

  InvestmentProjection projection(MonetaryAmount amount) {
    _requireCurrency(amount);
    return InvestmentProjection(
      principal: amount,
      annualRateBasisPoints: annualReturnBasisPoints,
      termMonths: durationMonths,
      payoutEveryMonths: InvestmentPolicy.payoutEveryMonths,
    );
  }

  MonetaryAmount projectedPayout(MonetaryAmount amount) =>
      projection(amount).payout;
  MonetaryAmount monthlyDistribution(MonetaryAmount amount) =>
      projection(amount).payments.first;

  void _requireCurrency(MonetaryAmount amount) {
    if (amount.currency != minimumInvestment.currency) {
      throw ArgumentError('The investment currency must match the project.');
    }
  }
}

final class ProjectFilter {
  ProjectFilter({
    this.category,
    this.location = '',
    this.minimumReturnBasisPoints = 0,
    this.minimumInvestment = InvestmentPolicy.minimumMajorUnits,
    this.maximumInvestment = 50000,
    Set<ProjectFundingStatus> funding = const {},
    this.sort = ProjectSort.trending,
  }) : funding = Set.unmodifiable(funding);

  final ProjectCategory? category;
  final String location;
  final int minimumReturnBasisPoints;
  final int minimumInvestment;
  final int maximumInvestment;
  final Set<ProjectFundingStatus> funding;
  final ProjectSort sort;

  static const locations = [
    'Cape Town',
    'Durban',
    'East London',
    'Pretoria',
    'Port Elizabeth',
    'Johannesburg',
    'Bloemfontein',
  ];

  Map<String, String> get parameters => {
    if (category != null) 'category': category!.name,
    if (location.isNotEmpty) 'location': location,
    if (minimumReturnBasisPoints != 0) 'roi': '$minimumReturnBasisPoints',
    if (minimumInvestment != InvestmentPolicy.minimumMajorUnits)
      'min': '$minimumInvestment',
    if (maximumInvestment != 50000) 'max': '$maximumInvestment',
    if (sort != ProjectSort.trending) 'sort': sort.name,
    if (funding.isNotEmpty)
      'funding': ProjectFundingStatus.values
          .where(funding.contains)
          .map((value) => value.name)
          .join(','),
  };

  static ProjectFilter? tryParse(Map<String, String> parameters) {
    final category = ProjectCategory.values
        .where((value) => value.name == parameters['category'])
        .firstOrNull;
    final sort = ProjectSort.values
        .where((value) => value.name == parameters['sort'])
        .firstOrNull;
    final location = parameters['location'] ?? '';
    final minimum = int.tryParse(
      parameters['min'] ?? '${InvestmentPolicy.minimumMajorUnits}',
    );
    final maximum = int.tryParse(parameters['max'] ?? '50000');
    final roi = int.tryParse(parameters['roi'] ?? '0');
    final fundingNames = parameters['funding']?.split(',') ?? [];
    final funding = ProjectFundingStatus.values
        .where((value) => fundingNames.contains(value.name))
        .toSet();
    if ((parameters.containsKey('category') && category == null) ||
        (parameters.containsKey('sort') && sort == null) ||
        (location.isNotEmpty && !locations.contains(location)) ||
        minimum == null ||
        maximum == null ||
        minimum < InvestmentPolicy.minimumMajorUnits ||
        maximum > 50000 ||
        minimum > maximum ||
        ![0, 1000, 1500].contains(roi) ||
        fundingNames.any(
          (name) => !funding.any((value) => value.name == name),
        )) {
      return null;
    }
    return ProjectFilter(
      category: category,
      location: location,
      minimumInvestment: minimum,
      maximumInvestment: maximum,
      minimumReturnBasisPoints: roi!,
      funding: funding,
      sort: sort ?? ProjectSort.trending,
    );
  }
}
