import 'base_url.dart';

/// Makes image/document URLs returned by the API loadable on a real device.
///
/// Common backend mistakes: store `http://localhost:3000/...`, `http://192.168...`,
/// or a relative path `/uploads/...`. Phones cannot reach those hosts; remap to
/// [resolveApiOrigin] while keeping path + query.
String resolvePublicMediaUrl(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return '';

  if (s.startsWith('//')) {
    return 'https:$s';
  }

  final origin = resolveApiOrigin();

  if (s.startsWith('/')) {
    return '$origin$s';
  }

  final uri = Uri.tryParse(s);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return s;
  }

  final host = uri.host.toLowerCase();
  final isLoopbackOrLan = host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '0.0.0.0' ||
      host == '10.0.2.2' ||
      host.startsWith('192.168.') ||
      host.startsWith('10.') ||
      host.startsWith('172.');

  if (!isLoopbackOrLan) {
    return s;
  }

  final path = uri.path.isEmpty ? '/' : uri.path;
  final q = uri.hasQuery ? '?${uri.query}' : '';
  return '$origin$path$q';
}
