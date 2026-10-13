import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/anotacao.dart';
import '../models/aviso.dart';
import '../models/departamento.dart';
import '../models/escala.dart';

/// Guarda uma lista de registros localmente. Mantém uma cópia em memória para
/// que as telas enxerguem as alterações na hora, sem esperar a escrita em disco.
class Repositorio<T> {
  Repositorio({
    required this.chave,
    required this.fromJson,
    required this.toJson,
    required this.id,
    required this.atualizadoEm,
  });

  final String chave;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;
  final String Function(T) id;
  final DateTime Function(T) atualizadoEm;

  List<T> _cache = [];

  Future<void> init(SharedPreferences prefs) async {
    _cache = [];
    final raw = prefs.getString(chave);
    if (raw == null) return;
    try {
      _cache = (jsonDecode(raw) as List)
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      _cache = [];
    }
  }

  /// Mais recentes primeiro.
  List<T> todos() =>
      [..._cache]..sort((a, b) => atualizadoEm(b).compareTo(atualizadoEm(a)));

  T? buscar(String idItem) {
    for (final item in _cache) {
      if (id(item) == idItem) return item;
    }
    return null;
  }

  bool get vazio => _cache.isEmpty;

  Future<void> salvarVarios(List<T> itens) async {
    for (final item in itens) {
      _cache.removeWhere((a) => id(a) == id(item));
      _cache.add(item);
    }
    await _gravar();
  }

  Future<void> salvar(T item) async {
    final i = _cache.indexWhere((a) => id(a) == id(item));
    if (i >= 0) {
      _cache[i] = item;
    } else {
      _cache.add(item);
    }
    await _gravar();
  }

  Future<void> excluir(String idItem) async {
    _cache.removeWhere((a) => id(a) == idItem);
    await _gravar();
  }

  Future<void> _gravar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chave, jsonEncode(_cache.map(toJson).toList()));
  }
}

class Storage {
  Storage._();
  static final instance = Storage._();

  final avisos = Repositorio<Aviso>(
    chave: 'avisos',
    fromJson: Aviso.fromJson,
    toJson: (a) => a.toJson(),
    id: (a) => a.id,
    atualizadoEm: (a) => a.atualizadoEm,
  );

  final anotacoes = Repositorio<Anotacao>(
    chave: 'anotacoes',
    fromJson: Anotacao.fromJson,
    toJson: (a) => a.toJson(),
    id: (a) => a.id,
    atualizadoEm: (a) => a.atualizadoEm,
  );

  final departamentos = Repositorio<Departamento>(
    chave: 'departamentos',
    fromJson: Departamento.fromJson,
    toJson: (d) => d.toJson(),
    id: (d) => d.id,
    atualizadoEm: (d) => d.criadoEm,
  );

  final escalas = Repositorio<Escala>(
    chave: 'escalas',
    fromJson: Escala.fromJson,
    toJson: (e) => e.toJson(),
    id: (e) => e.id,
    atualizadoEm: (e) => e.atualizadoEm,
  );

  /// Departamentos na ordem em que foram criados.
  List<Departamento> listaDepartamentos() =>
      departamentos.todos().reversed.toList();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    await avisos.init(prefs);
    await anotacoes.init(prefs);
    await departamentos.init(prefs);
    await escalas.init(prefs);
    if (!prefs.containsKey('departamentos')) {
      await departamentos.salvarVarios(Departamento.padroes());
    }
  }
}
