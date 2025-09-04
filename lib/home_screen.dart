import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'apod_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ApodModel? apodModel;
  bool loading = false;
  String? error;

  // 🔑 Replace DEMO_KEY with your real NASA key if you have one
  static const String _apiKey = 'DEMO_KEY';

  Future<void> fetchData() async {
    setState(() {
      loading = true;
      error = null;
    });

    final url = Uri.parse(
      "https://api.nasa.gov/planetary/apod?api_key=$_apiKey",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        apodModel = ApodModel.fromJson(jsonDecode(response.body));
      } else {
        error = "HTTP ${response.statusCode}";
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
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NASA APOD'),
        actions: [
          IconButton(onPressed: fetchData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading && apodModel == null
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: fetchData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : apodModel == null
          ? const Center(child: Text('No data'))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    apodModel!.title ?? 'No title',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    apodModel!.date != null
                        ? apodModel!.date!.toLocal().toString().split(' ').first
                        : '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  if (apodModel!.mediaType == 'video')
                    const Text(
                      'This APOD is a video. Open the URL from the API in a browser.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  if (apodModel!.mediaType != 'video')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: Image.network(
                          apodModel!.url ?? '',
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 72),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),
                  Text(
                    apodModel!.explanation ?? '',
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                ],
              ),
            ),
    );
  }
}
