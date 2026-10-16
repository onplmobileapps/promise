class AccidentModel {
  String? status;
  Accident? accident;

  AccidentModel({this.status, this.accident});

  AccidentModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    accident = json['accident'] != null
        ? Accident.fromJson(json['accident'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    if (accident != null) {
      data['accident'] = accident!.toJson();
    }
    return data;
  }
}

class Accident {
  int? id;
  String? accidentId;
  String? reportedAt;
  int? reporter;
  String? reporterName;
  String? reportedLat;
  String? reportedLog;
  String? kilometerNumber;
  String? accidentDateTime;
  int? accidentClass;
  String? accidentClassCode;
  String? accidentClassMeaning;
  String? locoLat;
  String? locoLon;
  int? trainId;
  String? trainName;
  String? trainNumber;
  String? trainDirection;
  String? trainType;
  String? trainEffectiveDate;
  int? division;
  String? divisionName;
  String? divisionCode;
  int? section;
  String? sectionName;
  String? blockSection;
  String? blockSectionName;
  String? blockSectionLabel;
  String? blockSectionFromCode;
  String? blockSectionToCode;
  String? blockSectionFromStationName;
  String? blockSectionToStationName;
  double? blockSectionFromLat;
  double? blockSectionFromLon;
  double? blockSectionToLat;
  double? blockSectionToLon;
  List<dynamic>? blockSectionCoordinates;
  int? line;
  String? lineName;
  int? nearestStation;
  String? nearestStationName;
  String? nearestStationCode;
  int? lastCrossedStation;
  String? lastCrossedStationName;
  String? lastCrossedStationCode;
  String? locomotiveNumber;
  List<CoachesWagons>? coachesWagons;
  int? originStation;
  String? originStationName;
  int? destinationStation;
  String? destinationStationName;
  String? severity;
  String? status;
  String? peopleInjured;
  int? injuredCount;
  bool? trainDerailed;
  bool? hasFire;
  String? dangerousGoods;
  String? description;
  bool? isApproved;
  String? approvedAt;
  String? approvedBy;
  String? createdAt;
  String? updatedAt;
  List<Photos>? photos;
  List<Timeline>? timeline;

  Accident({
    this.id,
    this.accidentId,
    this.reportedAt,
    this.reporter,
    this.reporterName,
    this.reportedLat,
    this.reportedLog,
    this.kilometerNumber,
    this.accidentDateTime,
    this.accidentClass,
    this.accidentClassCode,
    this.accidentClassMeaning,
    this.locoLat,
    this.locoLon,
    this.trainId,
    this.trainName,
    this.trainNumber,
    this.trainDirection,
    this.trainType,
    this.trainEffectiveDate,
    this.division,
    this.divisionName,
    this.divisionCode,
    this.section,
    this.sectionName,
    this.blockSection,
    this.blockSectionName,
    this.blockSectionLabel,
    this.blockSectionFromCode,
    this.blockSectionToCode,
    this.blockSectionFromStationName,
    this.blockSectionToStationName,
    this.blockSectionFromLat,
    this.blockSectionFromLon,
    this.blockSectionToLat,
    this.blockSectionToLon,
    this.blockSectionCoordinates,
    this.line,
    this.lineName,
    this.nearestStation,
    this.nearestStationName,
    this.nearestStationCode,
    this.lastCrossedStation,
    this.lastCrossedStationName,
    this.lastCrossedStationCode,
    this.locomotiveNumber,
    this.coachesWagons,
    this.originStation,
    this.originStationName,
    this.destinationStation,
    this.destinationStationName,
    this.severity,
    this.status,
    this.peopleInjured,
    this.injuredCount,
    this.trainDerailed,
    this.hasFire,
    this.dangerousGoods,
    this.description,
    this.isApproved,
    this.approvedAt,
    this.approvedBy,
    this.createdAt,
    this.updatedAt,
    this.photos,
    this.timeline,
  });

  Accident.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    accidentId = json['accident_id'];
    reportedAt = json['reported_at'];
    reporter = json['reporter'];
    reporterName = json['reporter_name'];
    reportedLat = json['reported_lat'];
    reportedLog = json['reported_log'];
    kilometerNumber = json['kilometer_number'];
    accidentDateTime = json['accident_date_time'];
    accidentClass = json['accident_class'];
    accidentClassCode = json['accident_class_code'];
    accidentClassMeaning = json['accident_class_meaning'];
    locoLat = json['loco_lat'];
    locoLon = json['loco_lon'];
    trainId = json['train_id'];
    trainName = json['train_name'];
    trainNumber = json['train_number'];
    trainDirection = json['train_direction'];
    trainType = json['train_type'];
    trainEffectiveDate = json['train_effective_date'];
    division = json['division'];
    divisionName = json['division_name'];
    divisionCode = json['division_code'];
    section = json['section'];
    sectionName = json['section_name'];
    blockSection = json['block_section'];
    blockSectionName = json['block_section_name'];
    blockSectionLabel = json['block_section_label'];
    blockSectionFromCode = json['block_section_from_code'];
    blockSectionToCode = json['block_section_to_code'];
    blockSectionFromStationName = json['block_section_from_station_name'];
    blockSectionToStationName = json['block_section_to_station_name'];
    blockSectionFromLat = json['block_section_from_lat'];
    blockSectionFromLon = json['block_section_from_lon'];
    blockSectionToLat = json['block_section_to_lat'];
    blockSectionToLon = json['block_section_to_lon'];
    if (json['block_section_coordinates'] != null) {
      blockSectionCoordinates = <List>[];
      json['block_section_coordinates'].forEach((v) {
        blockSectionCoordinates!.add(List.from(v));
      });
    }
    line = json['line'];
    lineName = json['line_name'];
    nearestStation = json['nearest_station'];
    nearestStationName = json['nearest_station_name'];
    nearestStationCode = json['nearest_station_code'];
    lastCrossedStation = json['last_crossed_station'];
    lastCrossedStationName = json['last_crossed_station_name'];
    lastCrossedStationCode = json['last_crossed_station_code'];
    locomotiveNumber = json['locomotive_number'];
    if (json['coaches_wagons'] != null) {
      coachesWagons = <CoachesWagons>[];
      json['coaches_wagons'].forEach((v) {
        coachesWagons!.add(CoachesWagons.fromJson(v));
      });
    }
    originStation = json['origin_station'];
    originStationName = json['origin_station_name'];
    destinationStation = json['destination_station'];
    destinationStationName = json['destination_station_name'];
    severity = json['severity'];
    status = json['status'];
    peopleInjured = json['people_injured'];
    injuredCount = json['injured_count'];
    trainDerailed = json['train_derailed'];
    hasFire = json['has_fire'];
    dangerousGoods = json['dangerous_goods'];
    description = json['description'];
    isApproved = json['is_approved'];
    approvedAt = json['approved_at'];
    approvedBy = json['approved_by'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if (json['photos'] != null) {
      photos = <Photos>[];
      json['photos'].forEach((v) {
        photos!.add(Photos.fromJson(v));
      });
    }
    if (json['timeline'] != null) {
      timeline = <Timeline>[];
      json['timeline'].forEach((v) {
        timeline!.add(Timeline.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['accident_id'] = accidentId;
    data['reported_at'] = reportedAt;
    data['reporter'] = reporter;
    data['reporter_name'] = reporterName;
    data['reported_lat'] = reportedLat;
    data['reported_log'] = reportedLog;
    data['kilometer_number'] = kilometerNumber;
    data['accident_date_time'] = accidentDateTime;
    data['accident_class'] = accidentClass;
    data['accident_class_code'] = accidentClassCode;
    data['accident_class_meaning'] = accidentClassMeaning;
    data['loco_lat'] = locoLat;
    data['loco_lon'] = locoLon;
    data['train_id'] = trainId;
    data['train_name'] = trainName;
    data['train_number'] = trainNumber;
    data['train_direction'] = trainDirection;
    data['train_type'] = trainType;
    data['train_effective_date'] = trainEffectiveDate;
    data['division'] = division;
    data['division_name'] = divisionName;
    data['division_code'] = divisionCode;
    data['section'] = section;
    data['section_name'] = sectionName;
    data['block_section'] = blockSection;
    data['block_section_name'] = blockSectionName;
    data['block_section_label'] = blockSectionLabel;
    data['block_section_from_code'] = blockSectionFromCode;
    data['block_section_to_code'] = blockSectionToCode;
    data['block_section_from_station_name'] = blockSectionFromStationName;
    data['block_section_to_station_name'] = blockSectionToStationName;
    data['block_section_from_lat'] = blockSectionFromLat;
    data['block_section_from_lon'] = blockSectionFromLon;
    data['block_section_to_lat'] = blockSectionToLat;
    data['block_section_to_lon'] = blockSectionToLon;
    data['block_section_coordinates'] = blockSectionCoordinates;
    data['line'] = line;
    data['line_name'] = lineName;
    data['nearest_station'] = nearestStation;
    data['nearest_station_name'] = nearestStationName;
    data['nearest_station_code'] = nearestStationCode;
    data['last_crossed_station'] = lastCrossedStation;
    data['last_crossed_station_name'] = lastCrossedStationName;
    data['last_crossed_station_code'] = lastCrossedStationCode;
    data['locomotive_number'] = locomotiveNumber;
    if (coachesWagons != null) {
      data['coaches_wagons'] = coachesWagons!.map((v) => v.toJson()).toList();
    }
    data['origin_station'] = originStation;
    data['origin_station_name'] = originStationName;
    data['destination_station'] = destinationStation;
    data['destination_station_name'] = destinationStationName;
    data['severity'] = severity;
    data['status'] = status;
    data['people_injured'] = peopleInjured;
    data['injured_count'] = injuredCount;
    data['train_derailed'] = trainDerailed;
    data['has_fire'] = hasFire;
    data['dangerous_goods'] = dangerousGoods;
    data['description'] = description;
    data['is_approved'] = isApproved;
    data['approved_at'] = approvedAt;
    data['approved_by'] = approvedBy;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (photos != null) {
      data['photos'] = photos!.map((v) => v.toJson()).toList();
    }
    if (timeline != null) {
      data['timeline'] = timeline!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CoachesWagons {
  String? type;
  int? order;
  int? assetId;
  String? category;
  String? assetNumber;

  CoachesWagons({
    this.type,
    this.order,
    this.assetId,
    this.category,
    this.assetNumber,
  });

  CoachesWagons.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    order = json['order'];
    assetId = json['asset_id'];
    category = json['category'];
    assetNumber = json['asset_number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['order'] = order;
    data['asset_id'] = assetId;
    data['category'] = category;
    data['asset_number'] = assetNumber;
    return data;
  }
}

class Photos {
  int? id;
  int? accident;
  String? file;
  String? fileName;
  int? fileSize;
  String? stage;
  String? stageDisplay;
  String? caption;
  String? latitude;
  String? longitude;
  String? uploadedAt;
  int? uploadedBy;
  String? uploadedByName;

  Photos({
    this.id,
    this.accident,
    this.file,
    this.fileName,
    this.fileSize,
    this.stage,
    this.stageDisplay,
    this.caption,
    this.latitude,
    this.longitude,
    this.uploadedAt,
    this.uploadedBy,
    this.uploadedByName,
  });

  Photos.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    accident = json['accident'];
    file = json['file'];
    fileName = json['file_name'];
    fileSize = json['file_size'];
    stage = json['stage'];
    stageDisplay = json['stage_display'];
    caption = json['caption'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    uploadedAt = json['uploaded_at'];
    uploadedBy = json['uploaded_by'];
    uploadedByName = json['uploaded_by_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['accident'] = accident;
    data['file'] = file;
    data['file_name'] = fileName;
    data['file_size'] = fileSize;
    data['stage'] = stage;
    data['stage_display'] = stageDisplay;
    data['caption'] = caption;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['uploaded_at'] = uploadedAt;
    data['uploaded_by'] = uploadedBy;
    data['uploaded_by_name'] = uploadedByName;
    return data;
  }
}

class Timeline {
  int? id;
  int? accident;
  String? actionType;
  String? actionTypeDisplay;
  String? title;
  String? description;
  String? actionLabel;
  String? actorName;
  String? actorRole;
  int? user;
  String? userName;
  String? eventTime;
  String? formattedTime;
  String? formattedDate;
  bool? isRead;
  String? createdAt;

  Timeline({
    this.id,
    this.accident,
    this.actionType,
    this.actionTypeDisplay,
    this.title,
    this.description,
    this.actionLabel,
    this.actorName,
    this.actorRole,
    this.user,
    this.userName,
    this.eventTime,
    this.formattedTime,
    this.formattedDate,
    this.isRead,
    this.createdAt,
  });

  Timeline.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    accident = json['accident'];
    actionType = json['action_type'];
    actionTypeDisplay = json['action_type_display'];
    title = json['title'];
    description = json['description'];
    actionLabel = json['action_label'];
    actorName = json['actor_name'];
    actorRole = json['actor_role'];
    user = json['user'];
    userName = json['user_name'];
    eventTime = json['event_time'];
    formattedTime = json['formatted_time'];
    formattedDate = json['formatted_date'];
    isRead = json['is_read'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['accident'] = accident;
    data['action_type'] = actionType;
    data['action_type_display'] = actionTypeDisplay;
    data['title'] = title;
    data['description'] = description;
    data['action_label'] = actionLabel;
    data['actor_name'] = actorName;
    data['actor_role'] = actorRole;
    data['user'] = user;
    data['user_name'] = userName;
    data['event_time'] = eventTime;
    data['formatted_time'] = formattedTime;
    data['formatted_date'] = formattedDate;
    data['is_read'] = isRead;
    data['created_at'] = createdAt;
    return data;
  }
}
