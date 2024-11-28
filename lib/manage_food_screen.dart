import 'package:flutter/material.dart';
import 'db_helper.dart';

class ManageFoodScreen extends StatefulWidget {
  @override
  _ManageFoodScreenState createState() => _ManageFoodScreenState();
}

class _ManageFoodScreenState extends State<ManageFoodScreen> {
  List<Map<String, dynamic>> _foodItems = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  int? _editingId;

  @override
  void initState() {
    super.initState();
    _fetchFoodItems();
  }

  Future<void> _fetchFoodItems() async {
    final db = await DBHelper.instance.database;
    final foodItems = await db.query('foods');
    setState(() {
      _foodItems = foodItems;
    });
  }

  Future<void> _addOrUpdateFood() async {
    final name = _nameController.text.trim();
    final cost = double.tryParse(_costController.text.trim());

    if (name.isEmpty || cost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid food name and cost')),
      );
      return;
    }

    final db = await DBHelper.instance.database;

    if (_editingId == null) {
      // Add new food
      await db.insert('foods', {'name': name, 'cost': cost});
    } else {
      // Update existing food
      await db.update(
        'foods',
        {'name': name, 'cost': cost},
        where: 'id = ?',
        whereArgs: [_editingId],
      );
    }

    _nameController.clear();
    _costController.clear();
    _editingId = null;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Food item saved successfully!')),
    );

    _fetchFoodItems();
    Navigator.of(context).pop();
  }

  Future<void> _deleteFood(int id) async {
    final db = await DBHelper.instance.database;
    await db.delete('foods', where: 'id = ?', whereArgs: [id]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Food item deleted')),
    );
    _fetchFoodItems();
  }

  void _showAddEditDialog({Map<String, dynamic>? food}) {
    if (food != null) {
      _editingId = food['id'];
      _nameController.text = food['name'];
      _costController.text = food['cost'].toString();
    } else {
      _editingId = null;
      _nameController.clear();
      _costController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingId == null ? 'Add Food' : 'Edit Food'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Food Name'),
            ),
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Cost'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addOrUpdateFood,
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Food Items'),
      ),
      body: ListView.builder(
        itemCount: _foodItems.length,
        itemBuilder: (context, index) {
          final food = _foodItems[index];
          return ListTile(
            title: Text(food['name']),
            subtitle: Text('\$${food['cost']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showAddEditDialog(food: food),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteFood(food['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}
