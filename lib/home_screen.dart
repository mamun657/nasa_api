import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nasa_api/apod_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ApodModel? apodModel;

  Future<void> fetchData() async {
    final url = Uri.parse(
      "https://api.nasa.gov/planetary/apod?api_key=nKbmC5xUZBLot7dy5GSIXMEkeaIj7jiMFI79DO6E",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        apodModel = ApodModel.fromJson(jsonDecode(response.body));
        setState(() {});
      } else {
        debugPrint("error : ${response.statusCode}");
      }
    } catch (e) {
      debugPrint(e.toString());
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
        backgroundColor: Colors.blue,
        title: const Text('Nasa API'),
      ),
      body: apodModel == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                children: [
                  Text(
                    apodModel?.title ?? 'none',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  
                  if (apodModel?.url != null && apodModel!.url!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 400, 
                        ),
                        child: Image.network(
                          apodModel!.url!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stack) =>
                              const Icon(Icons.error, size: 100),
                        ),
                      ),
                    )
                  else
                    const Icon(Icons.image_not_supported, size: 100),

                  const SizedBox(height: 12),
                  Text(
                    apodModel?.explanation ?? '',
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
