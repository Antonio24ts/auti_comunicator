import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/models/pictogram.dart';
import '../../../../data/repositories/pictogram_repository.dart';
import '../../../../services/speech_services.dart';
import '../../data/visual_agenda_service.dart';
import '../../domain/visual_agenda_item.dart';
import '../../domain/visual_agenda_state.dart';
import '../../../favorites/data/favorite_pictograms_service.dart';
import '../../../recent_phrases/data/recent_phrases_service.dart';
import '../../../recent_phrases/domain/recent_phrase.dart';

enum _VisualAgendaMode { child, editor }

class VisualAgendaPanel extends StatefulWidget {
  final String childName;
  final PictogramRepository repository;
  final SpeechService speechService;

  const VisualAgendaPanel({
    super.key,
    required this.childName,
    required this.repository,
    required this.speechService,
  });

  @override
  State<VisualAgendaPanel> createState() => _VisualAgendaPanelState();
}

class _VisualAgendaPanelState extends State<VisualAgendaPanel> {
  final VisualAgendaService _visualAgendaService = VisualAgendaService();

  final FavoritePictogramsService _favoritePictogramsService =
      FavoritePictogramsService();

  final RecentPhrasesService _recentPhrasesService = RecentPhrasesService();

  List<Pictogram> _favoritePictograms = [];
  List<RecentPhrase> _recentPhrases = [];

  bool _isAgendaMuted = false;

  _VisualAgendaMode _mode = _VisualAgendaMode.child;

  VisualAgendaState _agendaState = VisualAgendaState.empty();

  final List<VisualAgendaItem> _draftItems = [];
  final List<String> _editorCategoryHistory = [];

