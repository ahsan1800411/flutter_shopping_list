import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> groceryItems = [];
  late Future<List<GroceryItem>> loadedGroceryItems;

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
      'shopping-list.json',
    );

    final response = await http.get(url);
    if (response.body == 'null') {
      return [];
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    final List<GroceryItem> loadedItems = [];
    data.forEach(
      (itemId, itemData) {
        loadedItems.add(
          GroceryItem(
            id: itemId,
            name: itemData['name'],
            quantity: itemData['quantity'],
            category: categories.entries
                .firstWhere(
                    (entry) => entry.value.title == itemData['category'])
                .value,
          ),
        );
      },
    );
    return loadedItems;
  }

  void _addNewItem() async {
    final newItem =
        await Navigator.of(context).push<GroceryItem>(MaterialPageRoute(
      builder: (ctx) => const NewItem(),
    ));
    if (newItem != null) {
      setState(() {
        groceryItems.add(newItem);
      });
    }
  }

  void _removeItem(GroceryItem item) {
    setState(() {
      groceryItems.remove(item);
    });

    final url = Uri.https(
      'shopping-list/${item.id}.json',
    );

    http.delete(url);
  }

  @override
  void initState() {
    super.initState();
    loadedGroceryItems = _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewItem,
          ),
        ],
      ),
      body: FutureBuilder(
        future: loadedGroceryItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.error != null) {
            return const Center(
              child: Text('An error occurred!'),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (ctx, index) {
                final grocery = snapshot.data![index];
                return Dismissible(
                  key: ValueKey(grocery.id),
                  onDismissed: (direction) {
                    _removeItem(grocery);
                  },
                  child: ListTile(
                    trailing: Text(
                      '${grocery.quantity}x',
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    leading: Container(
                      width: 24,
                      height: 24,
                      color: grocery.category.color,
                    ),
                    title: Text(grocery.name),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
