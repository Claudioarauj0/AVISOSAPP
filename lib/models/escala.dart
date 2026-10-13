/// Quem serve em um dia da escala.
class DiaEscala {
  int dia;
  List<String> pessoas;
  String obs;

  DiaEscala({required this.dia, List<String>? pessoas, this.obs = ''})
    : pessoas = pessoas ?? [];

  Map<String, dynamic> toJson() => {'dia': dia, 'pessoas': pessoas, 'obs': obs};

  factory DiaEscala.fromJson(Map<String, dynamic> j) => DiaEscala(
    dia: j['dia'] as int,
    pessoas: (j['pessoas'] as List? ?? const [])
        .map((e) => e.toString())
        .toList(),
    obs: j['obs'] ?? '',
  );
}

/// Escala de um departamento em um mês. Existe uma por departamento/mês.
class Escala {
  final String id;
  final String departamentoId;
  String departamentoNome;
  final int ano;
  final int mes;
  List<DiaEscala> dias;
  DateTime atualizadoEm;

  Escala({
    required this.departamentoId,
    required this.departamentoNome,
    required this.ano,
    required this.mes,
    List<DiaEscala>? dias,
    DateTime? atualizadoEm,
  }) : id = idPara(departamentoId, ano, mes),
       dias = dias ?? [],
       atualizadoEm = atualizadoEm ?? DateTime.now();

  static String idPara(String departamentoId, int ano, int mes) =>
      '${departamentoId}_${ano}_$mes';

  DateTime data(int dia) => DateTime(ano, mes, dia);

  DiaEscala? diaEscala(int dia) {
    for (final d in dias) {
      if (d.dia == dia) return d;
    }
    return null;
  }

  /// Dias marcados, em ordem.
  List<DiaEscala> get ordenados => [...dias]..sort((a, b) => a.dia - b.dia);

  bool get vazia => dias.every((d) => d.pessoas.isEmpty && d.obs.isEmpty);

  Map<String, dynamic> toJson() => {
    'departamentoId': departamentoId,
    'departamentoNome': departamentoNome,
    'ano': ano,
    'mes': mes,
    'dias': dias.map((d) => d.toJson()).toList(),
    'atualizadoEm': atualizadoEm.toIso8601String(),
  };

  factory Escala.fromJson(Map<String, dynamic> j) => Escala(
    departamentoId: j['departamentoId'] as String,
    departamentoNome: j['departamentoNome'] ?? '',
    ano: j['ano'] as int,
    mes: j['mes'] as int,
    dias: (j['dias'] as List? ?? const [])
        .map((e) => DiaEscala.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    atualizadoEm: DateTime.tryParse(j['atualizadoEm'] ?? ''),
  );
}
