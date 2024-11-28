import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'manage_food_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _targetCostController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _queryDateController = TextEditingController();
  List<Map<String, dynamic>> _foodItems = [];
  List<Map<String, dynamic>> _selectedItems = [];
  Map<String, dynamic>? _queriedOrderPlan; // To store the retrieved order plan

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

  void _toggleSelection(Map<String, dynamic> item) {
    setState(() {
      if (_selectedItems.any((selected) => selected['id'] == item['id'])) {
        _selectedItems.removeWhere((selected) => selected['id'] == item['id']);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  Future<void> _saveOrderPlan() async {
    final targetCost = double.tryParse(_targetCostController.text);
    final date = _dateController.text;

    if (targetCost == null || date.isEmpty || _selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid target cost, date, and select at least one food item')),
      );
      return;
    }

    double totalCost = _selectedItems.fold(
        0.0, (sum, item) => sum + (item['cost'] as double));

    if (totalCost > targetCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Total cost exceeds the target cost')),
      );
      return;
    }

    final db = await DBHelper.instance.database;
    await db.insert('orders', {
      'date': date,
      'food_items': _selectedItems
          .map((item) => item['name'])
          .toList()
          .join(','),
      'target_cost': targetCost,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order plan saved successfully!')),
    );

    setState(() {
      _selectedItems.clear();
      _targetCostController.clear();
      _dateController.clear();
    });
  }

  Future<void> _queryOrderPlan() async {
    final date = _queryDateController.text;

    if (date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date to query')),
      );
      return;
    }

    final orderPlan = await DBHelper.instance.getOrderByDate(date);

    if (orderPlan != null) {
      setState(() {
        _queriedOrderPlan = orderPlan;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No order plan found for the selected date')),
      );
      setState(() {
        _queriedOrderPlan = null;
      });
    }
  }

  // Helper method to format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Ordering App'),
      ),
      body: SingleChildScrollView(
        // Wrap the Column with SingleChildScrollView to prevent overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section to create a new order plan
              Text(
                'Create Order Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _targetCostController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Target Cost (per day)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Select Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _dateController.text.isNotEmpty
                        ? DateTime.parse(_dateController.text)
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dateController.text = _formatDate(pickedDate);
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              Text(
                'Food Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Display food items in a limited height ListView
              Container(
                height: 200,
                child: ListView.builder(
                  itemCount: _foodItems.length,
                  itemBuilder: (context, index) {
                    final item = _foodItems[index];
                    final isSelected = _selectedItems.any((selected) => selected['id'] == item['id']);

                    return ListTile(
                      title: Text(item['name']),
                      subtitle: Text('\$${item['cost']}'),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          _toggleSelection(item);
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveOrderPlan,
                child: Text('Save Order Plan'),
              ),
              SizedBox(height: 32),

              // Section to query order plan
              Text(
                'Query Order Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _queryDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Select Date to Query',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _queryDateController.text.isNotEmpty
                        ? DateTime.parse(_queryDateController.text)
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _queryDateController.text = _formatDate(pickedDate);
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _queryOrderPlan,
                child: Text('View Order Plan'),
              ),
              SizedBox(height: 16),
              _queriedOrderPlan != null
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Plan for ${_queriedOrderPlan!['date']}',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                      'Target Cost: \$${_queriedOrderPlan!['target_cost']}'),
                  SizedBox(height: 8),
                  Text(
                      'Food Items: ${_queriedOrderPlan!['food_items']}'),
                ],
              )
                  : SizedBox.shrink(),
              SizedBox(height: 32),
              // Button to navigate to Manage Food Items screen
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ManageFoodScreen()),
                  ).then((_) {
                    // Refresh food items when returning
                    _fetchFoodItems();
                  });
                },
                child: Text('Manage Food Items'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}