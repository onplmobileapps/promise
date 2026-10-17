import 'package:railway_hrms/core/network/api_endpoints.dart';

/// The inspections the server takes, each at its own address.
enum InspectionApi {
  /// A signalling and telecom station inspection.
  station(ApiEndpoints.submitStationInspectionComplete),

  /// A motor trolley inspection.
  motorTrolley(ApiEndpoints.submitMotorTrolleyComplete),

  /// A locomotive inspected at its shed.
  shed(ApiEndpoints.submitShedInspection),

  /// A train lighting (RTL) inspection.
  rtl(ApiEndpoints.submitRtlInspection),

  /// An electrical power installation inspection.
  power(ApiEndpoints.submitPowerInspection);

  const InspectionApi(this.path);

  final String path;

  /// The kind [name] names, as a saved inspection keeps it.
  static InspectionApi? named(String? name) {
    for (final api in values) {
      if (api.name == name) return api;
    }
    return null;
  }
}
