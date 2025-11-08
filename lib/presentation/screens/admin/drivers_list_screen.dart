import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neurodrive/core/theme/app_theme.dart';
import 'package:neurodrive/data/models/user_model.dart';

class DriversListScreen extends StatefulWidget {
  const DriversListScreen({super.key});

  @override
  State<DriversListScreen> createState() => _DriversListScreenState();
}

class _DriversListScreenState extends State<DriversListScreen> {
  String searchQuery = '';
  String filterBy = 'all'; // all, name, plate, phone

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conductores Registrados'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Campo de búsqueda
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar conductor...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Filtros rápidos
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Todos',
                        isSelected: filterBy == 'all',
                        onSelected: () => setState(() => filterBy = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Por Nombre',
                        isSelected: filterBy == 'name',
                        onSelected: () => setState(() => filterBy = 'name'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Por Placa',
                        isSelected: filterBy == 'plate',
                        onSelected: () => setState(() => filterBy = 'plate'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Por Teléfono',
                        isSelected: filterBy == 'phone',
                        onSelected: () => setState(() => filterBy = 'phone'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de conductores
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'user')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay conductores registrados',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Filtrar conductores según búsqueda
                var drivers = snapshot.data!.docs.map((doc) {
                  return UserModel.fromJson(doc.data() as Map<String, dynamic>);
                }).toList();

                // Aplicar filtro de búsqueda
                if (searchQuery.isNotEmpty) {
                  drivers = drivers.where((driver) {
                    switch (filterBy) {
                      case 'name':
                        return driver.name.toLowerCase().contains(searchQuery);
                      case 'plate':
                        return driver.plate.toLowerCase().contains(searchQuery);
                      case 'phone':
                        return driver.phone.toLowerCase().contains(searchQuery);
                      default:
                        return driver.name.toLowerCase().contains(searchQuery) ||
                            driver.plate.toLowerCase().contains(searchQuery) ||
                            driver.phone.toLowerCase().contains(searchQuery) ||
                            driver.email.toLowerCase().contains(searchQuery);
                    }
                  }).toList();
                }

                if (drivers.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No se encontraron resultados',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    return _DriverCard(
                      driver: driver,
                      onTap: () => _showDriverDetails(context, driver),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar detalles del conductor
  void _showDriverDetails(BuildContext context, UserModel driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _DriverDetailsSheet(
            driver: driver,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

// Widget de chip de filtro
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryBlue,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
      ),
    );
  }
}

// Widget de tarjeta de conductor
class _DriverCard extends StatelessWidget {
  final UserModel driver;
  final VoidCallback onTap;

  const _DriverCard({
    required this.driver,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryBlue,
          radius: 30,
          child: Text(
            driver.name.isNotEmpty 
                ? driver.name[0].toUpperCase() 
                : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          driver.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.directions_car, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(driver.plate),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(driver.phone),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// Widget de detalles del conductor (Bottom Sheet)
class _DriverDetailsSheet extends StatelessWidget {
  final UserModel driver;
  final ScrollController scrollController;

  const _DriverDetailsSheet({
    required this.driver,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle del bottom sheet
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Avatar y nombre
          Center(
            child: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue,
              radius: 50,
              child: Text(
                driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              driver.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Información del conductor
          _InfoRow(
            icon: Icons.email,
            label: 'Correo',
            value: driver.email,
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.phone,
            label: 'Teléfono',
            value: driver.phone,
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.directions_car,
            label: 'Placa',
            value: driver.plate,
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.contact_emergency,
            label: 'Contacto de Emergencia',
            value: driver.emergencyContact,
          ),
          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Ver historial de viajes
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función próximamente'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('Historial'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Ver estadísticas
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función próximamente'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Estadísticas'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget de fila de información
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}