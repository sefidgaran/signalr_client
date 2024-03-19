import 'package:signal_r_client/hub_connection.dart';

import '../../views/pages/testsPageViewModel.dart';
import '../test.dart';
import 'package:logging/logging.dart';

class ClientMethodNoParametersSimpleReturnValue extends Test {
  // Properties

  // Methods
  ClientMethodNoParametersSimpleReturnValue(
      HubConnectionProvider hubConnectionProvider, Logger logger)
      : super(hubConnectionProvider, logger,
            "Client Invokes method: 'MethodNoParametersSimpleReturnValue");

  @override
  Future<void> executeTest(HubConnection hubConnection) async {
    final result =
        await hubConnection.invoke("MethodNoParametersSimpleReturnValue");
    logger.info("Result: '$result");
  }
}
