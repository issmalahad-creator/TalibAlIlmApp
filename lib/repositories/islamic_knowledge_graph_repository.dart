import '../models/islamic_knowledge_graph.dart';
import '../models/quran_learning.dart';

class IslamicKnowledgeGraphRepository {
  static IslamicKnowledgeGraph buildGraph({
    required List<KnowledgeFactModel> facts,
    required List<KnowledgeNodeModel> concepts,
    required String label,
  }) {
    final nodes = <KnowledgeNodeModel>[];
    final relations = <KnowledgeRelationModel>[];

    nodes.addAll(concepts);

    for (final fact in facts) {
      final factNode = KnowledgeNodeModel(
        id: fact.id,
        title: fact.title,
        type: 'fact',
        summary: fact.summary,
        domain: fact.domain,
      );
      nodes.add(factNode);
      if (concepts.isEmpty) continue;

      final conceptNode = concepts.firstWhere(
        (c) => c.title == label || c.title == fact.title,
        orElse: () => concepts.first,
      );

      relations.add(
        KnowledgeRelationModel(
          fromId: conceptNode.id,
          toId: factNode.id,
          relation: 'supports',
          strength: fact.provenance.overall,
        ),
      );
    }

    return IslamicKnowledgeGraph(nodes: nodes, relations: relations);
  }

  static IslamicKnowledgeGraph buildConceptGraph({
    required LearningConcept concept,
    required List<KnowledgeFact> facts,
  }) {
    final conceptNode = KnowledgeNodeModel.fromConcept(concept);
    final factModels = facts.map(KnowledgeFactModel.fromKnowledgeFact).toList();

    return buildGraph(
      facts: factModels,
      concepts: [conceptNode],
      label: concept.titleAr,
    );
  }
}
