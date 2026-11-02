import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gateway_repository_provider.dart';
import '../../domain/models/usage_summary.dart';
import '../../domain/repositories/gateway_repository.dart';

/// Períodos oferecidos, os mesmos do Dashboard web.
const usagePeriods = [7, 30, 90];

/// Uso dos últimos N dias pelo Dashboard. Sem pareamento falha com
/// `StateError`.
final usageSummaryProvider = FutureProvider.autoDispose
    .family<UsageSummary, int>((ref, days) {
      final GatewayRepository gateway;
      try {
        gateway = ref.watch(gatewayRepositoryProvider);
      } catch (_) {
        throw StateError('Dashboard não pareado.');
      }
      return gateway.usage(days: days);
    });
