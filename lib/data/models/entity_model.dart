class Entity {
  final String id;
  final String userId;
  final String name;
  final bool isPrimary;

  Entity({
    required this.id,
    required this.userId,
    required this.name,
    required this.isPrimary,
  });

  // Convert DB row to Object
  factory Entity.fromMap(Map<String, dynamic> map) {
    return Entity(
      id: map['entity_id'],
      userId: map['user_id'],
      name: map['entity_name'],
      isPrimary: map['is_primary'] == 1,
    );
  }
}