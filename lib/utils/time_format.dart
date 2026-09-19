/// Husaidia kuonesha muda ambao tangazo la nyumba limekuwa ndani ya app,
/// kwa mfano "Siku 3 zilizopita", "Saa 2 zilizopita", "Dakika 5 zilizopita".
String timeAgo(DateTime createdAt) {
  final now = DateTime.now().toUtc();
  final created = createdAt.isUtc ? createdAt : createdAt.toUtc();
  var diff = now.difference(created);
  if (diff.isNegative) diff = Duration.zero;

  if (diff.inDays >= 365) {
    final years = (diff.inDays / 365).floor();
    return years == 1 ? 'Mwaka 1 uliopita' : 'Miaka $years iliyopita';
  }
  if (diff.inDays >= 30) {
    final months = (diff.inDays / 30).floor();
    return months == 1 ? 'Mwezi 1 uliopita' : 'Miezi $months iliyopita';
  }
  if (diff.inDays >= 7) {
    final weeks = (diff.inDays / 7).floor();
    return weeks == 1 ? 'Wiki 1 iliyopita' : 'Wiki $weeks zilizopita';
  }
  if (diff.inDays >= 1) {
    return diff.inDays == 1 ? 'Siku 1 iliyopita' : 'Siku ${diff.inDays} zilizopita';
  }
  if (diff.inHours >= 1) {
    return diff.inHours == 1 ? 'Saa 1 lililopita' : 'Masaa ${diff.inHours} yaliyopita';
  }
  if (diff.inMinutes >= 1) {
    return diff.inMinutes == 1 ? 'Dakika 1 iliyopita' : 'Dakika ${diff.inMinutes} zilizopita';
  }
  return 'Sasa hivi';
}
