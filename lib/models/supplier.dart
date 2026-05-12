class Supplier {
  final int? id;
  final String name;
  final String? address;
  final String? tel;
  final String? staff;

  const Supplier({
    this.id,
    required this.name,
    this.address,
    this.tel,
    this.staff,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'address': address,
      'tel': tel,
      'staff': staff,
    };
  }

  Supplier copyWith({int? id, String? name, String? address, String? tel, String? staff}) {
    return Supplier(id: id ?? this.id, name: name ?? this.name,
        address: address ?? this.address, tel: tel ?? this.tel, staff: staff ?? this.staff);
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String?,
      tel: map['tel'] as String?,
      staff: map['staff'] as String?,
    );
  }
}
