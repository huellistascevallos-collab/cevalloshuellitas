import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _busqueda = '';

  final List<Map<String, dynamic>> _productos = [
    {
      'nombre': 'Amoxicilina 250mg',
      'categoria': 'Antibiótico',
      'stock': 45,
      'stockMin': 20,
      'precio': 8.50,
      'unidad': 'cápsulas',
      'icon': Icons.medication_outlined,
      'color': Color(0xFF1CB5C9),
    },
    {
      'nombre': 'Vacuna Antirrábica',
      'categoria': 'Vacuna',
      'stock': 12,
      'stockMin': 15,
      'precio': 18.00,
      'unidad': 'dosis',
      'icon': Icons.vaccines_outlined,
      'color': Color(0xFF7C6FCD),
    },
    {
      'nombre': 'Frontline Spray',
      'categoria': 'Antiparasitario',
      'stock': 8,
      'stockMin': 10,
      'precio': 22.00,
      'unidad': 'frascos',
      'icon': Icons.bug_report_outlined,
      'color': Color(0xFF43B89C),
    },
    {
      'nombre': 'Metronidazol 500mg',
      'categoria': 'Antibiótico',
      'stock': 30,
      'stockMin': 15,
      'precio': 6.00,
      'unidad': 'tabletas',
      'icon': Icons.medication_outlined,
      'color': Color(0xFF1CB5C9),
    },
    {
      'nombre': 'Suero Fisiológico',
      'categoria': 'Solución',
      'stock': 20,
      'stockMin': 10,
      'precio': 3.50,
      'unidad': 'bolsas',
      'icon': Icons.water_drop_outlined,
      'color': Color(0xFF1CB5C9),
    },
    {
      'nombre': 'Buprenorfina 0.3mg',
      'categoria': 'Analgésico',
      'stock': 5,
      'stockMin': 8,
      'precio': 35.00,
      'unidad': 'ampollas',
      'icon': Icons.healing_outlined,
      'color': Color(0xFFE58D57),
    },
  ];

  final List<Map<String, dynamic>> _facturas = [
    {
      'numero': '#001-2025',
      'cliente': 'María Torres',
      'fecha': '20/06/2025',
      'total': 45.50,
      'estado': 'pagada',
      'items': ['Consulta general', 'Amoxicilina x2'],
    },
    {
      'numero': '#002-2025',
      'cliente': 'Carlos López',
      'fecha': '19/06/2025',
      'total': 28.00,
      'estado': 'pagada',
      'items': ['Vacuna antirrábica', 'Desparasitación'],
    },
    {
      'numero': '#003-2025',
      'cliente': 'Ana Martínez',
      'fecha': '18/06/2025',
      'total': 95.00,
      'estado': 'pendiente',
      'items': ['Cirugía menor', 'Hospitalización 1 día'],
    },
    {
      'numero': '#004-2025',
      'cliente': 'Luis Ramírez',
      'fecha': '17/06/2025',
      'total': 22.00,
      'estado': 'pagada',
      'items': ['Consulta + Frontline'],
    },
  ];

  List<Map<String, dynamic>> get _productosFiltrados {
    if (_busqueda.isEmpty) return _productos;
    return _productos
        .where((p) =>
            (p['nombre'] as String)
                .toLowerCase()
                .contains(_busqueda.toLowerCase()) ||
            (p['categoria'] as String)
                .toLowerCase()
                .contains(_busqueda.toLowerCase()))
        .toList();
  }

  int get _productosStockBajo =>
      _productos.where((p) => (p['stock'] as int) < (p['stockMin'] as int)).length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // Cabecera
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              height: 260,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF126E82), Color(0xFF1CB5C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          const Icon(Icons.cases_rounded,
                              color: Colors.white, size: 28),
                          Text(
                            'Inventario y Facturas',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Alerta stock bajo
                if (_productosStockBajo > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '$_productosStockBajo producto(s) con stock bajo',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: const Color(0xFF126E82),
                    unselectedLabelColor: Colors.white,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: [
                      Tab(
                          child: Text('Inventario',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600))),
                      Tab(
                          child: Text('Facturas',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Contenido
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab Inventario
                      Column(
                        children: [
                          // Buscador
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              onChanged: (v) => setState(() => _busqueda = v),
                              style: GoogleFonts.poppins(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Buscar producto...',
                                hintStyle: GoogleFonts.poppins(
                                    color: Colors.grey.shade400, fontSize: 13),
                                prefixIcon: Icon(Icons.search,
                                    color: Colors.grey.shade400),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFDDEEF0), width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1CB5C9), width: 2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              itemCount: _productosFiltrados.length,
                              itemBuilder: (context, index) =>
                                  _buildProductoCard(
                                      _productosFiltrados[index]),
                            ),
                          ),
                        ],
                      ),

                      // Tab Facturas
                      ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _facturas.length,
                        itemBuilder: (context, index) =>
                            _buildFacturaCard(_facturas[index]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoCard(Map<String, dynamic> producto) {
    final stockBajo =
        (producto['stock'] as int) < (producto['stockMin'] as int);
    final color = producto['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: stockBajo
            ? Border.all(color: const Color(0xFFFFCDD2), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(producto['icon'] as IconData,
                  size: 26, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['nombre'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    producto['categoria'] as String,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    if (stockBajo)
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFE53935), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${producto['stock']} ${producto['unidad']}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: stockBajo
                            ? const Color(0xFFE53935)
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${(producto['precio'] as double).toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacturaCard(Map<String, dynamic> factura) {
    final pagada = factura['estado'] == 'pagada';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  factura['numero'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pagada
                        ? Colors.green.shade50
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pagada ? 'Pagada ✓' : 'Pendiente',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pagada
                          ? Colors.green.shade600
                          : const Color(0xFFF9A825),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Cliente: ${factura['cliente']}  ·  ${factura['fecha']}',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            ...((factura['items'] as List<String>).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.fiber_manual_record,
                          size: 8, color: Color(0xFF1CB5C9)),
                      const SizedBox(width: 8),
                      Text(item,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ))),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: \$${(factura['total'] as double).toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1CB5C9),
                  ),
                ),
                if (!pagada)
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1CB5C9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Registrar pago',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width / 2, size.height + 10, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
