import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/models/warehouse.dart';
import '../../shared/models/party.dart';
import '../../core/config/supabase_config.dart';

class MasterDataScreen extends ConsumerStatefulWidget {
  const MasterDataScreen({super.key});

  @override
  ConsumerState<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends ConsumerState<MasterDataScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddWarehouseDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Gudang Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Kode Gudang * (contoh: GDG-03)')),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Gudang *')),
            const SizedBox(height: 12),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Alamat Lokasi')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final service = ref.read(supabaseServiceProvider);
              await service.createWarehouse(
                Warehouse(
                  id: '',
                  kode: codeCtrl.text.trim(),
                  nama: nameCtrl.text.trim(),
                  alamat: addressCtrl.text.trim(),
                ),
              );
              ref.invalidate(warehousesProvider);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Kategori *')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi Singkat')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final service = ref.read(supabaseServiceProvider);
              await service.createCategory(nameCtrl.text.trim(), descCtrl.text.trim());
              ref.invalidate(categoriesProvider);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddSupplierDialog() {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Supplier / Vendor *')),
            const SizedBox(height: 12),
            TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Kontak / No Telp / PIC')),
            const SizedBox(height: 12),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Alamat Kantor/Gudang')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final service = ref.read(supabaseServiceProvider);
              await service.createSupplier(
                Supplier(
                  id: '',
                  nama: nameCtrl.text.trim(),
                  kontak: contactCtrl.text.trim(),
                  alamat: addressCtrl.text.trim(),
                ),
              );
              ref.invalidate(suppliersProvider);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Pelanggan / Penerima'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Pelanggan *')),
            const SizedBox(height: 12),
            TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Kontak / No Telp')),
            const SizedBox(height: 12),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Alamat Tujuan')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final service = ref.read(supabaseServiceProvider);
              await service.createCustomer(
                Customer(
                  id: '',
                  nama: nameCtrl.text.trim(),
                  kontak: contactCtrl.text.trim(),
                  alamat: addressCtrl.text.trim(),
                ),
              );
              ref.invalidate(customersProvider);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(warehousesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final suppliersAsync = ref.watch(suppliersProvider);
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Master Data'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Gudang'),
            Tab(text: 'Kategori'),
            Tab(text: 'Supplier'),
            Tab(text: 'Pelanggan'),
            Tab(text: 'Koneksi Supabase'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Gudang Tab
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daftar Gudang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: _showAddWarehouseDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah Gudang'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: warehousesAsync.when(
                    data: (list) => Card(
                      child: ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final w = list[idx];
                          return ListTile(
                            leading: const Icon(Icons.warehouse),
                            title: Text('${w.kode} - ${w.nama}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(w.alamat ?? 'Alamat belum diatur'),
                          );
                        },
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),

          // 2. Kategori Tab
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kategori Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: _showAddCategoryDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah Kategori'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: categoriesAsync.when(
                    data: (list) => Card(
                      child: ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final c = list[idx];
                          return ListTile(
                            leading: const Icon(Icons.category_outlined),
                            title: Text(c.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(c.deskripsi ?? ''),
                          );
                        },
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),

          // 3. Supplier Tab
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daftar Supplier / Vendor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: _showAddSupplierDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah Supplier'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: suppliersAsync.when(
                    data: (list) => Card(
                      child: ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final s = list[idx];
                          return ListTile(
                            leading: const Icon(Icons.local_shipping_outlined),
                            title: Text(s.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${s.kontak ?? "-"} • ${s.alamat ?? "-"}'),
                          );
                        },
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),

          // 4. Pelanggan Tab
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daftar Pelanggan / Tujuan Kirim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: _showAddCustomerDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah Pelanggan'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: customersAsync.when(
                    data: (list) => Card(
                      child: ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final c = list[idx];
                          return ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(c.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${c.kontak ?? "-"} • ${c.alamat ?? "-"}'),
                          );
                        },
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),

          // 5. Supabase Settings Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status Koneksi Supabase',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Icon(
                              SupabaseConfig.isConfigured ? Icons.check_circle : Icons.info,
                              color: SupabaseConfig.isConfigured ? Colors.green : Colors.amber.shade800,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              SupabaseConfig.isConfigured
                                  ? 'Terhubung ke Supabase Cloud / Self-hosted'
                                  : 'Mode Standalone / Demo (Siap Digunakan)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: SupabaseConfig.isConfigured ? Colors.green : Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aplikasi membaca konfigurasi dari file .env di root project:\n\n'
                          '• SUPABASE_URL: URL proyek Supabase Anda\n'
                          '• SUPABASE_ANON_KEY: Publishable/Anon Key (BUKAN service_role!)\n\n'
                          'Migration database SQL lengkap tersedia di folder:\nsupabase/migrations/20240101000000_initial_schema.sql',
                          style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

