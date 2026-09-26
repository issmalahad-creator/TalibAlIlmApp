import 'quran_learning.dart';

class KnowledgeProvenance {
  final double sourceAuthority;
  final double directness;
  final double contextFit;
  final double independentSupport;

  const KnowledgeProvenance({
    required this.sourceAuthority,
    required this.directness,
    required this.contextFit,
    required this.independentSupport,
  });

  double get overall =>
      [
        sourceAuthority,
        directness,
        contextFit,
        independentSupport,
      ].reduce((a, b) => a + b) /
      4;
}

class KnowledgeFactModel {
  final String id;
  final String title;
  final String domain;
  final String summary;
  final String source;
  final String sourceType;
  final KnowledgeProvenance provenance;

  const KnowledgeFactModel({
    required this.id,
    required this.title,
    required this.domain,
    required this.summary,
    required this.source,
    required this.sourceType,
    required this.provenance,
  });

  factory KnowledgeFactModel.fromKnowledgeFact(KnowledgeFact fact) {
    final payload = fact.payload;
    final provenanceMap = payload['provenance'];
    final sourceAuthority = provenanceMap is Map
        ? ((provenanceMap['source_authority'] as num?) ?? 0.5).toDouble()
        : 0.5;
    final directness = provenanceMap is Map
        ? ((provenanceMap['directness'] as num?) ?? 0.5).toDouble()
        : 0.5;
    final contextFit = provenanceMap is Map
        ? ((provenanceMap['context_fit'] as num?) ?? 0.5).toDouble()
        : 0.5;
    final independentSupport = provenanceMap is Map
        ? ((provenanceMap['independent_support'] as num?) ?? 0.5).toDouble()
        : 0.5;

    return KnowledgeFactModel(
      id: fact.id,
      title: (payload['title'] as String?) ?? fact.id,
      domain: fact.domain,
      summary:
          (payload['summary'] as String?) ??
          (payload['explanation'] as String?) ??
          '',
      source: fact.sourceRefId,
      sourceType: payload['source_type'] as String? ?? fact.domain,
      provenance: KnowledgeProvenance(
        sourceAuthority: sourceAuthority,
        directness: directness,
        contextFit: contextFit,
        independentSupport: independentSupport,
      ),
    );
  }
}

class KnowledgeNodeModel {
  final String id;
  final String title;
  final String type;
  final String summary;
  final String domain;

  const KnowledgeNodeModel({
    required this.id,
    required this.title,
    required this.type,
    required this.summary,
    required this.domain,
  });

  factory KnowledgeNodeModel.fromConcept(LearningConcept concept) =>
      KnowledgeNodeModel(
        id: concept.id,
        title: concept.titleAr.isNotEmpty ? concept.titleAr : concept.id,
        type: 'concept',
        summary: concept.shortDefAr ?? '',
        domain: concept.domain,
      );
}

class KnowledgeRelationModel {
  final String fromId;
  final String toId;
  final String relation;
  final double strength;

  const KnowledgeRelationModel({
    required this.fromId,
    required this.toId,
    required this.relation,
    required this.strength,
  });
}

class IslamicKnowledgeGraph {
  final List<KnowledgeNodeModel> nodes;
  final List<KnowledgeRelationModel> relations;

  const IslamicKnowledgeGraph({required this.nodes, required this.relations});
}
