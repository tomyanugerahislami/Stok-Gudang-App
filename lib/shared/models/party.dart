class Supplier {
  final String id;
  final String nama;
  final String? kontak;
  final String? alamat;

  Supplier({
    required this.id,
    required this.nama,
    this.kontak,
    this.alamat,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      nama: json['nama'] as String,
      kontak: json['kontak'] as String?,
      alamat: json['alamat'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'kontak': kontak,
      'alamat': alamat,
    };
  }
}

class Customer {
  final String id;
  final String nama;
  final String? kontak;
  final String? alamat;

  Customer({
    required this.id,
    required this.nama,
    this.kontak,
    this.alamat,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      nama: json['nama'] as String,
      kontak: json['kontak'] as String?,
      alamat: json['alamat'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'kontak': kontak,
      'alamat': alamat,
    };
  }
}

