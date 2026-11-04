class Warehouse {
  final String id;
  final String kode;
  final String nama;
  final String? alamat;
  final String status;

  Warehouse({
    required this.id,
    required this.kode,
    required this.nama,
    this.alamat,
    this.status = 'active',
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] as String,
      kode: json['kode'] as String,
      nama: json['nama'] as String,
      alamat: json['alamat'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kode': kode,
      'nama': nama,
      'alamat': alamat,
      'status': status,
    };
  }
}

