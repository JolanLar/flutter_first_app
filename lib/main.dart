import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:english_words/english_words.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => MyAppState(),
        child: MaterialApp(
          title: 'Clicker manager',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepOrange
            ),
            useMaterial3: true,
          ),
          home: const MyHomePage(),
      )
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var history = <WordPair>[];

  GlobalKey? historyListKey;

  void getNext() {
    history.insert(0, current);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite(WordPair pair) {
    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const GeneratorPage();
        break;
      case 1:
        page = const FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    var colorScheme = Theme.of(context).colorScheme;

    var mainArea = ColoredBox(
        color: colorScheme.surfaceVariant,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: page,
        )
    );

    return LayoutBuilder(
      builder: (context, constraint) {
        return Scaffold(
          body: Column(
              children: [
                Expanded(child: mainArea),
                SafeArea(
                    child: BottomNavigationBar(
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home),
                          label: 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.favorite),
                          label: 'Favorites',
                        )
                      ],
                      currentIndex: selectedIndex,
                      onTap: (value) {
                        setState(() {
                          selectedIndex = value;
                        });
                      },
                    )
                ),
              ]
          )
        );
      }
    );
  }
}

class GeneratorPage extends StatelessWidget {
  const GeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(
              flex: 3,
              child: HistoryListView(),
            ),
            const SizedBox(height: 10),
            BigCard(pair: pair),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                    onPressed: () {
                      appState.toggleFavorite(pair);
                    },
                    icon: Icon(icon),
                    label: const Text('Like')
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    appState.getNext();
                  },
                  child: const Text('Next')
                )
              ]
            ),
            const Spacer(flex: 1)
          ],
        )
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(pair.join(" "), style: style,)
      )
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var favorites = appState.favorites;

    if (favorites.isEmpty) {
      return const Center(
        child: Text('No favorites yet.'),
      );
    }

    var theme = Theme.of(context);

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
            '${favorites.length} favorites:'),
        ),
        for (var fav in favorites)...[
          ListTile(
            leading: IconButton(
              icon: const Icon(Icons.favorite),
              color: theme.colorScheme.primary,
              onPressed: () {
                appState.toggleFavorite(fav);
              },
            ),
            title: Text(fav.join(" ")),
          )
        ]
      ],
    );
  }

}

class HistoryListView extends StatefulWidget {
  const HistoryListView({super.key});

  @override
  State<StatefulWidget> createState() =>
      _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
  final _key = GlobalKey();

  static const Gradient _maskingGradient = LinearGradient(
    // This gradient goes from fully transparent to fully opaque black...
    colors: [Colors.transparent, Colors.black],
    // ... from the top (transparent) to half (0.5) of the way to the bottom.
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: true,
        padding: const EdgeInsets.only(top: 10),
        initialItemCount: appState.history.length,
        itemBuilder: (context, index, animation) {
          final pair = appState.history[index];
          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: TextButton.icon(
                onPressed: () { appState.toggleFavorite(pair); },
                icon: appState.favorites.contains(pair)
                  ? const Icon(Icons.favorite)
                  : const SizedBox(),
                label: Text(pair.join(" "))
              ),
            ),
          );
        }
      ),
    );
  }

}