  String _editorCategoryId = PictogramRepository.homeMainCategoryId;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    unawaited(_loadAgenda());
  }

  Future<void> _loadAgenda() async {
    final agendaState = await _visualAgendaService.loadAgenda(
      childName: widget.childName,
    );

    final favoriteIds = await _favoritePictogramsService.loadFavoriteIds(
      childName: widget.childName,
    );

    final favoritePictograms = favoriteIds
        .map((id) => widget.repository.getPictogramById(id))
        .whereType<Pictogram>()
        .toList();

    final recentPhrases = await _recentPhrasesService.loadRecentPhrases(
      childName: widget.childName,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _agendaState = agendaState;
      _favoritePictograms = favoritePictograms;
      _recentPhrases = recentPhrases;
      _isLoading = false;
    });
  }

  void _toggleAgendaMute() {
    setState(() {
      _isAgendaMuted = !_isAgendaMuted;
    });
  }

  Future<void> _speakAgendaPhrase(String text) async {
    if (_isAgendaMuted) {
      return;
    }

    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    await widget.speechService.speakPhrase(cleanText);
  }

  void _speakAgendaWord(String text) {
    if (_isAgendaMuted) {
      return;
    }

    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    unawaited(widget.speechService.speakWord(cleanText));
  }

  Future<void> _saveAgendaState(VisualAgendaState agendaState) async {
    await _visualAgendaService.saveAgenda(
      childName: widget.childName,
      agendaState: agendaState,
    );
  }

  void _enterEditorMode() {
    setState(() {
      _mode = _VisualAgendaMode.editor;
      _draftItems
        ..clear()
        ..addAll(_getCurrentAgendaAsLinearList());
      _editorCategoryId = PictogramRepository.homeMainCategoryId;
      _editorCategoryHistory.clear();
    });
  }

  List<VisualAgendaItem> _getCurrentAgendaAsLinearList() {
    return [
      if (_agendaState.nowItem != null) _agendaState.nowItem!,
      ..._agendaState.afterItems,
    ];
  }

  void _cancelEditorMode() {
    setState(() {
      _mode = _VisualAgendaMode.child;
      _draftItems.clear();
      _editorCategoryHistory.clear();
      _editorCategoryId = PictogramRepository.homeMainCategoryId;
    });
  }

  Future<void> _saveDraftAgenda() async {
    if (_draftItems.isEmpty || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final newAgendaState = VisualAgendaState(
      nowItem: _draftItems.first,
      afterItems: _draftItems.skip(1).toList(),
      doneItems: [],
    );

    await _saveAgendaState(newAgendaState);

    if (!mounted) {
      return;
    }

    setState(() {
      _agendaState = newAgendaState;
      _mode = _VisualAgendaMode.child;
      _draftItems.clear();
      _editorCategoryHistory.clear();
      _editorCategoryId = PictogramRepository.homeMainCategoryId;
      _isSaving = false;
    });

    unawaited(
      _speakAgendaPhrase(
        'Agenda preparada. Ahora toca ${newAgendaState.nowItem?.text ?? ''}',
      ),
    );
  }

  void _addDraftItem(Pictogram pictogram) {
    if (!_canUsePictogramAsAgendaItem(pictogram)) {
      return;
    }

    final item = VisualAgendaItem.fromPictogram(pictogram);

    setState(() {
      _draftItems.add(item);
    });

    _speakAgendaWord(item.text);
  }

  void _addRecentPhraseDraftItem(RecentPhrase recentPhrase) {
    final cleanText = recentPhrase.text.trim();

    if (cleanText.isEmpty || recentPhrase.items.isEmpty) {
      return;
    }

    final firstItemWithImage = recentPhrase.items.firstWhere(
      (item) => item.imagePath.trim().isNotEmpty,
      orElse: () => recentPhrase.items.first,
    );

    final agendaItem = VisualAgendaItem(
      pictogramId: recentPhrase.id,
      text: cleanText,
      imagePath: firstItemWithImage.imagePath,
    );

    setState(() {
      _draftItems.add(agendaItem);
    });

    _speakAgendaWord(cleanText);
  }

  bool _canUsePictogramAsAgendaItem(Pictogram pictogram) {
    if (pictogram.isCategory) {
      return false;
    }

    if (pictogram.isKeyboardAction) {
      return false;
    }

    final cleanText = pictogram.text.trim();

    return cleanText.isNotEmpty && pictogram.imagePath.trim().isNotEmpty;
  }

  void _removeLastDraftItem() {
    if (_draftItems.isEmpty) {
      return;
    }

    setState(() {
      _draftItems.removeLast();
    });
  }

  void _clearDraftItems() {
    if (_draftItems.isEmpty) {
      return;
    }

    setState(() {
      _draftItems.clear();
    });
  }

  void _handleEditorPictogramTap(Pictogram pictogram) {
    if (pictogram.isCategory) {
      _openEditorCategory(pictogram);
      return;
    }

    _addDraftItem(pictogram);
  }

  void _openEditorCategory(Pictogram pictogram) {
    final targetCategoryId = pictogram.targetCategoryId;

    if (targetCategoryId == null || targetCategoryId.trim().isEmpty) {
      return;
    }

    if (targetCategoryId == _editorCategoryId) {
      return;
    }

    setState(() {
      _editorCategoryHistory.add(_editorCategoryId);
      _editorCategoryId = targetCategoryId;
    });
  }

  void _goBackEditorCategory() {
    if (_editorCategoryHistory.isEmpty) {
      return;
    }

    setState(() {
      _editorCategoryId = _editorCategoryHistory.removeLast();
    });
  }

  void _goHomeEditorCategory() {
    setState(() {
      _editorCategoryId = PictogramRepository.homeMainCategoryId;
      _editorCategoryHistory.clear();
    });
  }

  Future<void> _speakNow() async {
    final nowItem = _agendaState.nowItem;

    if (nowItem == null) {
      await _speakAgendaPhrase('No hay actividad ahora');
      return;
    }

    await _speakAgendaPhrase('Ahora toca ${nowItem.text}');
  }

  Future<void> _speakAfter() async {
    if (_agendaState.afterItems.isEmpty) {
      await _speakAgendaPhrase('No hay nada después');
      return;
    }

    final nextItem = _agendaState.afterItems.first;

    await _speakAgendaPhrase('Después toca ${nextItem.text}');
  }

  Future<void> _goToNextAgendaItem() async {
    final nowItem = _agendaState.nowItem;

    if (nowItem == null && _agendaState.afterItems.isEmpty) {
      await _speakAgendaPhrase('Agenda terminada');
      return;
    }

    final updatedDoneItems = List<VisualAgendaItem>.from(
      _agendaState.doneItems,
    );

    if (nowItem != null) {
      updatedDoneItems.add(nowItem);
    }

    final nextNowItem = _agendaState.afterItems.isEmpty
        ? null
        : _agendaState.afterItems.first;

    final updatedAfterItems = _agendaState.afterItems.isEmpty
        ? <VisualAgendaItem>[]
        : _agendaState.afterItems.skip(1).toList();

    final newAgendaState = VisualAgendaState(
      nowItem: nextNowItem,
      afterItems: updatedAfterItems,
      doneItems: updatedDoneItems,
    );

    await _saveAgendaState(newAgendaState);

    if (!mounted) {
      return;
    }

    setState(() {
      _agendaState = newAgendaState;
    });

    if (nextNowItem == null) {
      await _speakAgendaPhrase('Agenda terminada');
      return;
    }

    if (nowItem == null) {
      await _speakAgendaPhrase('Ahora toca ${nextNowItem.text}');
      return;
    }

    await _speakAgendaPhrase(
      'Terminado ${nowItem.text}. Ahora toca ${nextNowItem.text}',
    );
  }

  Future<void> _clearAgenda() async {
    await _visualAgendaService.clearAgenda(childName: widget.childName);

    if (!mounted) {
      return;
    }

    setState(() {
      _agendaState = VisualAgendaState.empty();
    });

    unawaited(_speakAgendaPhrase('Agenda borrada'));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_mode) {
      case _VisualAgendaMode.child:
        return _buildChildMode();
      case _VisualAgendaMode.editor:
        return _buildEditorMode();
    }
  }

  Widget _buildChildMode() {
    final cleanChildName = widget.childName.trim();
    final title = cleanChildName.isEmpty
        ? 'Agenda visual'
        : 'Agenda visual de $cleanChildName';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _AgendaHeader(
            title: title,
            subtitle: 'Mira qué toca ahora, qué viene después y qué terminó.',
            icon: Icons.event_note_rounded,
            iconColor: Colors.indigo.shade800,
            trailing: OutlinedButton.icon(
              onLongPress: _enterEditorMode,
              onPressed: null,
              icon: const Icon(Icons.edit_calendar_rounded),
              label: const Text('Mantén para editar'),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _agendaState.isEmpty
                ? _EmptyAgendaMessage(onEditLongPress: _enterEditorMode)
                : _AgendaColumns(
                    agendaState: _agendaState,
                    onSpeakNowItem: (item) {
                      unawaited(_speakAgendaPhrase('Ahora toca ${item.text}'));
                    },
                    onSpeakAfterItem: (item) {
                      unawaited(
                        _speakAgendaPhrase('Después toca ${item.text}'),
                      );
                    },
                    onSpeakDoneItem: (item) {
                      unawaited(_speakAgendaPhrase('Terminado ${item.text}'));
                    },
                  ),
          ),
          const SizedBox(height: 12),
          _AgendaChildActions(
            hasAgenda: _agendaState.hasAgenda,
            isAgendaMuted: _isAgendaMuted,
            onSpeakNow: () {
              unawaited(_speakNow());
            },
            onSpeakAfter: () {
              unawaited(_speakAfter());
            },
            onNext: () {
              unawaited(_goToNextAgendaItem());
            },
            onClearLongPress: () {
              unawaited(_clearAgenda());
            },
            onToggleMuteLongPress: _toggleAgendaMute,
          ),
        ],
      ),
    );
  }

  List<Pictogram> _getEditorPictograms() {
    if (_editorCategoryId == 'favoritos') {
      return _favoritePictograms;
    }

    if (_editorCategoryId == 'frases_recientes') {
      return [];
    }

    return widget.repository.getPictogramsByCategory(_editorCategoryId);
  }

  Widget _buildEditorMode() {
    final pictograms = _getEditorPictograms();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _AgendaHeader(
            title: 'Crear agenda visual',
            subtitle: 'Toca pictogramas en el orden en que van a ocurrir.',
            icon: Icons.edit_calendar_rounded,
            iconColor: Colors.indigo.shade800,
            trailing: Text(
              '${_draftItems.length} elegidos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.indigo.shade800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DraftAgendaStrip(draftItems: _draftItems),
          const SizedBox(height: 12),
          _EditorNavigationBar(
            canGoBack: _editorCategoryHistory.isNotEmpty,
            onBack: _goBackEditorCategory,
            onHome: _goHomeEditorCategory,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _editorCategoryId == 'frases_recientes'
                ? _EditorRecentPhrasesGrid(
                    recentPhrases: _recentPhrases,
                    onRecentPhraseTap: _addRecentPhraseDraftItem,
                  )
                : _EditorPictogramGrid(
                    pictograms: pictograms,
                    onPictogramTap: _handleEditorPictogramTap,
                  ),
          ),
          const SizedBox(height: 12),
          _AgendaEditorActions(
            canSave: _draftItems.isNotEmpty && !_isSaving,
            isSaving: _isSaving,
            onCancel: _cancelEditorMode,
            onRemoveLast: _removeLastDraftItem,
            onClear: _clearDraftItems,
            onSave: () {
              unawaited(_saveDraftAgenda());
            },
          ),
        ],
      ),
    );
  }
}

