class LoginResponse {
  String? msg;
  User? user;
  Tokens? tokens;

  LoginResponse({this.msg, this.user, this.tokens});

  LoginResponse.fromJson(Map<String, dynamic> json) {
    msg = json['msg'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    tokens = json['tokens'] != null ? Tokens.fromJson(json['tokens']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['msg'] = msg;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    if (tokens != null) {
      data['tokens'] = tokens!.toJson();
    }
    return data;
  }

  LoginResponse copyWith({String? msg, User? user, Tokens? tokens}) {
    return LoginResponse(
      msg: msg ?? this.msg,
      user: user ?? this.user,
      tokens: tokens ?? this.tokens,
    );
  }
}

class User {
  int? id;

  RoleData? roleData;
  String? lastLogin;
  String? username;
  String? name;
  String? fullName;
  String? designation;
  int? profileStatus;
  bool? isDelete;
  String? profileImage;
  bool? isStaff;
  bool? isSuperuser;
  String? email;
  String? mobileNumber;
  String? resetCode;
  String? resetCodeExpiry;
  bool? initialReset;
  String? nic;
  bool? isHqUser;
  String? empid;
  String? sapid;
  int? role;
  int? division;
  int? section;
  Permissions? permissions;
  bool? hrmsLinked;
  bool? faceRegistered;
  String? verificationStatus;

  bool get isApproved {
    final status = verificationStatus?.toLowerCase().trim();
    if (status == 'verified' || status == 'approved') return true;
    if (_knownStatus) return false;
    return faceRegistered ?? false;
  }

  /// Whether [verificationStatus] is one this app acts on.
  bool get _knownStatus =>
      const {
        'verified',
        'approved',
        'pending',
        'rejected',
        'inprogress',
      }.contains(
        verificationStatus
            ?.toLowerCase()
            .trim()
            .replaceAll(' ', '')
            .replaceAll('_', ''),
      );

  bool get isRejected {
    final status = verificationStatus?.toLowerCase().trim();
    return status == 'rejected';
  }

  bool get isPending {
    final status = verificationStatus?.toLowerCase().trim();
    if (status == 'pending' || status == 'rejected') return true;
    if (_knownStatus) return false;
    return !(faceRegistered ?? false);
  }

  /// Registered and waiting for an admin to approve it. A status this
  /// app doesn't know never blocks attendance: it falls back to whether
  /// the face is registered.
  bool get isInProgress {
    final status = verificationStatus
        ?.toLowerCase()
        .trim()
        .replaceAll(' ', '')
        .replaceAll('_', '');
    return status == 'inprogress';
  }

  String get formattedVerificationStatus {
    final status = verificationStatus?.trim();
    if (status == null || status.isEmpty) {
      return 'Verification Pending';
    }
    if (status.toLowerCase().startsWith('verification')) {
      return status;
    }
    return 'Verification $status';
  }

  User({
    this.id,
    this.roleData,
    this.lastLogin,
    this.username,
    this.name,
    this.fullName,
    this.designation,
    this.profileStatus,
    this.isDelete,
    this.profileImage,
    this.isStaff,
    this.isSuperuser,
    this.email,
    this.mobileNumber,
    this.resetCode,
    this.resetCodeExpiry,
    this.initialReset,
    this.nic,
    this.isHqUser,
    this.empid,
    this.sapid,
    this.role,
    this.division,
    this.section,
    this.permissions,
    this.hrmsLinked,
    this.faceRegistered,
    this.verificationStatus,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];

    roleData = json['role_data'] != null
        ? RoleData.fromJson(json['role_data'])
        : null;
    lastLogin = json['last_login'];
    username = json['username'];
    fullName = "${json['first_name']} ${json['last_name']}";
    name = json['name'];
    designation =
        json['designation'] ??
        json['Designation'] ??
        json['designation_name'] ??
        (roleData?.name);
    profileStatus = json['profile_status'];
    isDelete = json['is_delete'];
    profileImage = json['profile_image'];
    isStaff = json['is_staff'];
    isSuperuser = json['is_superuser'];
    email = json['email'];
    mobileNumber = json['mobile_number'];
    resetCode = json['reset_code'];
    resetCodeExpiry = json['reset_code_expiry'];
    initialReset = json['initial_reset'];
    nic = json['nic'];
    isHqUser = json['is_hq_user'];
    empid = json['emp_id']?.toString() ?? json['empid']?.toString();
    sapid =
        json['sap_id']?.toString() ??
        json['SAPID']?.toString() ??
        json['sapId']?.toString() ??
        json['SAP_ID']?.toString();
    role = json['role'];
    division = json['division'];
    section =
        json['section_id'] ??
        json['section'] ??
        json['Section_ID'] ??
        json['sectionId'] ??
        json['SectionID'];
    permissions = json['permissions'] != null
        ? Permissions.fromJson(json['permissions'])
        : null;
    hrmsLinked = json['hrms_linked'];
    // Only the keys that name it: a bare "status" is the response's own.
    verificationStatus =
        json['verification_status']?.toString() ??
        json['Verification_Status']?.toString() ??
        json['verificationStatus']?.toString();
    final dynamic faceVal =
        json['face_registered'] ?? json['face'] ?? json['is_face'];
    if (faceVal is bool) {
      faceRegistered = faceVal;
    } else if (faceVal is int) {
      faceRegistered = faceVal != 0;
    } else if (faceVal is String) {
      faceRegistered = faceVal.toLowerCase() == 'true' || faceVal == '1';
    } else {
      faceRegistered = false;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    List<String> nameParts = fullName?.trim().split(' ') ?? [];
    data['id'] = id;

    if (roleData != null) {
      data['role_data'] = roleData!.toJson();
    }
    data['last_login'] = lastLogin;
    data['username'] = username;
    data['name'] = name;
    data['first_name'] = nameParts.isNotEmpty ? nameParts.first : '';
    data['last_name'] = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '';
    data['profile_status'] = profileStatus;
    data['is_delete'] = isDelete;
    data['profile_image'] = profileImage;
    data['is_staff'] = isStaff;
    data['is_superuser'] = isSuperuser;
    data['email'] = email;
    data['mobile_number'] = mobileNumber;
    data['reset_code'] = resetCode;
    data['reset_code_expiry'] = resetCodeExpiry;
    data['initial_reset'] = initialReset;
    data['nic'] = nic;
    data['is_hq_user'] = isHqUser;
    data['emp_id'] = empid;
    data['sap_id'] = sapid;
    data['role'] = role;
    data['division'] = division;
    data['section_id'] = section;
    data['designation'] = designation;
    if (permissions != null) {
      data['permissions'] = permissions!.toJson();
    }
    data['hrms_linked'] = hrmsLinked;
    data['face_registered'] = faceRegistered ?? false;
    data['verification_status'] = verificationStatus;

    return data;
  }

  User copyWith({
    int? id,
    RoleData? roleData,
    String? lastLogin,
    String? username,
    String? name,
    String? fullName,
    String? designation,
    int? profileStatus,
    bool? isDelete,
    String? profileImage,
    bool? isStaff,
    bool? isSuperuser,
    String? email,
    String? mobileNumber,
    String? resetCode,
    String? resetCodeExpiry,
    bool? initialReset,
    String? nic,
    bool? isHqUser,
    String? empid,
    String? sapid,
    int? role,
    int? division,
    int? sectionId,
    Permissions? permissions,
    bool? hrmsLinked,
    bool? faceRegistered,
    String? verificationStatus,
  }) {
    return User(
      id: id ?? this.id,
      roleData: roleData ?? this.roleData,
      lastLogin: lastLogin ?? this.lastLogin,
      username: username ?? this.username,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      designation: designation ?? this.designation,
      profileStatus: profileStatus ?? this.profileStatus,
      isDelete: isDelete ?? this.isDelete,
      profileImage: profileImage ?? this.profileImage,
      isStaff: isStaff ?? this.isStaff,
      isSuperuser: isSuperuser ?? this.isSuperuser,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      resetCode: resetCode ?? this.resetCode,
      resetCodeExpiry: resetCodeExpiry ?? this.resetCodeExpiry,
      initialReset: initialReset ?? this.initialReset,
      nic: nic ?? this.nic,
      isHqUser: isHqUser ?? this.isHqUser,
      empid: empid ?? this.empid,
      sapid: sapid ?? this.sapid,
      role: role ?? this.role,
      division: division ?? this.division,
      section: sectionId ?? section,
      permissions: permissions ?? this.permissions,
      hrmsLinked: hrmsLinked ?? this.hrmsLinked,
      faceRegistered: faceRegistered ?? this.faceRegistered,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }
}

class RoleData {
  int? id;
  String? name;
  String? codeName;

  RoleData({this.id, this.name, this.codeName});

  RoleData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    codeName = json['code_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['code_name'] = codeName;
    return data;
  }

  RoleData copyWith({int? id, String? name, String? codeName}) {
    return RoleData(
      id: id ?? this.id,
      name: name ?? this.name,
      codeName: codeName ?? this.codeName,
    );
  }
}

class Permissions {
  bool? createUser;
  bool? readUser;
  bool? updateUser;
  bool? deleteUser;
  bool? enableUser;
  bool? showUser;
  bool? createRole;
  bool? readRole;
  bool? updateRole;
  bool? deleteRole;
  bool? showRole;
  bool? showLogs;
  bool? createLogs;
  bool? readLogs;
  bool? updateLogs;
  bool? deleteLogs;
  bool? showTrackingDashboard;
  bool? showMonitoringDashboard;
  bool? createTracker;
  bool? readTracker;
  bool? updateTracker;
  bool? deleteTracker;
  bool? showTracker;
  bool? createGeofence;
  bool? readGeofence;
  bool? updateGeofence;
  bool? deleteGeofence;
  bool? showGeofence;
  bool? createEvent;
  bool? readEvent;
  bool? updateEvent;
  bool? deleteEvent;
  bool? readNotification;
  bool? readDlogs;
  bool? showDlogs;
  bool? createCoach;
  bool? readCoach;
  bool? updateCoach;
  bool? deleteCoach;
  bool? showCoach;
  bool? createPowerVan;
  bool? readPowerVan;
  bool? updatePowerVan;
  bool? deletePowerVan;
  bool? showPowerVan;
  bool? createEngine;
  bool? readEngine;
  bool? updateEngine;
  bool? deleteEngine;
  bool? showEngine;
  bool? assignTracker;
  bool? createWagon;
  bool? readWagon;
  bool? updateWagon;
  bool? deleteWagon;
  bool? showWagon;
  bool? createStation;
  bool? readStation;
  bool? updateStation;
  bool? deleteStation;
  bool? showStation;
  bool? createTrain;
  bool? readTrain;
  bool? updateTrain;
  bool? deleteTrain;
  bool? showTrain;
  bool? createCoachType;
  bool? readCoachType;
  bool? updateCoachType;
  bool? deleteCoachType;
  bool? showCoachType;
  bool? createVanType;
  bool? readVanType;
  bool? updateVanType;
  bool? deleteVanType;
  bool? showVanType;
  bool? createWagonType;
  bool? readWagonType;
  bool? updateWagonType;
  bool? deleteWagonType;
  bool? showWagonType;
  bool? createLocoType;
  bool? readLocoType;
  bool? updateLocoType;
  bool? deleteLocoType;
  bool? showLocoType;
  bool? createTrainComposition;
  bool? readTrainComposition;
  bool? updateTrainComposition;
  bool? deleteTrainComposition;
  bool? showTrainComposition;
  bool? approveTrainComposition;
  bool? acknowledgeTrainComposition;
  bool? createTrainAdjustment;
  bool? readTrainAdjustment;
  bool? updateTrainAdjustment;
  bool? deleteTrainAdjustment;
  bool? approveTrainAdjustment;
  bool? createTimeTable;
  bool? readTimeTable;
  bool? updateTimeTable;
  bool? deleteTimeTable;
  bool? showTimeTable;
  bool? approveTimeTable;
  bool? createLine;
  bool? readLine;
  bool? updateLine;
  bool? deleteLine;
  bool? createSection;
  bool? readSection;
  bool? updateSection;
  bool? deleteSection;
  bool? createSectionRailType;
  bool? readSectionRailType;
  bool? updateSectionRailType;
  bool? deleteSectionRailType;
  bool? createEngineeringRestriction;
  bool? readEngineeringRestriction;
  bool? updateEngineeringRestriction;
  bool? deleteEngineeringRestriction;
  bool? createPermanentSpeedRestriction;
  bool? readPermanentSpeedRestriction;
  bool? updatePermanentSpeedRestriction;
  bool? deletePermanentSpeedRestriction;
  bool? createSectionStation;
  bool? readSectionStation;
  bool? updateSectionStation;
  bool? deleteSectionStation;
  bool? createInterventionRecord;
  bool? readInterventionRecord;
  bool? updateInterventionRecord;
  bool? deleteInterventionRecord;
  bool? createLevelCrossing;
  bool? readLevelCrossing;
  bool? updateLevelCrossing;
  bool? deleteLevelCrossing;
  bool? createBridge;
  bool? readBridge;
  bool? updateBridge;
  bool? deleteBridge;
  bool? createStationLocation;
  bool? readStationLocation;
  bool? updateStationLocation;
  bool? deleteStationLocation;
  bool? createStationDetail;
  bool? readStationDetail;
  bool? updateStationDetail;
  bool? deleteStationDetail;
  bool? showGovernanceDashboard;
  bool? showInfrastructureDashboard;
  bool? showRollingStockDashboard;
  bool? showOperationsDashboard;
  bool? showFinancialDashboard;
  bool? createCoachClass;
  bool? readCoachClass;
  bool? updateCoachClass;
  bool? deleteCoachClass;
  bool? showCoachClass;
  bool? createTrainSchedule;
  bool? readTrainSchedule;
  bool? updateTrainSchedule;
  bool? deleteTrainSchedule;
  bool? createTunnel;
  bool? readTunnel;
  bool? updateTunnel;
  bool? deleteTunnel;
  bool? createTrackMachine;
  bool? readTrackMachine;
  bool? updateTrackMachine;
  bool? deleteTrackMachine;
  bool? createTelecom;
  bool? readTelecom;
  bool? updateTelecom;
  bool? deleteTelecom;
  bool? createSignalInterlocking;
  bool? readSignalInterlocking;
  bool? updateSignalInterlocking;
  bool? deleteSignalInterlocking;
  bool? showTracksAndBuildings;
  bool? showBridge;
  bool? showLevelCrossing;
  bool? showWimAnalytics;
  bool? readWimAnalytics;
  bool? showWimArchivedDashboard;
  bool? readWimArchivedDashboard;
  bool? showWimTransactionHistory;
  bool? readWimTransactionHistory;
  bool? showFuelManagement;
  bool? readFuelManagement;
  bool? createFuelManagement;
  bool? updateFuelManagement;
  bool? deleteFuelManagement;
  bool? showTrainScheduling;
  bool? readTrainScheduling;

  Permissions({
    this.createUser,
    this.readUser,
    this.updateUser,
    this.deleteUser,
    this.enableUser,
    this.showUser,
    this.createRole,
    this.readRole,
    this.updateRole,
    this.deleteRole,
    this.showRole,
    this.showLogs,
    this.createLogs,
    this.readLogs,
    this.updateLogs,
    this.deleteLogs,
    this.showTrackingDashboard,
    this.showMonitoringDashboard,
    this.createTracker,
    this.readTracker,
    this.updateTracker,
    this.deleteTracker,
    this.showTracker,
    this.createGeofence,
    this.readGeofence,
    this.updateGeofence,
    this.deleteGeofence,
    this.showGeofence,
    this.createEvent,
    this.readEvent,
    this.updateEvent,
    this.deleteEvent,
    this.readNotification,
    this.readDlogs,
    this.showDlogs,
    this.createCoach,
    this.readCoach,
    this.updateCoach,
    this.deleteCoach,
    this.showCoach,
    this.createPowerVan,
    this.readPowerVan,
    this.updatePowerVan,
    this.deletePowerVan,
    this.showPowerVan,
    this.createEngine,
    this.readEngine,
    this.updateEngine,
    this.deleteEngine,
    this.showEngine,
    this.assignTracker,
    this.createWagon,
    this.readWagon,
    this.updateWagon,
    this.deleteWagon,
    this.showWagon,
    this.createStation,
    this.readStation,
    this.updateStation,
    this.deleteStation,
    this.showStation,
    this.createTrain,
    this.readTrain,
    this.updateTrain,
    this.deleteTrain,
    this.showTrain,
    this.createCoachType,
    this.readCoachType,
    this.updateCoachType,
    this.deleteCoachType,
    this.showCoachType,
    this.createVanType,
    this.readVanType,
    this.updateVanType,
    this.deleteVanType,
    this.showVanType,
    this.createWagonType,
    this.readWagonType,
    this.updateWagonType,
    this.deleteWagonType,
    this.showWagonType,
    this.createLocoType,
    this.readLocoType,
    this.updateLocoType,
    this.deleteLocoType,
    this.showLocoType,
    this.createTrainComposition,
    this.readTrainComposition,
    this.updateTrainComposition,
    this.deleteTrainComposition,
    this.showTrainComposition,
    this.approveTrainComposition,
    this.acknowledgeTrainComposition,
    this.createTrainAdjustment,
    this.readTrainAdjustment,
    this.updateTrainAdjustment,
    this.deleteTrainAdjustment,
    this.approveTrainAdjustment,
    this.createTimeTable,
    this.readTimeTable,
    this.updateTimeTable,
    this.deleteTimeTable,
    this.showTimeTable,
    this.approveTimeTable,
    this.createLine,
    this.readLine,
    this.updateLine,
    this.deleteLine,
    this.createSection,
    this.readSection,
    this.updateSection,
    this.deleteSection,
    this.createSectionRailType,
    this.readSectionRailType,
    this.updateSectionRailType,
    this.deleteSectionRailType,
    this.createEngineeringRestriction,
    this.readEngineeringRestriction,
    this.updateEngineeringRestriction,
    this.deleteEngineeringRestriction,
    this.createPermanentSpeedRestriction,
    this.readPermanentSpeedRestriction,
    this.updatePermanentSpeedRestriction,
    this.deletePermanentSpeedRestriction,
    this.createSectionStation,
    this.readSectionStation,
    this.updateSectionStation,
    this.deleteSectionStation,
    this.createInterventionRecord,
    this.readInterventionRecord,
    this.updateInterventionRecord,
    this.deleteInterventionRecord,
    this.createLevelCrossing,
    this.readLevelCrossing,
    this.updateLevelCrossing,
    this.deleteLevelCrossing,
    this.createBridge,
    this.readBridge,
    this.updateBridge,
    this.deleteBridge,
    this.createStationLocation,
    this.readStationLocation,
    this.updateStationLocation,
    this.deleteStationLocation,
    this.createStationDetail,
    this.readStationDetail,
    this.updateStationDetail,
    this.deleteStationDetail,
    this.showGovernanceDashboard,
    this.showInfrastructureDashboard,
    this.showRollingStockDashboard,
    this.showOperationsDashboard,
    this.showFinancialDashboard,
    this.createCoachClass,
    this.readCoachClass,
    this.updateCoachClass,
    this.deleteCoachClass,
    this.showCoachClass,
    this.createTrainSchedule,
    this.readTrainSchedule,
    this.updateTrainSchedule,
    this.deleteTrainSchedule,
    this.createTunnel,
    this.readTunnel,
    this.updateTunnel,
    this.deleteTunnel,
    this.createTrackMachine,
    this.readTrackMachine,
    this.updateTrackMachine,
    this.deleteTrackMachine,
    this.createTelecom,
    this.readTelecom,
    this.updateTelecom,
    this.deleteTelecom,
    this.createSignalInterlocking,
    this.readSignalInterlocking,
    this.updateSignalInterlocking,
    this.deleteSignalInterlocking,
    this.showTracksAndBuildings,
    this.showBridge,
    this.showLevelCrossing,
    this.showWimAnalytics,
    this.readWimAnalytics,
    this.showWimArchivedDashboard,
    this.readWimArchivedDashboard,
    this.showWimTransactionHistory,
    this.readWimTransactionHistory,
    this.showFuelManagement,
    this.readFuelManagement,
    this.createFuelManagement,
    this.updateFuelManagement,
    this.deleteFuelManagement,
    this.showTrainScheduling,
    this.readTrainScheduling,
  });

  Permissions.fromJson(Map<String, dynamic> json) {
    createUser = json['create_user'];
    readUser = json['read_user'];
    updateUser = json['update_user'];
    deleteUser = json['delete_user'];
    enableUser = json['enable_user'];
    showUser = json['show_user'];
    createRole = json['create_role'];
    readRole = json['read_role'];
    updateRole = json['update_role'];
    deleteRole = json['delete_role'];
    showRole = json['show_role'];
    showLogs = json['show_logs'];
    createLogs = json['create_logs'];
    readLogs = json['read_logs'];
    updateLogs = json['update_logs'];
    deleteLogs = json['delete_logs'];
    showTrackingDashboard = json['show_tracking_dashboard'];
    showMonitoringDashboard = json['show_monitoring_dashboard'];
    createTracker = json['create_tracker'];
    readTracker = json['read_tracker'];
    updateTracker = json['update_tracker'];
    deleteTracker = json['delete_tracker'];
    showTracker = json['show_tracker'];
    createGeofence = json['create_geofence'];
    readGeofence = json['read_geofence'];
    updateGeofence = json['update_geofence'];
    deleteGeofence = json['delete_geofence'];
    showGeofence = json['show_geofence'];
    createEvent = json['create_event'];
    readEvent = json['read_event'];
    updateEvent = json['update_event'];
    deleteEvent = json['delete_event'];
    readNotification = json['read_notification'];
    readDlogs = json['read_dlogs'];
    showDlogs = json['show_dlogs'];
    createCoach = json['create_coach'];
    readCoach = json['read_coach'];
    updateCoach = json['update_coach'];
    deleteCoach = json['delete_coach'];
    showCoach = json['show_coach'];
    createPowerVan = json['create_power_van'];
    readPowerVan = json['read_power_van'];
    updatePowerVan = json['update_power_van'];
    deletePowerVan = json['delete_power_van'];
    showPowerVan = json['show_power_van'];
    createEngine = json['create_engine'];
    readEngine = json['read_engine'];
    updateEngine = json['update_engine'];
    deleteEngine = json['delete_engine'];
    showEngine = json['show_engine'];
    assignTracker = json['assign_tracker'];
    createWagon = json['create_wagon'];
    readWagon = json['read_wagon'];
    updateWagon = json['update_wagon'];
    deleteWagon = json['delete_wagon'];
    showWagon = json['show_wagon'];
    createStation = json['create_station'];
    readStation = json['read_station'];
    updateStation = json['update_station'];
    deleteStation = json['delete_station'];
    showStation = json['show_station'];
    createTrain = json['create_train'];
    readTrain = json['read_train'];
    updateTrain = json['update_train'];
    deleteTrain = json['delete_train'];
    showTrain = json['show_train'];
    createCoachType = json['create_coach_type'];
    readCoachType = json['read_coach_type'];
    updateCoachType = json['update_coach_type'];
    deleteCoachType = json['delete_coach_type'];
    showCoachType = json['show_coach_type'];
    createVanType = json['create_van_type'];
    readVanType = json['read_van_type'];
    updateVanType = json['update_van_type'];
    deleteVanType = json['delete_van_type'];
    showVanType = json['show_van_type'];
    createWagonType = json['create_wagon_type'];
    readWagonType = json['read_wagon_type'];
    updateWagonType = json['update_wagon_type'];
    deleteWagonType = json['delete_wagon_type'];
    showWagonType = json['show_wagon_type'];
    createLocoType = json['create_loco_type'];
    readLocoType = json['read_loco_type'];
    updateLocoType = json['update_loco_type'];
    deleteLocoType = json['delete_loco_type'];
    showLocoType = json['show_loco_type'];
    createTrainComposition = json['create_train_composition'];
    readTrainComposition = json['read_train_composition'];
    updateTrainComposition = json['update_train_composition'];
    deleteTrainComposition = json['delete_train_composition'];
    showTrainComposition = json['show_train_composition'];
    approveTrainComposition = json['approve_train_composition'];
    acknowledgeTrainComposition = json['acknowledge_train_composition'];
    createTrainAdjustment = json['create_train_adjustment'];
    readTrainAdjustment = json['read_train_adjustment'];
    updateTrainAdjustment = json['update_train_adjustment'];
    deleteTrainAdjustment = json['delete_train_adjustment'];
    approveTrainAdjustment = json['approve_train_adjustment'];
    createTimeTable = json['create_time_table'];
    readTimeTable = json['read_time_table'];
    updateTimeTable = json['update_time_table'];
    deleteTimeTable = json['delete_time_table'];
    showTimeTable = json['show_time_table'];
    approveTimeTable = json['approve_time_table'];
    createLine = json['create_line'];
    readLine = json['read_line'];
    updateLine = json['update_line'];
    deleteLine = json['delete_line'];
    createSection = json['create_section'];
    readSection = json['read_section'];
    updateSection = json['update_section'];
    deleteSection = json['delete_section'];
    createSectionRailType = json['create_section_rail_type'];
    readSectionRailType = json['read_section_rail_type'];
    updateSectionRailType = json['update_section_rail_type'];
    deleteSectionRailType = json['delete_section_rail_type'];
    createEngineeringRestriction = json['create_engineering_restriction'];
    readEngineeringRestriction = json['read_engineering_restriction'];
    updateEngineeringRestriction = json['update_engineering_restriction'];
    deleteEngineeringRestriction = json['delete_engineering_restriction'];
    createPermanentSpeedRestriction =
        json['create_permanent_speed_restriction'];
    readPermanentSpeedRestriction = json['read_permanent_speed_restriction'];
    updatePermanentSpeedRestriction =
        json['update_permanent_speed_restriction'];
    deletePermanentSpeedRestriction =
        json['delete_permanent_speed_restriction'];
    createSectionStation = json['create_section_station'];
    readSectionStation = json['read_section_station'];
    updateSectionStation = json['update_section_station'];
    deleteSectionStation = json['delete_section_station'];
    createInterventionRecord = json['create_intervention_record'];
    readInterventionRecord = json['read_intervention_record'];
    updateInterventionRecord = json['update_intervention_record'];
    deleteInterventionRecord = json['delete_intervention_record'];
    createLevelCrossing = json['create_level_crossing'];
    readLevelCrossing = json['read_level_crossing'];
    updateLevelCrossing = json['update_level_crossing'];
    deleteLevelCrossing = json['delete_level_crossing'];
    createBridge = json['create_bridge'];
    readBridge = json['read_bridge'];
    updateBridge = json['update_bridge'];
    deleteBridge = json['delete_bridge'];
    createStationLocation = json['create_station_location'];
    readStationLocation = json['read_station_location'];
    updateStationLocation = json['update_station_location'];
    deleteStationLocation = json['delete_station_location'];
    createStationDetail = json['create_station_detail'];
    readStationDetail = json['read_station_detail'];
    updateStationDetail = json['update_station_detail'];
    deleteStationDetail = json['delete_station_detail'];
    showGovernanceDashboard = json['show_Governance_dashboard'];
    showInfrastructureDashboard = json['show_infrastructure_dashboard'];
    showRollingStockDashboard = json['show_RollingStock_dashboard'];
    showOperationsDashboard = json['show_Operations_dashboard'];
    showFinancialDashboard = json['show_Financial_dashboard'];
    createCoachClass = json['create_coach_class'];
    readCoachClass = json['read_coach_class'];
    updateCoachClass = json['update_coach_class'];
    deleteCoachClass = json['delete_coach_class'];
    showCoachClass = json['show_coach_class'];
    createTrainSchedule = json['create_train_schedule'];
    readTrainSchedule = json['read_train_schedule'];
    updateTrainSchedule = json['update_train_schedule'];
    deleteTrainSchedule = json['delete_train_schedule'];
    createTunnel = json['create_tunnel'];
    readTunnel = json['read_tunnel'];
    updateTunnel = json['update_tunnel'];
    deleteTunnel = json['delete_tunnel'];
    createTrackMachine = json['create_track_machine'];
    readTrackMachine = json['read_track_machine'];
    updateTrackMachine = json['update_track_machine'];
    deleteTrackMachine = json['delete_track_machine'];
    createTelecom = json['create_telecom'];
    readTelecom = json['read_telecom'];
    updateTelecom = json['update_telecom'];
    deleteTelecom = json['delete_telecom'];
    createSignalInterlocking = json['create_signal_interlocking'];
    readSignalInterlocking = json['read_signal_interlocking'];
    updateSignalInterlocking = json['update_signal_interlocking'];
    deleteSignalInterlocking = json['delete_signal_interlocking'];
    showTracksAndBuildings = json['show_tracks_and_buildings'];
    showBridge = json['show_bridge'];
    showLevelCrossing = json['show_level_crossing'];
    showWimAnalytics = json['show_wim_analytics'];
    readWimAnalytics = json['read_wim_analytics'];
    showWimArchivedDashboard = json['show_wim_archived_dashboard'];
    readWimArchivedDashboard = json['read_wim_archived_dashboard'];
    showWimTransactionHistory = json['show_wim_transaction_history'];
    readWimTransactionHistory = json['read_wim_transaction_history'];
    showFuelManagement = json['show_fuel_management'];
    readFuelManagement = json['read_fuel_management'];
    createFuelManagement = json['create_fuel_management'];
    updateFuelManagement = json['update_fuel_management'];
    deleteFuelManagement = json['delete_fuel_management'];
    showTrainScheduling = json['show_train_scheduling'];
    readTrainScheduling = json['read_train_scheduling'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['create_user'] = createUser;
    data['read_user'] = readUser;
    data['update_user'] = updateUser;
    data['delete_user'] = deleteUser;
    data['enable_user'] = enableUser;
    data['show_user'] = showUser;
    data['create_role'] = createRole;
    data['read_role'] = readRole;
    data['update_role'] = updateRole;
    data['delete_role'] = deleteRole;
    data['show_role'] = showRole;
    data['show_logs'] = showLogs;
    data['create_logs'] = createLogs;
    data['read_logs'] = readLogs;
    data['update_logs'] = updateLogs;
    data['delete_logs'] = deleteLogs;
    data['show_tracking_dashboard'] = showTrackingDashboard;
    data['show_monitoring_dashboard'] = showMonitoringDashboard;
    data['create_tracker'] = createTracker;
    data['read_tracker'] = readTracker;
    data['update_tracker'] = updateTracker;
    data['delete_tracker'] = deleteTracker;
    data['show_tracker'] = showTracker;
    data['create_geofence'] = createGeofence;
    data['read_geofence'] = readGeofence;
    data['update_geofence'] = updateGeofence;
    data['delete_geofence'] = deleteGeofence;
    data['show_geofence'] = showGeofence;
    data['create_event'] = createEvent;
    data['read_event'] = readEvent;
    data['update_event'] = updateEvent;
    data['delete_event'] = deleteEvent;
    data['read_notification'] = readNotification;
    data['read_dlogs'] = readDlogs;
    data['show_dlogs'] = showDlogs;
    data['create_coach'] = createCoach;
    data['read_coach'] = readCoach;
    data['update_coach'] = updateCoach;
    data['delete_coach'] = deleteCoach;
    data['show_coach'] = showCoach;
    data['create_power_van'] = createPowerVan;
    data['read_power_van'] = readPowerVan;
    data['update_power_van'] = updatePowerVan;
    data['delete_power_van'] = deletePowerVan;
    data['show_power_van'] = showPowerVan;
    data['create_engine'] = createEngine;
    data['read_engine'] = readEngine;
    data['update_engine'] = updateEngine;
    data['delete_engine'] = deleteEngine;
    data['show_engine'] = showEngine;
    data['assign_tracker'] = assignTracker;
    data['create_wagon'] = createWagon;
    data['read_wagon'] = readWagon;
    data['update_wagon'] = updateWagon;
    data['delete_wagon'] = deleteWagon;
    data['show_wagon'] = showWagon;
    data['create_station'] = createStation;
    data['read_station'] = readStation;
    data['update_station'] = updateStation;
    data['delete_station'] = deleteStation;
    data['show_station'] = showStation;
    data['create_train'] = createTrain;
    data['read_train'] = readTrain;
    data['update_train'] = updateTrain;
    data['delete_train'] = deleteTrain;
    data['show_train'] = showTrain;
    data['create_coach_type'] = createCoachType;
    data['read_coach_type'] = readCoachType;
    data['update_coach_type'] = updateCoachType;
    data['delete_coach_type'] = deleteCoachType;
    data['show_coach_type'] = showCoachType;
    data['create_van_type'] = createVanType;
    data['read_van_type'] = readVanType;
    data['update_van_type'] = updateVanType;
    data['delete_van_type'] = deleteVanType;
    data['show_van_type'] = showVanType;
    data['create_wagon_type'] = createWagonType;
    data['read_wagon_type'] = readWagonType;
    data['update_wagon_type'] = updateWagonType;
    data['delete_wagon_type'] = deleteWagonType;
    data['show_wagon_type'] = showWagonType;
    data['create_loco_type'] = createLocoType;
    data['read_loco_type'] = readLocoType;
    data['update_loco_type'] = updateLocoType;
    data['delete_loco_type'] = deleteLocoType;
    data['show_loco_type'] = showLocoType;
    data['create_train_composition'] = createTrainComposition;
    data['read_train_composition'] = readTrainComposition;
    data['update_train_composition'] = updateTrainComposition;
    data['delete_train_composition'] = deleteTrainComposition;
    data['show_train_composition'] = showTrainComposition;
    data['approve_train_composition'] = approveTrainComposition;
    data['acknowledge_train_composition'] = acknowledgeTrainComposition;
    data['create_train_adjustment'] = createTrainAdjustment;
    data['read_train_adjustment'] = readTrainAdjustment;
    data['update_train_adjustment'] = updateTrainAdjustment;
    data['delete_train_adjustment'] = deleteTrainAdjustment;
    data['approve_train_adjustment'] = approveTrainAdjustment;
    data['create_time_table'] = createTimeTable;
    data['read_time_table'] = readTimeTable;
    data['update_time_table'] = updateTimeTable;
    data['delete_time_table'] = deleteTimeTable;
    data['show_time_table'] = showTimeTable;
    data['approve_time_table'] = approveTimeTable;
    data['create_line'] = createLine;
    data['read_line'] = readLine;
    data['update_line'] = updateLine;
    data['delete_line'] = deleteLine;
    data['create_section'] = createSection;
    data['read_section'] = readSection;
    data['update_section'] = updateSection;
    data['delete_section'] = deleteSection;
    data['create_section_rail_type'] = createSectionRailType;
    data['read_section_rail_type'] = readSectionRailType;
    data['update_section_rail_type'] = updateSectionRailType;
    data['delete_section_rail_type'] = deleteSectionRailType;
    data['create_engineering_restriction'] = createEngineeringRestriction;
    data['read_engineering_restriction'] = readEngineeringRestriction;
    data['update_engineering_restriction'] = updateEngineeringRestriction;
    data['delete_engineering_restriction'] = deleteEngineeringRestriction;
    data['create_permanent_speed_restriction'] =
        createPermanentSpeedRestriction;
    data['read_permanent_speed_restriction'] = readPermanentSpeedRestriction;
    data['update_permanent_speed_restriction'] =
        updatePermanentSpeedRestriction;
    data['delete_permanent_speed_restriction'] =
        deletePermanentSpeedRestriction;
    data['create_section_station'] = createSectionStation;
    data['read_section_station'] = readSectionStation;
    data['update_section_station'] = updateSectionStation;
    data['delete_section_station'] = deleteSectionStation;
    data['create_intervention_record'] = createInterventionRecord;
    data['read_intervention_record'] = readInterventionRecord;
    data['update_intervention_record'] = updateInterventionRecord;
    data['delete_intervention_record'] = deleteInterventionRecord;
    data['create_level_crossing'] = createLevelCrossing;
    data['read_level_crossing'] = readLevelCrossing;
    data['update_level_crossing'] = updateLevelCrossing;
    data['delete_level_crossing'] = deleteLevelCrossing;
    data['create_bridge'] = createBridge;
    data['read_bridge'] = readBridge;
    data['update_bridge'] = updateBridge;
    data['delete_bridge'] = deleteBridge;
    data['create_station_location'] = createStationLocation;
    data['read_station_location'] = readStationLocation;
    data['update_station_location'] = updateStationLocation;
    data['delete_station_location'] = deleteStationLocation;
    data['create_station_detail'] = createStationDetail;
    data['read_station_detail'] = readStationDetail;
    data['update_station_detail'] = updateStationDetail;
    data['delete_station_detail'] = deleteStationDetail;
    data['show_Governance_dashboard'] = showGovernanceDashboard;
    data['show_infrastructure_dashboard'] = showInfrastructureDashboard;
    data['show_RollingStock_dashboard'] = showRollingStockDashboard;
    data['show_Operations_dashboard'] = showOperationsDashboard;
    data['show_Financial_dashboard'] = showFinancialDashboard;
    data['create_coach_class'] = createCoachClass;
    data['read_coach_class'] = readCoachClass;
    data['update_coach_class'] = updateCoachClass;
    data['delete_coach_class'] = deleteCoachClass;
    data['show_coach_class'] = showCoachClass;
    data['create_train_schedule'] = createTrainSchedule;
    data['read_train_schedule'] = readTrainSchedule;
    data['update_train_schedule'] = updateTrainSchedule;
    data['delete_train_schedule'] = deleteTrainSchedule;
    data['create_tunnel'] = createTunnel;
    data['read_tunnel'] = readTunnel;
    data['update_tunnel'] = updateTunnel;
    data['delete_tunnel'] = deleteTunnel;
    data['create_track_machine'] = createTrackMachine;
    data['read_track_machine'] = readTrackMachine;
    data['update_track_machine'] = updateTrackMachine;
    data['delete_track_machine'] = deleteTrackMachine;
    data['create_telecom'] = createTelecom;
    data['read_telecom'] = readTelecom;
    data['update_telecom'] = updateTelecom;
    data['delete_telecom'] = deleteTelecom;
    data['create_signal_interlocking'] = createSignalInterlocking;
    data['read_signal_interlocking'] = readSignalInterlocking;
    data['update_signal_interlocking'] = updateSignalInterlocking;
    data['delete_signal_interlocking'] = deleteSignalInterlocking;
    data['show_tracks_and_buildings'] = showTracksAndBuildings;
    data['show_bridge'] = showBridge;
    data['show_level_crossing'] = showLevelCrossing;
    data['show_wim_analytics'] = showWimAnalytics;
    data['read_wim_analytics'] = readWimAnalytics;
    data['show_wim_archived_dashboard'] = showWimArchivedDashboard;
    data['read_wim_archived_dashboard'] = readWimArchivedDashboard;
    data['show_wim_transaction_history'] = showWimTransactionHistory;
    data['read_wim_transaction_history'] = readWimTransactionHistory;
    data['show_fuel_management'] = showFuelManagement;
    data['read_fuel_management'] = readFuelManagement;
    data['create_fuel_management'] = createFuelManagement;
    data['update_fuel_management'] = updateFuelManagement;
    data['delete_fuel_management'] = deleteFuelManagement;
    data['show_train_scheduling'] = showTrainScheduling;
    data['read_train_scheduling'] = readTrainScheduling;
    return data;
  }
}

class Tokens {
  String? access;
  String? refresh;
  String? csrf;

  Tokens({this.access, this.refresh, this.csrf});

  Tokens.fromJson(Map<String, dynamic> json) {
    access = json['access'];
    refresh = json['refresh'];
    csrf = json['csrf'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['access'] = access;
    data['refresh'] = refresh;
    data['csrf'] = csrf;
    return data;
  }
}
