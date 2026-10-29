import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_phylogeny/src/data.dart';

import 'package:flutter/services.dart';

import 'dart:convert';
import 'dart:io';

void main() {
  test('tree layout places every ghost once', () {
    final raw = jsonDecode(
      File('web/src/data/phylogeny.json').readAsStringSync(),
    );
    final tree = TreeNode.fromJson(raw['tree']);
    final clade = {
      for (final g in raw['ghosts']) g['id'] as String: g['clade'] as String,
    };
    final layout = TreeLayout(tree, (id) => clade[id]!, TreeMode.cladogram);
    expect(layout.nTips, raw['ghosts'].length);
    expect(layout.tips.map((t) => t.id).toSet().length, layout.nTips);
    expect(layout.root.tips.length, layout.nTips);
  });

  test('key reaches every ghost through couplets that exist', () {
    final raw = jsonDecode(
      File('web/src/data/phylogeny.json').readAsStringSync(),
    );
    final key = DichotomousKey.fromJson(raw['key']);
    final numbers = {for (final c in key.couplets) c.n};
    final reached = <String>{};
    for (final c in key.couplets) {
      expect(c.leads, hasLength(2));
      expect(c.from == null || numbers.contains(c.from), isTrue);
      for (final l in c.leads) {
        expect(l.to == null || numbers.contains(l.to), isTrue);
        reached.addAll(l.ghosts ?? const []);
      }
    }
    expect(reached, {for (final g in raw['ghosts']) g['id'] as String});
  });

  test('phylogeny asset is registered', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final s = await rootBundle.loadString(phylogenyAsset);
    expect(s, isNotEmpty);
  });
}
