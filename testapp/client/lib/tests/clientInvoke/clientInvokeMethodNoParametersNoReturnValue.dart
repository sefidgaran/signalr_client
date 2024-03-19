import 'package:signal_r_client/hub_connection.dart';

import '../../views/pages/testsPageViewModel.dart';
import '../test.dart';
import 'package:logging/logging.dart';

class ClientMethodNoParametersNoReturnValue extends Test {
  // Properties

  // Methods
  ClientMethodNoParametersNoReturnValue(
      HubConnectionProvider hubConnectionProvider, Logger logger)
      : super(hubConnectionProvider, logger,
            "Client Invokes method: 'MethodNoParametersNoReturnValue");

  @override
  Future<void> executeTest(HubConnection hubConnection) async {
    await hubConnection.invoke("MethodNoParametersNoReturnValue");
  }
}
