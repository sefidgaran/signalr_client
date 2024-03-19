import 'package:logging/logging.dart';
import 'package:signalr_client_core/hub_connection.dart';

import '../../views/pages/testsPageViewModel.dart';
import '../test.dart';

class ClientMethodOneSimpleParameterSimpleReturnValue extends Test {
  // Properties

  // Methods
  ClientMethodOneSimpleParameterSimpleReturnValue(
      HubConnectionProvider hubConnectionProvider, Logger logger)
      : super(hubConnectionProvider, logger,
            "Client Invokes method 'MethodOneSimpleParameterSimpleReturnValue");

  @override
  Future<void> executeTest(HubConnection hubConnection) async {
    final result = await hubConnection.invoke(
        "MethodOneSimpleParameterSimpleReturnValue",
        args: <Object>["ParameterValue"]);
    logger.info("Result: '$result");
  }
}
