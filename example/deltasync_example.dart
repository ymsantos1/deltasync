import 'package:deltasync/deltasync.dart';

void main() {
  final replica = Replica('device-a');
  final delta = replica.setDelta('message', 'edited offline');
  final remote = Replica('device-b')..apply(Delta.crdt([delta]));
  print(remote.state.values);
}
