import 'package:deltasync/deltasync.dart';

void main() {
  final replica = Replica('device-a');
  replica.set('message', 'edited offline');
  print(replica.state.values);
}
