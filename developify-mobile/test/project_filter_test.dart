import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';

void main() {
  test(
    'Project filters round-trip primitive route values and freeze selections',
    () {
      final funding = {
        ProjectFundingStatus.open,
        ProjectFundingStatus.newToday,
      };
      final filter = ProjectFilter(
        category: ProjectCategory.industrial,
        location: 'Pretoria',
        minimumReturnBasisPoints: 1000,
        minimumInvestment: 200,
        maximumInvestment: 50000,
        sort: ProjectSort.newest,
        funding: funding,
      );
      funding.clear();
      final parameters = Uri.splitQueryString(
        Uri(queryParameters: filter.parameters).query,
      );
      final parsed = ProjectFilter.tryParse(parameters)!;
      expect(parsed.parameters, filter.parameters);
      expect(parsed.funding, {
        ProjectFundingStatus.open,
        ProjectFundingStatus.newToday,
      });
      expect(() => parsed.funding.clear(), throwsUnsupportedError);
      expect(ProjectFilter.tryParse({})!.parameters, isEmpty);
    },
  );

  test(
    'Malformed filter links are rejected without throwing or widening the range',
    () {
      for (final parameters in [
        {'category': 'Johannesburg'},
        {'sort': 'random'},
        {'location': 'Missing'},
        {'min': '-1'},
        {'min': 'x'},
        {'min': '501', 'max': '200'},
        {'max': '50001'},
        {'min': 'NaN'},
        {'roi': '999999'},
        {'funding': 'open,missing'},
        {'funding': ''},
      ]) {
        expect(
          ProjectFilter.tryParse(parameters),
          isNull,
          reason: '$parameters',
        );
      }
    },
  );
}
