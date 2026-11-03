import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'api_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiController _apiController = ApiController();
  final TextEditingController _cravingController = TextEditingController();
  final List<UlamRecipe> _orders = [];
  late Future<List<UlamRecipe>> _recipesFuture;
  int _selectedPage = 0;
  String _submittedCraving = '';

  @override
  void initState() {
    super.initState();
    _recipesFuture = _apiController.getRecipes();
  }

  @override
  void dispose() {
    _cravingController.dispose();
    _apiController.close();
    super.dispose();
  }

  void _findUlam() {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedPage = 0;
      _submittedCraving = _cravingController.text.trim();
    });
  }

  List<UlamRecipe> _filterRecipes(List<UlamRecipe> recipes) {
    final terms = _submittedCraving
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((term) => term.length > 1)
        .toList();
    if (terms.isEmpty) return recipes;

    return recipes.where((recipe) {
      final searchableText = [
        recipe.name,
        recipe.cuisine,
        ...recipe.ingredients,
        ...recipe.mealTypes,
      ].join(' ').toLowerCase();
      return terms.any(searchableText.contains);
    }).toList();
  }

  void _addIngredient(String ingredient) {
    final current = _cravingController.text.trim();
    final ingredients = current.isEmpty ? ingredient : '$current, $ingredient';
    _cravingController.value = TextEditingValue(
      text: ingredients,
      selection: TextSelection.collapsed(offset: ingredients.length),
    );
    setState(() => _submittedCraving = ingredients);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void _placeOrder(UlamRecipe ulam) {
    setState(() => _orders.add(ulam));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${ulam.name} added to your order.'),
          action: SnackBarAction(
            label: 'VIEW ORDER',
            onPressed: () => setState(() => _selectedPage = 1),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email?.split('@').first ?? 'Kaibigan');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ma'ano Ulam?",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'My orders',
            onPressed: () => setState(() => _selectedPage = 1),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(user, displayName),
      body: SafeArea(
        child: _selectedPage == 0
            ? _buildDashboard(displayName)
            : _buildOrdersPage(),
      ),
    );
  }

  Widget _buildDrawer(User? user, String displayName) {
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationDrawer(
      selectedIndex: _selectedPage,
      onDestinationSelected: (index) {
        Navigator.pop(context);
        if (index < 2) {
          setState(() => _selectedPage = index);
        } else {
          _signOut();
        }
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.restaurant, color: colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                user?.email ?? '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Ulam finder'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: Text('My orders'),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 12, 16, 8),
          child: Divider(),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.logout),
          label: Text('Sign out'),
        ),
      ],
    );
  }

  Widget _buildDashboard(String displayName) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          'Kumusta, $displayName!',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Craving something? Tell us what you have in mind.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          margin: EdgeInsets.zero,
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What are you craving?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cravingController,
                  onChanged: (value) {
                    setState(() => _submittedCraving = value.trim());
                  },
                  onSubmitted: (_) => _findUlam(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'e.g. chicken, garlic, kangkong',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ['Chicken', 'Pork', 'Vegetables', 'Eggplant']
                      .map(
                        (ingredient) => InputChip(
                          label: Text(ingredient),
                          onPressed: () => _addIngredient(ingredient),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _findUlam,
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Find my ulam'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _submittedCraving.isEmpty
              ? 'Popular ulam today'
              : 'Suggestions for "$_submittedCraving"',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<UlamRecipe>>(
          future: _recipesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.wifi_off, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        'Could not load the ulam catalog: ${snapshot.error}',
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () {
                          setState(
                            () => _recipesFuture = _apiController.getRecipes(),
                          );
                        },
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final recipes = _filterRecipes(snapshot.data ?? const []);
            if (recipes.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, size: 36),
                      const SizedBox(height: 8),
                      const Text('No ulam matched those ingredients yet.'),
                      TextButton(
                        onPressed: () {
                          _cravingController.clear();
                          setState(() => _submittedCraving = '');
                        },
                        child: const Text('See popular ulam'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: recipes.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => _buildUlamCard(recipes[index]),
            );
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: const Icon(Icons.delivery_dining),
            ),
            title: const Text('Made fresh, delivered to you'),
            subtitle: const Text(
              'Choose a ulam and we’ll prepare it just for you.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUlamCard(UlamRecipe ulam) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 72,
                height: 72,
                child: ulam.imageUrl.isEmpty
                    ? ColoredBox(
                        color: colorScheme.secondaryContainer,
                        child: Icon(
                          Icons.restaurant,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      )
                    : Image.network(
                        ulam.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            ColoredBox(
                              color: colorScheme.secondaryContainer,
                              child: Icon(
                                Icons.restaurant,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        ulam.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(ulam.cuisine),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  Text(
                    'Ingredients: ${ulam.ingredients.join(', ')}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ulam.prepTimeMinutes + ulam.cookTimeMinutes} min · '
                    '${ulam.servings} servings',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Est. ₱${ulam.estimatedPrice}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const Spacer(),
                      FilledButton.tonal(
                        onPressed: () => _placeOrder(ulam),
                        child: const Text('Order'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'My orders',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text('Your selected ulam and order total.'),
        const SizedBox(height: 20),
        if (_orders.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text('No ulam selected yet'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => setState(() => _selectedPage = 0),
                    child: const Text('Find something to eat'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          ..._orders.map(
            (ulam) => Card(
              child: ListTile(
                leading: const Icon(Icons.restaurant),
                title: Text(ulam.name),
                subtitle: Text('${ulam.cuisine} · ${ulam.servings} servings'),
                trailing: Text(
                  '₱${ulam.estimatedPrice}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Estimated total'),
              trailing: Text(
                '₱${_orders.fold<int>(0, (total, ulam) => total + ulam.estimatedPrice)}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