class _AgendaHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget trailing;

  const _AgendaHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 36, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 27,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        trailing,
      ],
    );
  }
}

class _EmptyAgendaMessage extends StatelessWidget {
  final VoidCallback onEditLongPress;

  const _EmptyAgendaMessage({required this.onEditLongPress});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.indigo.shade200, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note_rounded,
              size: 74,
              color: Colors.indigo.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay agenda preparada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: Colors.blueGrey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mantén pulsado el botón para crear una agenda con pictogramas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onLongPress: onEditLongPress,
              onPressed: null,
              icon: const Icon(Icons.edit_calendar_rounded),
              label: const Text('Mantén para crear agenda'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaColumns extends StatelessWidget {
  final VisualAgendaState agendaState;
  final ValueChanged<VisualAgendaItem> onSpeakNowItem;
  final ValueChanged<VisualAgendaItem> onSpeakAfterItem;
  final ValueChanged<VisualAgendaItem> onSpeakDoneItem;

  const _AgendaColumns({
    required this.agendaState,
    required this.onSpeakNowItem,
    required this.onSpeakAfterItem,
    required this.onSpeakDoneItem,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AgendaColumn(
            title: 'Ahora',
            icon: Icons.play_circle_fill_rounded,
            color: Colors.blue,
            items: [if (agendaState.nowItem != null) agendaState.nowItem!],
            emptyText: 'Nada ahora',
            largeFirstItem: true,
            onItemTap: onSpeakNowItem,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AgendaColumn(
            title: 'Después',
            icon: Icons.arrow_forward_rounded,
            color: Colors.orange,
            items: agendaState.afterItems,
            emptyText: 'Nada después',
            largeFirstItem: false,
            onItemTap: onSpeakAfterItem,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AgendaColumn(
            title: 'Terminado',
            icon: Icons.check_circle_rounded,
            color: Colors.green,
            items: agendaState.doneItems,
            emptyText: 'Nada terminado',
            largeFirstItem: false,
            onItemTap: onSpeakDoneItem,
          ),
        ),
      ],
    );
  }
}

class _AgendaColumn extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<VisualAgendaItem> items;
  final String emptyText;
  final bool largeFirstItem;
  final ValueChanged<VisualAgendaItem> onItemTap;

  const _AgendaColumn({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.emptyText,
    required this.largeFirstItem,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.blueGrey.shade500,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return _AgendaItemCard(
                        item: item,
                        color: color,
                        isLarge: largeFirstItem && index == 0,
                        onTap: () => onItemTap(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AgendaItemCard extends StatelessWidget {
  final VisualAgendaItem item;
  final Color color;
  final bool isLarge;
  final VoidCallback onTap;

  const _AgendaItemCard({
    required this.item,
    required this.color,
    required this.isLarge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageHeight = isLarge ? 118.0 : 68.0;
    final fontSize = isLarge ? 22.0 : 16.0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.45), width: 2),
          ),
          child: Column(
            children: [
              SizedBox(
                height: imageHeight,
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) {
                    return Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.blueGrey.shade400,
                      size: 40,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaChildActions extends StatelessWidget {
  final bool hasAgenda;
  final bool isAgendaMuted;
  final VoidCallback onSpeakNow;
  final VoidCallback onSpeakAfter;
  final VoidCallback onNext;
  final VoidCallback onClearLongPress;
  final VoidCallback onToggleMuteLongPress;

  const _AgendaChildActions({
    required this.hasAgenda,
    required this.isAgendaMuted,
    required this.onSpeakNow,
    required this.onSpeakAfter,
    required this.onNext,
    required this.onClearLongPress,
    required this.onToggleMuteLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: hasAgenda && !isAgendaMuted ? onSpeakNow : null,
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('Hablar ahora'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: hasAgenda && !isAgendaMuted ? onSpeakAfter : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Ver después'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: hasAgenda ? onNext : null,
            icon: const Icon(Icons.navigate_next_rounded),
            label: const Text('Siguiente'),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onLongPress: onToggleMuteLongPress,
          onPressed: null,
          icon: Icon(
            isAgendaMuted ? Icons.volume_off_rounded : Icons.volume_up_outlined,
          ),
          label: Text(
            isAgendaMuted ? 'Mantén para activar' : 'Mantén para silenciar',
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onLongPress: hasAgenda ? onClearLongPress : null,
          onPressed: null,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Mantén para borrar'),
        ),
      ],
    );
  }
}

class _DraftAgendaStrip extends StatelessWidget {
  final List<VisualAgendaItem> draftItems;

  const _DraftAgendaStrip({required this.draftItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.shade200, width: 2),
      ),
      child: draftItems.isEmpty
          ? Center(
              child: Text(
                'Toca pictogramas abajo para crear la agenda en orden.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey.shade600,
                ),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: draftItems.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = draftItems[index];

                return _DraftAgendaItem(number: index + 1, item: item);
              },
            ),
    );
  }
}

class _DraftAgendaItem extends StatelessWidget {
  final int number;
  final VisualAgendaItem item;

  const _DraftAgendaItem({required this.number, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade200, width: 1.6),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.indigo.shade700,
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: Image.asset(
              item.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) {
                return Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.blueGrey.shade400,
                  size: 30,
                );
              },
            ),
          ),
          Text(
            item.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorNavigationBar extends StatelessWidget {
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onHome;

  const _EditorNavigationBar({
    required this.canGoBack,
    required this.onBack,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: canGoBack ? onBack : null,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Atrás'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onHome,
          icon: const Icon(Icons.home_rounded),
          label: const Text('Inicio'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Pulsa una categoría para entrar. Pulsa pictogramas, favoritos o frases recientes para añadirlos.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorPictogramGrid extends StatelessWidget {
  final List<Pictogram> pictograms;
  final ValueChanged<Pictogram> onPictogramTap;

  const _EditorPictogramGrid({
    required this.pictograms,
    required this.onPictogramTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1000 ? 7 : 5;

        return GridView.builder(
          itemCount: pictograms.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.10,
          ),
          itemBuilder: (context, index) {
            final pictogram = pictograms[index];

            return _EditorPictogramTile(
              pictogram: pictogram,
              onTap: () => onPictogramTap(pictogram),
            );
          },
        );
      },
    );
  }
}

class _EditorPictogramTile extends StatelessWidget {
  final Pictogram pictogram;
  final VoidCallback onTap;

  const _EditorPictogramTile({required this.pictogram, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCategory = pictogram.isCategory;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCategory
                  ? Colors.indigo.shade300
                  : Colors.blueGrey.shade200,
              width: isCategory ? 2.4 : 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  pictogram.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) {
                    return Icon(
                      isCategory
                          ? Icons.folder_rounded
                          : Icons.image_not_supported_outlined,
                      color: Colors.blueGrey.shade400,
                      size: 36,
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Text(
                pictogram.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: isCategory ? Colors.indigo.shade800 : Colors.black87,
                ),
              ),
              if (isCategory)
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.indigo.shade600,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaEditorActions extends StatelessWidget {
  final bool canSave;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onRemoveLast;
  final VoidCallback onClear;
  final VoidCallback onSave;

  const _AgendaEditorActions({
    required this.canSave,
    required this.isSaving,
    required this.onCancel,
    required this.onRemoveLast,
    required this.onClear,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.close_rounded),
          label: const Text('Cancelar'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onRemoveLast,
          icon: const Icon(Icons.undo_rounded),
          label: const Text('Borrar último'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.delete_sweep_rounded),
          label: const Text('Limpiar'),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: canSave ? onSave : null,
          icon: Icon(
            isSaving ? Icons.hourglass_top_rounded : Icons.save_rounded,
          ),
          label: Text(isSaving ? 'Guardando...' : 'Guardar agenda'),
        ),
      ],
    );
  }
}

class _EditorRecentPhrasesGrid extends StatelessWidget {
  final List<RecentPhrase> recentPhrases;
  final ValueChanged<RecentPhrase> onRecentPhraseTap;

  const _EditorRecentPhrasesGrid({
    required this.recentPhrases,
    required this.onRecentPhraseTap,
  });

  @override
  Widget build(BuildContext context) {
    if (recentPhrases.isEmpty) {
      return Center(
        child: Text(
          'No hay frases recientes para añadir a la agenda.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.blueGrey.shade600,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1000 ? 3 : 2;

        return GridView.builder(
          itemCount: recentPhrases.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.6,
          ),
          itemBuilder: (context, index) {
            final recentPhrase = recentPhrases[index];

            return _EditorRecentPhraseTile(
              recentPhrase: recentPhrase,
              onTap: () => onRecentPhraseTap(recentPhrase),
            );
          },
        );
      },
    );
  }
}

class _EditorRecentPhraseTile extends StatelessWidget {
  final RecentPhrase recentPhrase;
  final VoidCallback onTap;

  const _EditorRecentPhraseTile({
    required this.recentPhrase,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = recentPhrase.items.take(4).toList();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.cyan.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visibleItems.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = visibleItems[index];

                    return SizedBox(
                      width: 58,
                      child: Column(
                        children: [
                          Expanded(
                            child: item.imagePath.trim().isEmpty
                                ? Icon(
                                    Icons.keyboard_rounded,
                                    color: Colors.cyan.shade700,
                                    size: 28,
                                  )
                                : Image.asset(
                                    item.imagePath,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) {
                                      return Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.blueGrey.shade400,
                                        size: 28,
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 140,
                child: Text(
                  recentPhrase.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.add_circle_rounded,
                color: Colors.cyan.shade700,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
