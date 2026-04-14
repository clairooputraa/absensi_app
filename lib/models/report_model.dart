class ReportModel {
  final String id;
  final String title;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final String generatedBy;
  final DateTime generatedAt;
  final String filePath;
  final Map<String, dynamic> data;
  final String format;

  ReportModel({
    required this.id,
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.generatedBy,
    required this.generatedAt,
    required this.filePath,
    required this.data,
    required this.format,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'generatedBy': generatedBy,
      'generatedAt': generatedAt.toIso8601String(),
      'filePath': filePath,
      'data': data.toString(),
      'format': format,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'],
      title: map['title'],
      type: map['type'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      generatedBy: map['generatedBy'],
      generatedAt: DateTime.parse(map['generatedAt']),
      filePath: map['filePath'],
      data: {},
      format: map['format'],
    );
  }
}