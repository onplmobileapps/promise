class RecentEmployee {
  final List<Employee> employees;

  RecentEmployee({required this.employees});

  factory RecentEmployee.fromJson(Object? json) {
    final list = json is Map<String, dynamic> ? json['Employees'] : json;
    return RecentEmployee(
      employees: [
        if (list is List)
          for (final e in list)
            if (e is Map<String, dynamic>) Employee.fromJson(e),
      ],
    );
  }
}

class Employee {
  final String? shift;
  final int? gender;
  final int? empId;
  final int? roleId;
  final String? roleName;
  final String? rank;
  final String? fullName;
  final int? departmentId;
  final String? department;
  final int? locationId;
  final String? location;
  final int? divisionId;
  final String? division;
  final DateTime? joinDate;
  final String? designation;
  final String? status;
  final String? attStatus; // Nullable
  final String? profilePicturePath;

  Employee({
    this.shift,
    this.gender,
    this.empId,
    this.roleId,
    this.roleName,
    this.rank,
    this.fullName,
    this.departmentId,
    this.department,
    this.locationId,
    this.location,
    this.divisionId,
    this.division,
    this.joinDate,
    this.designation,
    this.status,
    this.attStatus,
    this.profilePicturePath,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      shift: _text(json['Shift']),
      gender: _int(json['Gender']),
      empId: _int(json['Emp_ID']),
      roleId: _int(json['RoleID']),
      roleName: _text(json['RoleName']),
      rank: _text(json['Rank']),
      fullName: _text(json['FullName']),
      departmentId: _int(json['DepartmentID']),
      department: _text(json['Department']),
      locationId: _int(json['LocationID']),
      location: _text(json['Location']),
      divisionId: _int(json['DivisionID']),
      division: _text(json['Division']),
      joinDate: DateTime.tryParse(json['JoinDate']?.toString() ?? ''),
      designation: _text(json['Designation']),
      status: _text(json['Status']),
      attStatus: _text(json['AttStatus']),
      profilePicturePath: _text(json['Profile_Picture_Path']),
    );
  }
}

int? _int(Object? v) =>
    v is num ? v.toInt() : (v is String ? int.tryParse(v.trim()) : null);

String? _text(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty || s == 'null' ? null : s;
}
