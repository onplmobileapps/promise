class LeaveRequest {
  final int leaveTypeID;
  final String from;
  final String to;
  final String remarks;
  final int? empId;

  LeaveRequest({
    required this.leaveTypeID,
    required this.from,
    required this.to,
    required this.remarks,
    this.empId,
  });

  Map<String, dynamic> toJson() {
    return {
      'leaveTypeID': leaveTypeID,
      'from': from,
      'to': to,
      'remarks': remarks,
      'emp_id': empId,
    };
  }
}
