import 'package:shahkar_connect/core/api/models.dart';

NodeCandidate? nextCandidate(
  List<NodeCandidate> ranked,
  NodeCandidate current,
) {
  final i = ranked.indexWhere((n) => n.id == current.id);
  if (i < 0 || i + 1 >= ranked.length) return null;
  return ranked[i + 1];
}
