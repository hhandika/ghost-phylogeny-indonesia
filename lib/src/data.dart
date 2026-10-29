/// Typed access to the pipeline output (web/src/data/phylogeny.json, written
/// by `uv run --project pipeline ghostphylo export`), plus the tree layout
/// shared by the Atlas, Lantern, and Bestiary. Nothing here is hand-maintained
/// data.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

const phylogenyAsset = 'web/src/data/phylogeny.json';

/// Plate for one ghost, drawn by `ghostphylo svg`.
String plateAsset(String id) => 'web/public/ghosts/$id.svg';

class Ghost {
  Ghost.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      name = j['name'],
      region = j['region'],
      regionGroup = j['regionGroup'],
      culture = j['culture'],
      clade = j['clade'],
      morphology = j['morphology'],
      bodyPlan = j['bodyPlan'],
      diet = j['diet'],
      dietClass = j['dietClass'],
      danger = j['danger'],
      origin = j['origin'],
      appearance = j['appearance'],
      behavior = j['behavior'],
      deterrents = j['deterrents'],
      popCulture = j['popCulture'],
      outgroup = j['outgroup'],
      inSourceTree = j['inSourceTree'],
      coding = j['coding'],
      traits = Map<String, int?>.from(j['traits']),
      row = j['row'],
      twins = List<String>.from(j['twins']),
      relatives = List<String>.from(j['relatives']);

  final String id;
  final String name;
  final String region;
  final String regionGroup;
  final String? culture;
  final String clade;
  final String morphology;
  final String bodyPlan;
  final String diet;
  final String? dietClass;
  final int danger;
  final String? origin;
  final String? appearance;
  final String? behavior;
  final String? deterrents;
  final String? popCulture;
  final bool outgroup;
  final bool inSourceTree;

  /// "source", "filled", or "new".
  final String coding;
  final Map<String, int?> traits;
  final String row;
  final List<String> twins;
  final List<String> relatives;
}

class Character {
  Character.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      label = j['label'],
      states = List<String>.from(j['states']);

  final String id;
  final String label;
  final List<String> states;
}

class TreeNode {
  TreeNode.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      l = (j['l'] as num).toDouble(),
      s = j['s'],
      c = (j['c'] as List?)?.map((e) => TreeNode.fromJson(e)).toList();

  final String? id;
  final double l;
  final int? s;
  final List<TreeNode>? c;
}

/// One lead of a couplet: a character's states, then a couplet or ghosts.
class KeyLead {
  KeyLead.fromJson(Map<String, dynamic> j)
    : char = j['char'],
      states = List<String>.from(j['states']),
      negate = j['not'],
      to = j['to'],
      ghosts = j['ghosts'] == null ? null : List<String>.from(j['ghosts']);

  final String char;

  /// State labels (English; translate with tr). With [negate], every state
  /// but these.
  final List<String> states;
  final bool negate;
  final int? to;
  final List<String>? ghosts;
}

class Couplet {
  Couplet.fromJson(Map<String, dynamic> j)
    : n = j['n'],
      from = j['from'],
      leads = [for (final l in j['leads']) KeyLead.fromJson(l)];

  final int n;
  final int? from;
  final List<KeyLead> leads;
}

/// The dichotomous key written by `ghostphylo key`.
class DichotomousKey {
  DichotomousKey.fromJson(Map<String, dynamic> j)
    : labels = {
        for (final c in j['characters'])
          c['id'] as String: c['label'] as String,
      },
      couplets = [for (final c in j['couplets']) Couplet.fromJson(c)],
      index = {
        for (final e in (j['index'] as Map<String, dynamic>).entries)
          e.key: List<int>.from(e.value),
      };

  /// Character id to its English label.
  final Map<String, String> labels;
  final List<Couplet> couplets;

  /// Ghost id to the couplets where it keys out.
  final Map<String, List<int>> index;
}

