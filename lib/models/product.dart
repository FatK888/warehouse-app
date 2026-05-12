class Product {
  final int? id;
  final String upc;
  final String band;
  final String type;
  final String item;
  final String? size;
  final String? color;
  final String? model;
  final String? spec;
  final String? scode;
  final String? createdAt;

  const Product({
    this.id,
    required this.upc,
    required this.band,
    required this.type,
    required this.item,
    this.size,
    this.color,
    this.model,
    this.spec,
    this.scode,
    this.createdAt,
  });

  String get displayName => [band, type, item].join(' ');

  String get fullDescription {
    final parts = [band, type, item];
    if (size != null && size!.isNotEmpty) parts.add(size!);
    if (color != null && color!.isNotEmpty) parts.add(color!);
    if (model != null && model!.isNotEmpty) parts.add(model!);
    if (spec != null && spec!.isNotEmpty) parts.add(spec!);
    return parts.join(' ');
  }

  Product copyWith({
    int? id,
    String? upc,
    String? band,
    String? type,
    String? item,
    String? size,
    String? color,
    String? model,
    String? spec,
    String? scode,
    String? createdAt,
    bool clearSize = false,
    bool clearColor = false,
    bool clearModel = false,
    bool clearSpec = false,
    bool clearScode = false,
  }) {
    return Product(
      id: id ?? this.id,
      upc: upc ?? this.upc,
      band: band ?? this.band,
      type: type ?? this.type,
      item: item ?? this.item,
      size: clearSize ? null : (size ?? this.size),
      color: clearColor ? null : (color ?? this.color),
      model: clearModel ? null : (model ?? this.model),
      spec: clearSpec ? null : (spec ?? this.spec),
      scode: clearScode ? null : (scode ?? this.scode),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'upc': upc,
      'band': band,
      'type': type,
      'item': item,
      'size': size,
      'color': color,
      'model': model,
      'spec': spec,
      'scode': scode,
      'created_at': createdAt ?? (() {
        final now = DateTime.now();
        return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')} ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}';
      })(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      upc: map['upc'] as String,
      band: map['band'] as String,
      type: map['type'] as String,
      item: map['item'] as String,
      size: map['size'] as String?,
      color: map['color'] as String?,
      model: map['model'] as String?,
      spec: map['spec'] as String?,
      scode: map['scode'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }
}
