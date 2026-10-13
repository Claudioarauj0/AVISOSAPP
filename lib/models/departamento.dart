import 'package:flutter/material.dart';

/// Ícones disponíveis para os departamentos (guardados pela chave).
const iconesDepartamento = <String, IconData>{
  'diaconato': Icons.volunteer_activism_outlined,
  'infantil': Icons.child_care_outlined,
  'louvor': Icons.music_note_outlined,
  'ministros': Icons.menu_book_outlined,
  'dirigentes': Icons.mic_none_outlined,
  'grupo': Icons.groups_outlined,
};

class Departamento {
  final String id;
  String nome;
  String icone;
  List<String> pessoas;
  DateTime criadoEm;

  Departamento({
    required this.id,
    required this.nome,
    this.icone = 'grupo',
    List<String>? pessoas,
    DateTime? criadoEm,
  }) : pessoas = pessoas ?? [],
       criadoEm = criadoEm ?? DateTime.now();

  factory Departamento.novo(String nome, {String icone = 'grupo'}) =>
      Departamento(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        nome: nome,
        icone: icone,
      );

  IconData get iconData => iconesDepartamento[icone] ?? Icons.groups_outlined;

  /// Departamentos criados na primeira vez que o app abre.
  static List<Departamento> padroes() {
    final base = DateTime.now();
    var i = 0;
    Departamento d(String nome, String icone) => Departamento(
      id: 'padrao_$icone',
      nome: nome,
      icone: icone,
      criadoEm: base.add(Duration(milliseconds: i++)),
    );
    return [
      d('Diaconato', 'diaconato'),
      d('DI', 'infantil'),
      d('Louvor', 'louvor'),
      d('Ministros', 'ministros'),
      d('Dirigentes', 'dirigentes'),
    ];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'icone': icone,
    'pessoas': pessoas,
    'criadoEm': criadoEm.toIso8601String(),
  };

  factory Departamento.fromJson(Map<String, dynamic> j) => Departamento(
    id: j['id'] as String,
    nome: j['nome'] ?? '',
    icone: j['icone'] ?? 'grupo',
    pessoas: (j['pessoas'] as List? ?? const [])
        .map((e) => e.toString())
        .toList(),
    criadoEm: DateTime.tryParse(j['criadoEm'] ?? ''),
  );
}
