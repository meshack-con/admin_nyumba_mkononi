/// Akaunti ya mtumiaji (mmiliki wa nyumba) kama inavyorudishwa na
/// `GET /admin/users` - inatumika kuchagua akaunti iliyopo.
class OwnerAccount {
  final int id;
  final String jina;
  final String simu;
  final String username;
  final String? eneo;

  OwnerAccount({
    required this.id,
    required this.jina,
    required this.simu,
    required this.username,
    required this.eneo,
  });

  factory OwnerAccount.fromJson(Map<String, dynamic> json) {
    return OwnerAccount(
      id: json['id'] as int,
      jina: json['jina_kamili'] as String,
      simu: json['namba_ya_simu'] as String,
      username: json['username'] as String,
      eneo: json['eneo'] as String?,
    );
  }
}
