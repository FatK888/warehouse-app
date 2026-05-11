import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse/models/product.dart';

void main() {
  group('Product', () {
    test('fromMap should parse all fields', () {
      final map = {
        'id': 1,
        'band': 'Apple',
        'type': 'iPhone',
        'item': '17Pro Max',
        'size': '512',
        'color': 'ML8G3',
        'model': 'ZA/NA',
        'spec': null,
        'created_at': '2026-05-11 10:00:00',
      };

      final product = Product.fromMap(map);

      expect(product.id, 1);
      expect(product.band, 'Apple');
      expect(product.type, 'iPhone');
      expect(product.item, '17Pro Max');
      expect(product.size, '512');
      expect(product.color, 'ML8G3');
      expect(product.model, 'ZA/NA');
      expect(product.spec, isNull);
    });

    test('fromMap should handle null optional fields', () {
      final map = {
        'id': 2,
        'band': 'Samsung',
        'type': 'Phone',
        'item': 'Galaxy S25',
        'size': null,
        'color': null,
        'model': null,
        'spec': null,
        'created_at': '2026-05-11 10:00:00',
      };

      final product = Product.fromMap(map);

      expect(product.size, isNull);
      expect(product.color, isNull);
      expect(product.model, isNull);
      expect(product.spec, isNull);
    });

    test('toMap should include all fields except id', () {
      final product = Product(
        band: 'Apple',
        type: 'iPhone',
        item: '17Pro Max',
        size: '512',
        color: 'ML8G3',
        model: 'ZA/NA',
        spec: null,
      );

      final map = product.toMap();

      expect(map['id'], isNull);
      expect(map['band'], 'Apple');
      expect(map['type'], 'iPhone');
      expect(map['item'], '17Pro Max');
      expect(map['size'], '512');
      expect(map['color'], 'ML8G3');
      expect(map['model'], 'ZA/NA');
      expect(map['spec'], isNull);
      expect(map['created_at'], isNotNull);
    });

    test('displayName should return BAND TYPE ITEM', () {
      final product = Product(
        band: 'Apple',
        type: 'iPhone',
        item: '17Pro Max',
      );

      expect(product.displayName, 'Apple iPhone 17Pro Max');
    });

    test('copyWith should update specific fields', () {
      final product = Product(band: 'Apple', type: 'iPhone', item: '17Pro Max',
        size: '512', color: 'ML8G3');
      final updated = product.copyWith(size: '256', color: 'RED');
      expect(updated.size, '256');
      expect(updated.color, 'RED');
      expect(updated.band, 'Apple'); // unchanged
    });

    test('copyWith clearXxx flags should set field to null', () {
      final product = Product(band: 'Apple', type: 'iPhone', item: '17Pro Max',
        size: '512', color: 'ML8G3');
      final cleared = product.copyWith(clearSize: true, clearColor: true);
      expect(cleared.size, isNull);
      expect(cleared.color, isNull);
    });

    test('fullDescription should join all non-null fields', () {
      final product = Product(band: 'Apple', type: 'iPhone', item: '17Pro Max',
        size: '512', color: 'ML8G3', model: 'ZA/NA');
      expect(product.fullDescription, 'Apple iPhone 17Pro Max 512 ML8G3 ZA/NA');
    });
  });
}
