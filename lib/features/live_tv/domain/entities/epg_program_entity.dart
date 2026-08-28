import 'package:equatable/equatable.dart';

/// The "what's on now" program for a channel — powers the premium Live TV
/// list's subtitle + elapsed-time progress bar.
class EpgProgramEntity extends Equatable {
  final String title;
  final DateTime start;
  final DateTime end;

  const EpgProgramEntity({required this.title, required this.start, required this.end});

  /// 0..1 how far through the program we are right now.
  double get progress {
    final now = DateTime.now();
    final totalSeconds = end.difference(start).inSeconds;
    if (totalSeconds <= 0) return 0;
    if (now.isBefore(start)) return 0;
    if (now.isAfter(end)) return 1;
    return now.difference(start).inSeconds / totalSeconds;
  }

  @override
  List<Object?> get props => [title, start, end];
}
