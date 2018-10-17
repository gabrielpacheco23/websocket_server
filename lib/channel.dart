import 'chat_websocket.dart';
// import 'model/model.dart';

class ChatWebsocketChannel extends ApplicationChannel {
  ManagedContext context;

  List<WebSocket> websockets = [];

  @override
  Future prepare() async {
    logger.onRecord.listen(
        (rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));

    final config = ChatWebsocketConfiguration(options.configurationFilePath);
    context = contextWithConnectionInfo(config.database);

    messageHub.listen((bytes) {
      sendBytesToConnectedClients(bytes as String/* as List<int> */);
    });
  }

  @override
  Controller get entryPoint {
    final router = Router();

    // router
    //     .route("/model/[:id]")
    //     .link(() => ManagedObjectController<Model>(context));

    router.route("/connect").linkFunction((request) async {
      final websocket = await WebSocketTransformer.upgrade(request.raw);
      websocket.listen(echo, onDone: () {
        websockets.remove(websocket);
      }, cancelOnError: true);

      websockets.add(websocket);

      return null;
    });

    return router;
  }

  void sendBytesToConnectedClients(String str/* List<int> bytes */) {
    websockets.forEach((ws) {
     //ws.add(bytes);
     ws.add(str);
    });
  }

  void echo(dynamic bytes) {
    sendBytesToConnectedClients(bytes as String/*  as List<int> */);
    messageHub.add(bytes as String/* as List<int> */);
  }

  ManagedContext contextWithConnectionInfo(
      DatabaseConfiguration connectionInfo) {
    final dataModel = ManagedDataModel.fromCurrentMirrorSystem();
    final psc = PostgreSQLPersistentStore(
        connectionInfo.username,
        connectionInfo.password,
        connectionInfo.host,
        connectionInfo.port,
        connectionInfo.databaseName);

    return ManagedContext(dataModel, psc);
  }
}

class ChatWebsocketConfiguration extends Configuration {
  ChatWebsocketConfiguration(String fileName) : super.fromFile(File(fileName));

  DatabaseConfiguration database;
}
