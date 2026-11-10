class UserModel {
  final int id;
  final String role;
  final String nama;
  final String email;
  final String noHp;
  final String inisial;

  const UserModel({
    required this.id,
    required this.role,
    required this.nama,
    required this.email,
    required this.noHp,
    required this.inisial,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as int,
        role: j['role'] as String,
        nama: j['nama'] as String,
        email: j['email'] as String,
        noHp: j['noHp'] as String,
        inisial: (j['inisial'] ?? '?') as String,
      );
}
