// Booking Detail Screen par call karein
ElevatedButton.icon(
  icon: const Icon(Icons.local_gas_station),
  label: const Text("Add Trip Fuel Entry"),
  onPressed: () async {
    await showDialog(
      context: context,
      builder: (_) => AddEditFuelDialog(
        preSelectedVehicleId: booking.vehicleId,
        preSelectedBookingId: booking.id,
      ),
    );
    setState(() {});
  },
);

