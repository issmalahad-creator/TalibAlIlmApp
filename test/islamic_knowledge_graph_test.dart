import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/models/quran_learning.dart';
import 'package:talib_alilm_app/repositories/islamic_knowledge_graph_repository.dart';

void main() {
  group('IslamicKnowledgeGraph', () {
    test('builds a concept graph from the real Quran learning model', () {
      final concept = LearningConcept(
        id: 'concept-1',
        domain: 'aqeedah',
        titleAr: 'النية',
        shortDefAr: 'قصد القلب في العمل',
        sourceRefIds: ['src-1'],
      );

      final facts = [
        KnowledgeFact(
          id: 'fact-1',
          domain: 'meaning',
          anchor: KnowledgeAnchor(surah: 1, ayah: 1, wordStart: 1, wordEnd: 1),
          payload: {
            'concept_id': 'concept-1',
            'summary': 'النية تؤثر في قبول العمل',
          },
          sourceRefId: 'src-1',
        ),
      ];

      final graph = IslamicKnowledgeGraphRepository.buildConceptGraph(
        concept: concept,
        facts: facts,
      );

      expect(graph.nodes.length, 2);
      expect(graph.relations, isNotEmpty);
      expect(graph.relations.first.relation, 'supports');
      expect(graph.nodes.any((n) => n.id == 'concept-1'), isTrue);
      expect(graph.nodes.any((n) => n.id == 'fact-1'), isTrue);
    });
  });
}
