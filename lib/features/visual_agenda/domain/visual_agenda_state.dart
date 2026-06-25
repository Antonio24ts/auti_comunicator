import 'visual_agenda_item.dart';

class VisualAgendaState {
  final VisualAgendaItem? nowItem;
  final List<VisualAgendaItem> afterItems;
  final List<VisualAgendaItem> doneItems;

  const VisualAgendaState({
    required this.nowItem,
    required this.afterItems,
    required this.doneItems,
  });

  factory VisualAgendaState.empty() {
    return const VisualAgendaState(
      nowItem: null,
      afterItems: [],
      doneItems: [],
    );
  }

  bool get isEmpty {
    return nowItem == null && afterItems.isEmpty && doneItems.isEmpty;
  }

  bool get hasAgenda {
    return nowItem != null || afterItems.isNotEmpty || doneItems.isNotEmpty;
  }

  bool get isFinished {
    return nowItem == null && afterItems.isEmpty && doneItems.isNotEmpty;
  }

  VisualAgendaState copyWith({
    VisualAgendaItem? nowItem,
    bool clearNowItem = false,
    List<VisualAgendaItem>? afterItems,
    List<VisualAgendaItem>? doneItems,
  }) {
    return VisualAgendaState(
      nowItem: clearNowItem ? null : nowItem ?? this.nowItem,
      afterItems: afterItems ?? this.afterItems,
      doneItems: doneItems ?? this.doneItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nowItem': nowItem?.toJson(),
      'afterItems': afterItems.map((item) => item.toJson()).toList(),
      'doneItems': doneItems.map((item) => item.toJson()).toList(),
    };
  }

  factory VisualAgendaState.fromJson(Map<String, dynamic> json) {
    final rawNowItem = json['nowItem'];
    final rawAfterItems = json['afterItems'];
    final rawDoneItems = json['doneItems'];

    return VisualAgendaState(
      nowItem: rawNowItem is Map<String, dynamic>
          ? VisualAgendaItem.fromJson(rawNowItem)
          : null,
      afterItems: rawAfterItems is List
          ? rawAfterItems
                .whereType<Map<String, dynamic>>()
                .map(VisualAgendaItem.fromJson)
                .where((item) => item.text.trim().isNotEmpty)
                .toList()
          : <VisualAgendaItem>[],
      doneItems: rawDoneItems is List
          ? rawDoneItems
                .whereType<Map<String, dynamic>>()
                .map(VisualAgendaItem.fromJson)
                .where((item) => item.text.trim().isNotEmpty)
                .toList()
          : <VisualAgendaItem>[],
    );
  }
}
