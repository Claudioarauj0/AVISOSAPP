/// Uma anotação livre: título editável e corpo de texto.
class Anotacao {
  final String id;
  String titulo;
  String corpo;
  DateTime criadoEm;
  DateTime atualizadoEm;

  Anotacao({
    required this.id,
    this.titulo = '',
    this.corpo = '',
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now(),
       atualizadoEm = atualizadoEm ?? DateTime.now();

  factory Anotacao.nova() =>
      Anotacao(id: DateTime.now().microsecondsSinceEpoch.toString());

  bool get vazia => titulo.trim().isEmpty && corpo.trim().isEmpty;

  String get tituloOuPadrao =>
      titulo.trim().isEmpty ? 'Sem título' : titulo.trim();

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'corpo': corpo,
    'criadoEm': criadoEm.toIso8601String(),
    'atualizadoEm': atualizadoEm.toIso8601String(),
  };

  factory Anotacao.fromJson(Map<String, dynamic> j) => Anotacao(
    id: j['id'] as String,
    titulo: j['titulo'] ?? '',
    corpo: j['corpo'] ?? '',
    criadoEm: DateTime.tryParse(j['criadoEm'] ?? ''),
    atualizadoEm: DateTime.tryParse(j['atualizadoEm'] ?? ''),
  );
}
