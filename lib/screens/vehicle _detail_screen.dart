class VehicleFuelSection extends StatefulWidget {
  final int vehicleId;
  const VehicleFuelSection({Key? key, required this.vehicleId}) : super(key: key);

  @override
  State<VehicleFuelSection> createState() => _VehicleFuelSectionState();
}

class _VehicleFuelSectionState extends State<VehicleFuelSection> {
  final FuelService _fuelService = FuelService();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Fuel History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Fuel"),
              onPressed: () async {
                final refresh = await showDialog(
                  context: context,
                  builder: (_) => AddEditFuelDialog(preSelectedVehicleId: widget.vehicleId),
                );
                if (refresh == true) setState(() {});
              },
            ),
          ],
        ),
        FutureBuilder<List<FuelLog>>(
          future: _fuelService.getFuelByVehicle(widget.vehicleId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final logs = snapshot.data!;
            if (logs.isEmpty) return const Text("No fuel entries recorded yet.");

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  leading: const Icon(Icons.local_gas_station, color: Colors.orange),
                  title: Text("${log.fuelType} - ${log.totalUnits} Units"),
                  subtitle: Text("Date: ${log.date} | Rate: Rs. ${log.ratePerUnit}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Rs. ${log.totalCost}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final refresh = await showDialog(
                            context: context,
                            builder: (_) => AddEditFuelDialog(fuelLog: log),
                          );
                          if (refresh == true) setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _fuelService.deleteFuelLog(log.id!);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
  
