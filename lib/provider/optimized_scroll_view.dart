
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Controller for managing reactive state
class MyController extends GetxController {
  final items = <String>[].obs; // Observable list for ListView/GridView
  final scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    // Initialize with sample data
    items.addAll(List.generate(20, (index) => 'Item $index'));
  }

  void addItem() {
    items.add('Item ${items.length}');
  }
}

class MyScrollView extends StatelessWidget {
  const MyScrollView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    Get.put(MyController());

    return Scaffold(
      appBar: AppBar(title: const Text('Optimized ScrollView')),
      body: Column(
        children: [
          // Button to add items (reactive update)
          Obx(() {
            final controller = Get.find<MyController>();
            return ElevatedButton(
              onPressed: controller.addItem,
              child: Text('Add Item (Total: ${controller.items.length})'),
            );
          }),
          // ListView: Constrained to avoid overflow
          Expanded(
            child: Obx(() {
              final controller = Get.find<MyController>();
              return ListView.builder(
                controller: controller.scrollController,
                scrollDirection: Axis.vertical,
                itemCount: controller.items.length,
                cacheExtent: 1000.0, // Pre-render for performance
                itemBuilder: (context, index) {
                  // Wrap only the reactive part in Obx
                  return Obx(() => ListTile(
                    title: Text(controller.items[index]),
                  ));
                },
              );
            }),
          ),
          // GridView: Constrained with fixed cross-axis count
          Expanded(
            child: Obx(() {
              final controller = Get.find<MyController>();
              return GridView.builder(
                controller: controller.scrollController,
                scrollDirection: Axis.vertical,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: controller.items.length,
                cacheExtent: 1000.0, // Pre-render for performance
                itemBuilder: (context, index) {
                  return Obx(() => Card(
                    child: Center(child: Text(controller.items[index])),
                  ));
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}


void main() {
  runApp(const MaterialApp(home: MyScrollView()));
}