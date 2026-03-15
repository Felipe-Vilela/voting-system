import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class PollOption {
  String text;
  int votes;

  PollOption(this.text, {this.votes = 0});
}

class PollRoom {
  String code;
  String question;
  List<PollOption> options;
  bool isActive;

  PollRoom({
    required this.code,
    required this.question,
    required this.options,
    this.isActive = true,
  });
}

class VotingAppState extends ChangeNotifier {
  List<PollRoom> rooms = [];

  String createRoom(String question, List<String> optionTexts) {
    String code = (1000 + Random().nextInt(9000)).toString(); // Código de 4 dígitos
    List<PollOption> options = optionTexts.map((text) => PollOption(text)).toList();
    
    rooms.add(PollRoom(code: code, question: question, options: options));
    notifyListeners();
    return code;
  }

  PollRoom? getRoom(String code) {
    try {
      return rooms.firstWhere((r) => r.code == code && r.isActive);
    } catch (e) {
      return null; 
    }
  }

  void vote(String roomCode, int optionIndex) {
    var room = getRoom(roomCode);
    if (room != null) {
      room.options[optionIndex].votes++;
      notifyListeners(); 
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VotingAppState(),
      child: MaterialApp(
        title: 'Sistema de Votação',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const MyHomePage(),
      ),
    );
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
        page = const ParticipantPage();
        break;
      case 1:
        page = const AdminPage();
        break;
      default:
        throw UnimplementedError('Nenhum widget para $selectedIndex');
    }

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: MediaQuery.of(context).size.width >= 600,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.person),
                  label: Text('Participante'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.admin_panel_settings),
                  label: Text('Administrador'),
                ),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: page,
            ),
          ),
        ],
      ),
    );
  }
}

class ParticipantPage extends StatefulWidget {
  const ParticipantPage({super.key});

  @override
  State<ParticipantPage> createState() => _ParticipantPageState();
}

class _ParticipantPageState extends State<ParticipantPage> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController(); 
  PollRoom? activeRoom;
  bool hasVoted = false;

  void _joinRoom(VotingAppState appState) {
    var room = appState.getRoom(_codeController.text.trim());
    if (room != null) {
      setState(() {
        activeRoom = room;
        hasVoted = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código de sala inválido ou inativo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<VotingAppState>();

    if (activeRoom != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activeRoom!.question,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (hasVoted)
                    const Text(
                      'Voto registrado com sucesso! Aguarde o administrador encerrar.',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    )
                  else
                    ...List.generate(activeRoom!.options.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: () {
                            appState.vote(activeRoom!.code, index);
                            setState(() {
                              hasVoted = true;
                            });
                          },
                          child: Text(activeRoom!.options[index].text),
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => setState(() => activeRoom = null),
                    child: const Text('Sair da Sala'),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.how_to_vote, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Seu Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Código da Sala',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _joinRoom(appState),
              icon: const Icon(Icons.login),
              label: const Text('Entrar na Votação'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _questionController = TextEditingController();
  final _opt1Controller = TextEditingController();
  final _opt2Controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<VotingAppState>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Criar Nova Votação',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _questionController,
                      decoration: const InputDecoration(
                        labelText: 'Pergunta da Enquete',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _opt1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Opção 1',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _opt2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Opção 2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        if (_questionController.text.isNotEmpty && _opt1Controller.text.isNotEmpty) {
                          appState.createRoom(
                            _questionController.text,
                            [_opt1Controller.text, _opt2Controller.text],
                          );
                          _questionController.clear();
                          _opt1Controller.clear();
                          _opt2Controller.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sala criada com sucesso!')),
                          );
                        }
                      },
                      child: const Text('Gerar Sala e Código', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (appState.rooms.isEmpty)
              const Center(
                child: Text('Nenhuma sala criada ainda.'),
              )
            else
              ...appState.rooms.reversed.map((room) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    room.question,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(
                                    'CÓD: ${room.code}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            ...room.options.map((opt) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(opt.text, style: const TextStyle(fontSize: 16))),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${opt.votes} votos',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}