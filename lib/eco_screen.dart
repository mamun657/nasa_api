import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class EonetEventsScreen extends StatefulWidget {
  const EonetEventsScreen({super.key});

  @override
  State<EonetEventsScreen> createState() => _EonetEventsScreenState();
}

class _EonetEventsScreenState extends State<EonetEventsScreen> {
  List<dynamic> events = [];
  bool loading = false;
  String? error;

  Future<void> fetchEvents() async {
    setState(() {
      loading = true;
      error = null;
    });

    final url = Uri.parse(
      'https://eonet.gsfc.nasa.gov/api/v3/events?status=open&limit=20',
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        events = (data['events'] as List?) ?? [];
      } else {
        error = 'HTTP ${res.statusCode}';
      }
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EONET Natural Events'),
        actions: [
          IconButton(onPressed: fetchEvents, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchEvents,
        child: loading && events.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: fetchEvents,
                    child: const Text('Retry'),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final ev = events[i] as Map<String, dynamic>;
                  final title = ev['title'] as String? ?? 'Untitled';
                  final categories = (ev['categories'] as List?) ?? [];
                  final catTitle = categories.isNotEmpty
                      ? (categories.first as Map<String, dynamic>)['title']
                                as String? ??
                            '—'
                      : '—';
                  final geometries = (ev['geometry'] as List?) ?? [];
                  final date = geometries.isNotEmpty
                      ? (geometries.first as Map<String, dynamic>)['date']
                                as String? ??
                            ''
                      : '';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Category: $catTitle'),
                          if (date.isNotEmpty) Text('Date: $date'),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EonetEventDetail(event: ev),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class EonetEventDetail extends StatelessWidget {
  const EonetEventDetail({super.key, required this.event});
  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final title = event['title'] as String? ?? 'Event detail';
    final categories = (event['categories'] as List?) ?? [];
    final catTitle = categories.isNotEmpty
        ? (categories.first as Map<String, dynamic>)['title'] as String? ?? '—'
        : '—';
    final sources = (event['sources'] as List?) ?? [];
    final geometries = (event['geometry'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Category: $catTitle')),
              Chip(label: Text('Sources: ${sources.length}')),
              Chip(label: Text('Points: ${geometries.length}')),
            ],
          ),
          const SizedBox(height: 12),
          if (geometries.isNotEmpty)
            ...geometries.take(10).map((g) {
              final m = g as Map<String, dynamic>;
              final date = m['date'] as String? ?? '';
              final coords = m['coordinates'];
              final coordsText = coords is List
                  ? coords.join(', ')
                  : (coords?.toString() ?? '');
              return ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(date),
                subtitle: Text(coordsText),
              );
            }),
          const SizedBox(height: 12),
          if (sources.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sources',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...sources.map((s) {
                  final src = s as Map<String, dynamic>;
                  final id = src['id'] as String? ?? '';
                  final url = src['url'] as String? ?? '';
                  return ListTile(
                    leading: const Icon(Icons.link),
                    title: Text(id),
                    subtitle: Text(url),
                    onTap: () async {
                      if (url.isEmpty) return;
                      final uri = Uri.parse(url);
                      final ok = await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open link')),
                        );
                      }
                    },
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }
}
