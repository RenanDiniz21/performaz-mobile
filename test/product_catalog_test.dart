import 'package:flutter_test/flutter_test.dart';
import 'package:performaz/features/orders/product_catalog_screen.dart';
import 'package:performaz/shared/models/product.dart';

class FakeProductSource implements ProductSource {
  FakeProductSource(this.products);

  final List<Product> products;

  @override
  Future<List<Product>> fetchProducts() async => products;
}

void main() {
  test('Product.fromJson accepts API camelCase product fields', () {
    final product = Product.fromJson({
      'id': 'product-1',
      'name': 'Acai Premium',
      'unitPrice': 18.5,
      'unitOfMeasure': 'un',
      'code': 'AC-001',
      'category': 'Congelados',
      'description': 'Pote de acai',
      'imageUrl': 'https://example.com/acai.png',
      'isActive': true,
    });

    expect(product.unitPrice, 18.5);
    expect(product.unitOfMeasure, 'un');
    expect(product.imageUrl, 'https://example.com/acai.png');
    expect(product.isActive, isTrue);
  });

  test('Product.fromJson accepts Nest API product fields', () {
    final product = Product.fromJson({
      'id': 'product-1',
      'name': 'Acai Premium',
      'price': 18.5,
      'unit': 'un',
      'code': 'AC-001',
      'category': 'Congelados',
      'imageUrl': 'https://example.com/acai.png',
      'active': true,
    });

    expect(product.unitPrice, 18.5);
    expect(product.unitOfMeasure, 'un');
    expect(product.imageUrl, 'https://example.com/acai.png');
    expect(product.isActive, isTrue);
  });

  test('ProductCatalogCubit loads active products from a source', () async {
    final cubit = ProductCatalogCubit(
      productSource: FakeProductSource([
        const Product(
          id: 'active-1',
          name: 'Acai Premium',
          unitPrice: 18.5,
          unitOfMeasure: 'un',
          category: 'Congelados',
        ),
        const Product(
          id: 'inactive-1',
          name: 'Produto Inativo',
          unitPrice: 9,
          unitOfMeasure: 'cx',
          isActive: false,
        ),
      ]),
    );

    await cubit.loadProducts();

    expect(cubit.state.products.map((product) => product.id), ['active-1']);
    expect(cubit.state.categories, ['Congelados']);
  });
}