class Dataset {
  Dataset._(Map<String, dynamic> j)
    : meta = j['meta'],
      clades = List<String>.from(j['clades']),
      regions = List<String>.from(j['regions']),
      bodyPlans = [
        for (final b in j['bodyPlans'])
          (id: b['id'] as String, label: b['label'] as String),
      ],
      characters = [for (final c in j['characters']) Character.fromJson(c)],
      symbols = j['symbols'],
      tree = TreeNode.fromJson(j['tree']),
      ghosts = [for (final g in j['ghosts']) Ghost.fromJson(g)],
      key = DichotomousKey.fromJson(j['key']),
      i18n = {
        for (final e in (j['i18n'] as Map<String, dynamic>? ?? {}).entries)
          e.key: Map<String, String>.from(e.value),
      } {
    byId = {for (final g in ghosts) g.id: g};
    cladogram = TreeLayout(tree, (id) => byId[id]!.clade, TreeMode.cladogram);
  }

  static late final Dataset instance;

  static Future<void> load() async {
    final raw = await rootBundle.loadString(phylogenyAsset);
    instance = Dataset._(jsonDecode(raw));
  }

  final Map<String, dynamic> meta;
  final List<String> clades;
  final List<String> regions;
  final List<({String id, String label})> bodyPlans;
  final List<Character> characters;
  final String symbols;
  final TreeNode tree;
  final List<Ghost> ghosts;
  final DichotomousKey key;
  final Map<String, Map<String, String>> i18n;
  late final Map<String, Ghost> byId;

  /// The default layout, shared by every view that only needs tip order.
  late final TreeLayout cladogram;

  Map<String, dynamic> get analysis => meta['analysis'];

  /// Coded state of character [i] for a ghost, in words.
  String stateOf(
    Ghost g,
    int i,
    String Function(String) translate,
    String unknown,
  ) {
    final s = g.row[i];
    if (s == '?') return unknown;
    return translate(characters[i].states[symbols.indexOf(s)]);
  }
}

// ---- Tree layout -------------------------------------------------------------

enum TreeMode { cladogram, phylogram }

class Placed {
  Placed(this.id, this.support, this.parent);

  final String? id;

  /// Distance from the root: branch-length sum or node depth.
  double x = 0;

  /// Tip index, or the mean of the children's for internal nodes.
  double y = 0;
  final int? support;
  final Placed? parent;
  List<Placed> children = const [];

  /// Clade shared by every tip below, or null when mixed.
  String? clade;
  List<String> tips = const [];

  bool get isTip => children.isEmpty;
}

/// Assigns coordinates to the rooted, ladderized tree from the pipeline.
class TreeLayout {
  TreeLayout(TreeNode tree, String Function(String) cladeOf, this.mode) {
    var row = 0;
    Placed build(TreeNode n, Placed? parent, int depth) {
      final p = Placed(n.id, n.s, parent);
      p.x = mode == TreeMode.phylogram
          ? (parent?.x ?? 0) + (parent != null ? n.l : 0)
          : depth.toDouble();
      all.add(p);
      if (n.c != null) {
        p.children = [for (final c in n.c!) build(c, p, depth + 1)];
        p.y = (p.children.first.y + p.children.last.y) / 2;
        p.tips = [for (final c in p.children) ...c.tips];
        final clades = {for (final c in p.children) c.clade};
        p.clade = clades.length == 1 ? clades.first : null;
      } else {
        p.y = (row++).toDouble();
        p.tips = [n.id!];
        p.clade = cladeOf(n.id!);
      }
      return p;
    }

    root = build(tree, null, 0);

    // Cladogram: tips line up at the right; internal nodes sit one step left
    // of their deepest child so the tree reads as nested brackets.
    if (mode == TreeMode.cladogram) {
      final heights = <Placed, int>{};
      int height(Placed p) => heights[p] ??= p.isTip
          ? 0
          : 1 + p.children.map(height).reduce(math.max);
      final h = height(root);
      for (final p in all) {
        p.x = (h - height(p)).toDouble();
      }
    }
    tips = all.where((p) => p.isTip).toList();
    maxX = tips.map((t) => t.x).reduce(math.max);
    tipById = {for (final t in tips) t.id!: t};
  }

  final TreeMode mode;
  final List<Placed> all = [];
  late final Placed root;
  late final List<Placed> tips;
  late final double maxX;
  late final Map<String, Placed> tipById;

  int get nTips => tips.length;

  /// Every node on the path from a tip to the root, tip first.
  static List<Placed> ancestry(Placed? tip) {
    final out = <Placed>[];
    for (var p = tip; p != null; p = p.parent) {
      out.add(p);
    }
    return out;
  }
}
