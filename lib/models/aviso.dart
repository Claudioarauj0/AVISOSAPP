/// Seções do culto, na ordem padrão.
const secoesPadrao = [
  'louvor',
  'direcao',
  'avisos',
  'ministracao',
  'avisosFinais',
];

const nomesSecao = {
  'louvor': 'Louvor',
  'direcao': 'Direção',
  'avisos': 'Avisos',
  'ministracao': 'Ministração',
  'avisosFinais': 'Avisos Finais',
};

/// Garante que a ordem tenha todas as seções, uma vez cada.
List<String> normalizarOrdem(List<String>? ordem) => [
  ...?ordem?.where(secoesPadrao.contains).toSet(),
  ...secoesPadrao.where((s) => !(ordem ?? const []).contains(s)),
];

/// "30 min", "1h", "1h 15min".
String formatarTempo(int minutos) {
  if (minutos < 60) return '$minutos min';
  final h = minutos ~/ 60, m = minutos % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}min';
}

/// Lê os minutos de um tempo salvo ("1h 15min" -> 75). Aceita textos antigos
/// digitados à mão, como "30" ou "30 minutos".
int? minutosDe(String texto) {
  final t = texto.toLowerCase();
  final h = RegExp(r'(\d+)\s*h').firstMatch(t);
  final m = RegExp(r'(\d+)\s*m').firstMatch(t);
  if (h == null && m == null) {
    final n = RegExp(r'\d+').firstMatch(t);
    return n == null ? null : int.parse(n.group(0)!);
  }
  return (int.tryParse(h?.group(1) ?? '') ?? 0) * 60 +
      (int.tryParse(m?.group(1) ?? '') ?? 0);
}

/// Um informativo (avisos de um culto).
class Aviso {
  final String id;
  String culto;
  DateTime? data;

  String tempoLouvor;
  String ministroLouvor;
  List<String> musicas;

  String tempoDirecao;
  String dirigente;

  List<String> avisos;

  String tempoMinistracao;
  String ministro;

  List<String> avisosFinais;

  /// Ordem das seções no formulário e no PDF.
  List<String> ordem;

  DateTime criadoEm;
  DateTime atualizadoEm;

  Aviso({
    required this.id,
    this.culto = '',
    this.data,
    this.tempoLouvor = '',
    this.ministroLouvor = '',
    List<String>? musicas,
    this.tempoDirecao = '',
    this.dirigente = '',
    List<String>? avisos,
    this.tempoMinistracao = '',
    this.ministro = '',
    List<String>? avisosFinais,
    List<String>? ordem,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) : musicas = musicas ?? List.filled(5, '', growable: true),
       avisos = avisos ?? List.filled(5, '', growable: true),
       avisosFinais = avisosFinais ?? List.filled(5, '', growable: true),
       ordem = normalizarOrdem(ordem),
       criadoEm = criadoEm ?? DateTime.now(),
       atualizadoEm = atualizadoEm ?? DateTime.now();

  factory Aviso.novo() =>
      Aviso(id: DateTime.now().microsecondsSinceEpoch.toString());

  /// Cópia com novo id, usada para "usar como modelo".
  Aviso duplicar() {
    final agora = DateTime.now();
    return Aviso.fromJson({
      ...toJson(),
      'id': agora.microsecondsSinceEpoch.toString(),
      'data': null,
      'criadoEm': agora.toIso8601String(),
      'atualizadoEm': agora.toIso8601String(),
    });
  }

  bool get vazio =>
      [
        culto,
        tempoLouvor,
        ministroLouvor,
        tempoDirecao,
        dirigente,
        tempoMinistracao,
        ministro,
        ...musicas,
        ...avisos,
        ...avisosFinais,
      ].every((s) => s.trim().isEmpty) &&
      data == null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'culto': culto,
    'data': data?.toIso8601String(),
    'tempoLouvor': tempoLouvor,
    'ministroLouvor': ministroLouvor,
    'musicas': musicas,
    'tempoDirecao': tempoDirecao,
    'dirigente': dirigente,
    'avisos': avisos,
    'tempoMinistracao': tempoMinistracao,
    'ministro': ministro,
    'avisosFinais': avisosFinais,
    'ordem': ordem,
    'criadoEm': criadoEm.toIso8601String(),
    'atualizadoEm': atualizadoEm.toIso8601String(),
  };

  factory Aviso.fromJson(Map<String, dynamic> j) {
    List<String> lista(dynamic v) =>
        (v as List? ?? const []).map((e) => e.toString()).toList();
    DateTime? data(dynamic v) => v == null ? null : DateTime.tryParse(v);

    return Aviso(
      id: j['id'] as String,
      culto: j['culto'] ?? '',
      data: data(j['data']),
      tempoLouvor: j['tempoLouvor'] ?? '',
      ministroLouvor: j['ministroLouvor'] ?? '',
      musicas: lista(j['musicas']),
      tempoDirecao: j['tempoDirecao'] ?? '',
      dirigente: j['dirigente'] ?? '',
      avisos: lista(j['avisos']),
      tempoMinistracao: j['tempoMinistracao'] ?? '',
      ministro: j['ministro'] ?? '',
      avisosFinais: lista(j['avisosFinais']),
      ordem: j['ordem'] == null ? null : lista(j['ordem']),
      criadoEm: data(j['criadoEm']),
      atualizadoEm: data(j['atualizadoEm']),
    );
  }
}
