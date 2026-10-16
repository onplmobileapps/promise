import 'package:flutter/foundation.dart';
import 'package:railway_hrms/core/constants/app_assets.dart';

/// A mobile network a traveller picks to sign in to train tracking.
@immutable
class NetworkOperator {
  const NetworkOperator({required this.name, required this.logo});

  /// The network's brand name, which isn't translated.
  final String name;

  /// Asset path of its logo.
  final String logo;

  /// Pakistan's mobile networks, in the order the picker lists them.
  static const all = [
    NetworkOperator(name: 'Jazz', logo: AppAssets.operatorJazz),
    NetworkOperator(name: 'Telenor', logo: AppAssets.operatorTelenor),
    NetworkOperator(name: 'Zong', logo: AppAssets.operatorZong),
    NetworkOperator(name: 'Ufone', logo: AppAssets.operatorUfone),
    NetworkOperator(name: 'Warid', logo: AppAssets.operatorWarid),
    NetworkOperator(name: 'SCO', logo: AppAssets.operatorSco),
  ];

  @override
  bool operator ==(Object other) =>
      other is NetworkOperator && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
