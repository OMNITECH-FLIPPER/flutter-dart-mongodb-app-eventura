class Event {
  final String? id;
  final String title;
  final String description;
  final String organizerId;
  final String organizerName;
  final String imageUrl;
  final int totalSlots;
  final int availableSlots;
  final DateTime eventDate;
  final String location;
  final String status; // 'upcoming', 'ongoing', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool pendingApproval;
  final List<Map<String, dynamic>> editHistory;
  final String? lastEditedBy;

  Event({
    this.id,
    required this.title,
    required this.description,
    required this.organizerId,
    required this.organizerName,
    required this.imageUrl,
    required this.totalSlots,
    required this.availableSlots,
    required this.eventDate,
    required this.location,
    required this.status,
    this.pendingApproval = false,
    List<Map<String, dynamic>>? editHistory,
    this.lastEditedBy,
    DateTime? createdAt,
    this.updatedAt,
  }) : editHistory = editHistory ?? [],
      createdAt = createdAt ?? DateTime.now();

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['_id']?.toString(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      organizerId: map['organizer_id'] ?? '',
      organizerName: map['organizer_name'] ?? '',
      imageUrl: map['image_url'] ?? '',
      totalSlots: map['total_slots'] ?? 0,
      availableSlots: map['available_slots'] ?? 0,
      eventDate: map['event_date'] != null 
          ? DateTime.parse(map['event_date'].toString())
          : DateTime.now(),
      location: map['location'] ?? '',
      status: map['status'] ?? 'upcoming',
      pendingApproval: map['pending_approval'] ?? false,
      editHistory: (map['edit_history'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      lastEditedBy: map['last_edited_by'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'organizer_id': organizerId,
      'organizer_name': organizerName,
      'image_url': imageUrl,
      'total_slots': totalSlots,
      'available_slots': availableSlots,
      'event_date': eventDate.toIso8601String(),
      'location': location,
      'status': status,
      'pending_approval': pendingApproval,
      'edit_history': editHistory,
      'last_edited_by': lastEditedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Event(id: $id, title: $title, organizer: $organizerName, slots: $availableSlots/$totalSlots, date: $eventDate)';
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? organizerId,
    String? organizerName,
    String? imageUrl,
    int? totalSlots,
    int? availableSlots,
    DateTime? eventDate,
    String? location,
    String? status,
    bool? pendingApproval,
    List<Map<String, dynamic>>? editHistory,
    String? lastEditedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      imageUrl: imageUrl ?? this.imageUrl,
      totalSlots: totalSlots ?? this.totalSlots,
      availableSlots: availableSlots ?? this.availableSlots,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      status: status ?? this.status,
      pendingApproval: pendingApproval ?? this.pendingApproval,
      editHistory: editHistory ?? this.editHistory,
      lastEditedBy: lastEditedBy ?? this.lastEditedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isFull => availableSlots <= 0;
  bool get isUpcoming => status == 'upcoming';
  bool get isOngoing => status == 'ongoing';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
} 