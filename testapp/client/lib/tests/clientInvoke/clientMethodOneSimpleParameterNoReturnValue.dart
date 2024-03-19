import 'package:logging/logging.dart';
import 'package:signalr_client_core/hub_connection.dart';

import '../../views/pages/testsPageViewModel.dart';
import '../test.dart';

class ClientMethodOneSimpleParameterNoReturnValue extends Test {
  // Properties

  // Methods
  ClientMethodOneSimpleParameterNoReturnValue(
      HubConnectionProvider hubConnectionProvider, Logger logger)
      : super(hubConnectionProvider, logger,
            "Client Invokes method 'MethodOneSimpleParameterNoReturnValue");

  @override
  Future<void> executeTest(HubConnection hubConnection) async {
    await hubConnection.invoke("MethodOneSimpleParameterNoReturnValue",
        args: <Object>["ParameterValue"]);
  }
}
