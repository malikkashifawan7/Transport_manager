import 'package:flutter/material.dart';

void main() {
  runApp(const TransportApp());
}

class TransportApp extends StatelessWidget {
  const TransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Map<String, String> modules = {
    'Records': 'View All Transport Records',
    'Drivers': 'Manage Drivers List',
    'Vehicles': 'Vehicle History',
  };

  final String db = "main_database";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Fixed search context call
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(records: modules.keys.toList()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        // Fixed .toList() call
        children: modules.entries.map((e) => Card(
          child: ListTile(
            title: Text(e.key),
            subtitle: Text(e.value),
            onTap: () {
              // Fixed named parameters
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Page(db: db, title: e.key),
                ),
              );
            },
          ),
        )).toList(),
      ),
    );
  }
}

class Page extends StatelessWidget {
  final String db;
  final String title;

  const Page({super.key, required this.db, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text('Database: $db | View: $title'),
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  final List<String> records;

  CustomSearchDelegate({required this.records});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text('Search Result: $query'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = records.where((element) => element.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
        );
      },
    );
  }
}
