class EventRegistration {
  final String? id;
  final String userId;
  final String userName;
  final String userEmail;
  final String eventId;
  final String eventTitle;
  final DateTime registrationDate;
  final String status; // 'registered', 'attended', 'missed', 'cancelled'
  final bool isConfirmed;
  final String? certificateUrl;
  final DateTime? attendanceDate;
  final String? notes;
  final bool attended;

  EventRegistration({
    this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.eventId,
    required this.eventTitle,
    required this.registrationDate,
    required this.status,
    required this.isConfirmed,
    this.certificateUrl,
    this.attendanceDate,
    this.notes,
    this.attended = false,
  });

  factory EventRegistration.fromMap(Map<String, dynamic> map) {
    return EventRegistration(
      id: map['_id']?.toString(),
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? '',
      userEmail: map['user_email'] ?? '',
      eventId: map['event_id'] ?? '',
      eventTitle: map['event_title'] ?? '',
      registrationDate: map['registration_date'] != null 
          ? DateTime.parse(map['registration_date'].toString())
          : DateTime.now(),
      status: map['status'] ?? 'registered',
      isConfirmed: map['is_confirmed'] ?? false,
      certificateUrl: map['certificate_url'],
      attendanceDate: map['attendance_date'] != null 
          ? DateTime.parse(map['attendance_date'].toString())
          : null,
      notes: map['notes'],
      attended: map['attended'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'event_id': eventId,
      'event_title': eventTitle,
      'registration_date': registrationDate.toIso8601String(),
      'status': status,
      'is_confirmed': isConfirmed,
      'certificate_url': certificateUrl,
      'attendance_date': attendanceDate?.toIso8601String(),
      'notes': notes,
      'attended': attended,
    };
  }

  @override
  String toString() {
    return 'EventRegistration(user: $userName, event: $eventTitle, status: $status, confirmed: $isConfirmed)';
  }

  EventRegistration copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? eventId,
    String? eventTitle,
    DateTime? registrationDate,
    String? status,
    bool? isConfirmed,
    String? certificateUrl,
    DateTime? attendanceDate,
    String? notes,
    bool? attended,
  }) {
    return EventRegistration(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      registrationDate: registrationDate ?? this.registrationDate,
      status: status ?? this.status,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      notes: notes ?? this.notes,
      attended: attended ?? this.attended,
    );
  }

  bool get isRegistered => status == 'registered';
  bool get isAttended => status == 'attended';
  bool get isMissed => status == 'missed';
  bool get isCancelled => status == 'cancelled';
  bool get hasCertificate => certificateUrl != null && certificateUrl!.isNotEmpty;
} 