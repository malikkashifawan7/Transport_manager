void showMonthlyReportDialog(BuildContext context, int vehicleId, String monthYear) async {
  final fuelService = FuelService();
  final reportData = await fuelService.getMonthlyVehicleReport(
    vehicleId: vehicleId,
    monthYear: monthYear,
  );

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Monthly Hisab ($monthYear)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total Earning: Rs. ${reportData['earning']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Fuel Expense: Rs. ${reportData['fuel']}", style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Text("Other Expenses: Rs. ${reportData['otherExp']}", style: const TextStyle(color: Colors.orange)),
            const Divider(),
            Text("Net Profit / Saving: Rs. ${reportData['netProfit']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
