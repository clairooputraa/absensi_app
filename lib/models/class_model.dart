class ClassModel {
  final String id;
  final String name;
  final String? teacherId;
  final String? teacherName;
  final String? room;
  final String academicYear;
  final int capacity;
  final int studentCount;
  final bool isActive;
  final DateTime createdAt;
  final String? description;

  ClassModel({
    required this.id,
    required this.name,
    this.teacherId,
    this.teacherName,
    this.room,
    required this.academicYear,
    this.capacity = 30,
    this.studentCount = 0,
    this.isActive = true,
    required this.createdAt,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'room': room,
      'academicYear': academicYear,
      'capacity': capacity,
      'studentCount': studentCount,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
    };
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'],
      name: map['name'],
      teacherId: map['teacherId'],
      teacherName: map['teacherName'],
      room: map['room'],
      academicYear: map['academicYear'],
      capacity: map['capacity'],
      studentCount: map['studentCount'],
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      description: map['description'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel.fromMap(json);
}