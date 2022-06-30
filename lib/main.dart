import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:model_tester_app/test_sceen/test_screen.dart';
import 'package:model_tester_app/widgets/custom_card.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tflite tester',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      darkTheme: ThemeData(
          brightness: Brightness.dark,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
                color: Colors.deepOrange,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          )),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tflite Model Tester',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CustomCard('Simulator', TestScreen(), Icons.grid_3x3,
                tileColor: Colors.deepOrange),
          ],
        ),
      ),
    );
  }
}
