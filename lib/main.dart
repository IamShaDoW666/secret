import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:task_manager_app/firebase_api.dart';
import 'package:task_manager_app/message/data/local/data_sources/messages_data_provider.dart';
import 'package:task_manager_app/message/data/repository/message_repository.dart';
import 'package:task_manager_app/message/presentation/bloc/messages_bloc.dart';
import 'package:task_manager_app/routes/app_router.dart';
import 'package:task_manager_app/bloc_state_observer.dart';
import 'package:task_manager_app/routes/pages.dart';
import 'package:task_manager_app/tasks/data/local/data_sources/tasks_data_provider.dart';
import 'package:task_manager_app/tasks/data/repository/task_repository.dart';
import 'package:task_manager_app/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:task_manager_app/utils/color_palette.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Bloc.observer = BlocStateOberver();
  await FirebaseApi().initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
        create: (context) =>
            TaskRepository(taskDataProvider: TaskDataProvider()),
        child: BlocProvider(
            create: (context) => TasksBloc(context.read<TaskRepository>()),
            child: RepositoryProvider(
              create: (context) =>
                  MessageRepository(messageDataProvider: MessageDataProvider()),
              child: BlocProvider(
                create: (context) =>
                    MessagesBloc(context.read<MessageRepository>()),
                child: MaterialApp(
                  title: 'Task Manager',
                  debugShowCheckedModeBanner: false,
                  initialRoute: Pages.initial,
                  onGenerateRoute: onGenerateRoute,
                  theme: ThemeData(
                    fontFamily: 'Sora',
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                    canvasColor: Colors.black,
                    colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
                    useMaterial3: true,
                  ),
                ),
              ),
            )));
  }
}
