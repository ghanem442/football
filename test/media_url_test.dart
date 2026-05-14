import 'package:flutter_test/flutter_test.dart';
import 'package:football/core/network/media_url.dart';

void main() {
  test('resolvePublicMediaUrl prepends origin for root-relative paths', () {
    final u = resolvePublicMediaUrl('/uploads/field.jpg');
    expect(u, startsWith('https://'));
    expect(u, endsWith('/uploads/field.jpg'));
  });

  test('resolvePublicMediaUrl rewrites localhost to API origin', () {
    final u = resolvePublicMediaUrl('http://localhost:3000/files/a.png');
    expect(u, isNot(contains('localhost')));
    expect(u, contains('/files/a.png'));
  });
}
