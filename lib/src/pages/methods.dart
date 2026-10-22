/// Methods: from spreadsheet to tree, ported from methods.astro.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';

const _downloads = [
  (
    'data/processed/ghosts.nex',
    'Character matrix (Nexus)',
    'Matriks karakter (Nexus)',
  ),
  (
    'results/iqtree/ghosts.rooted.tre',
    'Rooted ML tree with UFBoot support (Newick)',
    'Pohon ML berakar dengan dukungan UFBoot (Newick)',
  ),
  ('results/iqtree/ghosts.iqtree', 'IQ-TREE report', 'Laporan IQ-TREE'),
  (
    'data/processed/ghosts.csv',
    'Cleaned taxon table (CSV)',
    'Tabel takson yang sudah dirapikan (CSV)',
  ),
  (
    'data/processed/characters.csv',
    'Character definitions (CSV)',
    'Definisi karakter (CSV)',
  ),
];

class MethodsPage extends StatelessWidget {
  const MethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final lang = context.lang;
    final id = lang == Lang.id;
    final meta = data.meta;
    final a = data.analysis;
    final coded = {'source': 0, 'filled': 0, 'new': 0};
    for (final g in data.ghosts) {
      coded[g.coding] = coded[g.coding]! + 1;
    }
    final body = TextStyle(color: k.ink, fontSize: 16, height: 1.6);
    final code = TextStyle(
      fontFamily: 'monospace',
      fontSize: 14,
      color: k.ink,
      backgroundColor: k.chip,
    );
    TextSpan c(String s) => TextSpan(text: s, style: code);
    TextSpan i(String s) => TextSpan(
      text: s,
      style: const TextStyle(fontStyle: FontStyle.italic),
    );
    Widget p(List<InlineSpan> spans) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text.rich(TextSpan(children: spans), style: body),
    );
    final double? bic = a['bic']?.toDouble();
    final double? ll = a['logLikelihood']?.toDouble();
    final llText = ll != null ? num(lang, ll, 2) : '?';
    final bicText = bic != null ? ' (${num(lang, bic, 1)})' : '';

    final sections = <(String, List<Widget>)>[
      (
        'Data',
        [
          p([
            TextSpan(text: id ? 'Sumbernya adalah ' : 'The source is '),
            c('${meta['source']}'),
            TextSpan(
              text: id
                  ? ': ${meta['taxa']} takson, ${meta['outgroups']} di antaranya kelompok luar dari Malaysia, Filipina, Thailand, Kamboja, dan Asia Selatan. Dari seluruh takson, ${coded['source']} mempertahankan kode dari matriks asli, ${coded['filled']} memiliki sifat kosong yang diisi lewat sintesis cerita rakyat, dan ${coded['new']} merupakan entri baru yang seluruhnya dikodekan lewat sintesis. Semuanya ditandai ◆.'
                  : ': ${meta['taxa']} taxa, ${meta['outgroups']} of them outgroups from Malaysia, the Philippines, Thailand, Cambodia, and South Asia. Of the taxa, ${coded['source']} keep the codings of the original matrix, ${coded['filled']} had missing traits filled by folklore synthesis, and ${coded['new']} are new entries coded entirely by synthesis. These are marked ◆ throughout.',
            ),
          ]),
          if (id)
            p([
              const TextSpan(
                text: 'Teks dari data diterjemahkan ke bahasa Indonesia lewat tabel terjemahan yang dikurasi (',
              ),
              c('data/translations/id.json'),
              const TextSpan(text: '); nama hantu dibiarkan seperti aslinya.'),
            ]),
        ],
      ),
      (
        id ? 'Karakter' : 'Characters',
        [
          p([
            TextSpan(
              text: id
                  ? 'Delapan belas sifat diambil langsung dari buku kerja (0 tidak ada, 1 ada, 2 bervariasi; untuk jenis kelamin, 1 perempuan dan 2 laki-laki atau tidak disebutkan). Bentuk tubuh dan makanan masing-masing ditambahkan sebagai satu karakter multikeadaan tak berurut, sehingga sebuah bentuk tubuh dihitung sekali, bukan sebagai banyak kolom biner. Klad tidak dimasukkan karena justru pengelompokan itulah yang diuji oleh pohon. Ke-${meta['taxa']} takson menyusut menjadi ${meta['uniqueRows']} baris yang berbeda; takson yang berbagi baris tidak dapat dipisahkan oleh pohon mana pun.'
                  : 'Eighteen traits come straight from the workbook (0 absent, 1 present, 2 variable; for sex, 1 female and 2 male or unspecified). The body plan and the diet are each added as one unordered multistate character, so a body plan counts once rather than as many one-hot columns. Clade is left out because it is the grouping the tree tests. The ${meta['taxa']} taxa reduce to ${meta['uniqueRows']} distinct rows; taxa that share a row cannot be separated by any tree.',
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: k.tileBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: k.dark
                        ? Malam.c900
                        : Kafan.c200.withValues(alpha: 0.7),
                  ),
                  children: [
                    for (final h in [
                      '#',
                      context.t('character'),
                      id ? 'Keadaan' : 'States',
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          h.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
                for (final (n, ch) in data.characters.indexed)
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: k.dark ? Malam.c800 : Kafan.c200,
                        ),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          '${n + 1}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          context.tr(ch.label),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          [
                            for (final (j, s) in ch.states.indexed)
                              '${data.symbols[j]} ${context.tr(s)}',
                          ].join('; '),
                          style: TextStyle(fontSize: 14, color: k.muted),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      (
        id ? 'Inferensi' : 'Inference',
        [
          p(
            id
                ? [
                    TextSpan(text: '${a['software']} dengan ModelFinder ('),
                    c('-m MFP'),
                    const TextSpan(text: ') pada tipe data morfologi memilih '),
                    TextSpan(
                      text: '${a['model']}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          ' berdasarkan BIC$bicText. Dukungan cabang berasal dari 1000 replikasi ',
                    ),
                    i('ultrafast bootstrap'),
                    const TextSpan(text: ' (UFBoot2, -bnni); '),
                    i('seed'),
                    TextSpan(
                      text:
                          '-nya ${a['seed']}, sehingga hasilnya dapat diulang. ',
                    ),
                    i('Log-likelihood'),
                    TextSpan(text: ' pohon terbaik adalah $llText.'),
                  ]
                : [
                    TextSpan(text: '${a['software']} with ModelFinder ('),
                    c('-m MFP'),
                    const TextSpan(
                      text: ') on the morphological data type selected ',
                    ),
                    TextSpan(
                      text: '${a['model']}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          ' by BIC$bicText. Support comes from ${a['bootstrap']}; the seed is ${a['seed']}, so reruns are reproducible. The log-likelihood of the best tree is $llText.',
                    ),
                  ],
          ),
          p([
            TextSpan(
              text: id
                  ? 'Pohon diakarkan pada klad terbesar yang hanya berisi kelompok luar${meta['outgroupMonophyletic'] == true ? ', dan di sini kelompok luar memang membentuk satu klad' : '. Kelompok luar tidak membentuk satu klad: beberapa di antaranya bersarang di antara kerabat Indonesia, seperti kepala terbang Melayu dan Filipina pada pohon 61 takson sebelumnya'}. Dari ${meta['nodes']} simpul internal, ${meta['strongNodes']} memiliki ultrafast bootstrap 95 atau lebih dan ${meta['weakNodes']} di bawah 50, sehingga percabangan bagian dalam sebaiknya dianggap belum terpecahkan.'
                  : 'The tree is rooted on the largest clade made only of outgroups${meta['outgroupMonophyletic'] == true ? ', and here the outgroups do form one clade' : '. They do not form one clade: several outgroups nest among Indonesian relatives, as the Malay and Philippine flying heads did in the earlier 61-taxon tree'}. Of ${meta['nodes']} internal nodes, ${meta['strongNodes']} have ultrafast bootstrap of 95 or more and ${meta['weakNodes']} fall below 50, so treat the deep branching as unresolved.',
            ),
          ]),
        ],
      ),
      (
        id ? 'Pelat' : 'Plates',
        [
          p(
            id
                ? [
                    const TextSpan(text: 'Pelat setiap hantu digambar oleh '),
                    c('pipeline/ghostphylo/svgs.py'),
                    const TextSpan(
                      text: ' dari datanya: bentuk tubuh menentukan sosoknya, klad menentukan warna cincinnya, dan sifat berkode menambahkan latar, seperti beringin untuk roh hutan, ',
                    ),
                    i('nisan'),
                    const TextSpan(
                      text: ' dan bunga kamboja untuk penguburan, atap ',
                    ),
                    i('joglo'),
                    const TextSpan(
                      text:
                          ' dengan jendela menyala untuk hantu kampung, uang ',
                    ),
                    i('kepeng'),
                    const TextSpan(
                      text: ' untuk pencurian, dan anglo kemenyan untuk ilmu hitam. Berkas gambar tangan di ',
                    ),
                    c('assets/ghosts/'),
                    const TextSpan(
                      text: ' menggantikan pelat buatan untuk hantu tersebut.',
                    ),
                  ]
                : [
                    const TextSpan(text: "Each ghost's plate is drawn by "),
                    c('pipeline/ghostphylo/svgs.py'),
                    const TextSpan(
                      text: ' from its record: the body plan sets the figure, the clade sets the ring color, and coded traits add scenery, such as a banyan for forest spirits, ',
                    ),
                    i('nisan'),
                    const TextSpan(
                      text: ' gravestones and frangipani for burial, a lit ',
                    ),
                    i('joglo'),
                    const TextSpan(text: ' roof for village haunts, '),
                    i('kepeng'),
                    const TextSpan(
                      text: ' coins for theft, and an incense burner for black magic. A hand-drawn file in ',
                    ),
                    c('assets/ghosts/'),
                    const TextSpan(
                      text: ' replaces the generated plate for that ghost.',
                    ),
                  ],
          ),
        ],
      ),
      (
        id ? 'Alur pemrosesan' : 'Pipeline',
        [
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Malam.c950,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                'uv run --project pipeline ghostphylo all   # parse, encode, IQ-TREE, export, plates\n'
                'cd web && bun run build                    # the website\n'
                'flutter run                                # this app',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Kafan.c100,
                  height: 1.5,
                ),
              ),
            ),
          ),
          p([
            TextSpan(
              text: id
                  ? 'Alur kerja GitHub memasang IQ-TREE, menjalankan perintah yang sama, mengunggah berkas analisis sebagai artefak, dan menerbitkan situs ke GitHub Pages.'
                  : 'The GitHub workflow installs IQ-TREE, runs the same commands, uploads the analysis files as a build artifact, and deploys the site to GitHub Pages.',
            ),
          ]),
        ],
      ),
      (
        id ? 'Unduhan' : 'Downloads',
        [
          const SizedBox(height: 8),
          for (final (file, en, idText) in _downloads)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AccentLink(
                    file.split('/').last,
                    onTap: () =>
                        launchUrl(Uri.parse('$sourceUrl/blob/main/$file')),
                  ),
                  Text(
                    ' · ${id ? idText : en}',
                    style: TextStyle(color: k.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
      (
        id ? 'Catatan' : 'Caveats',
        [
          p([
            TextSpan(
              text: id
                  ? 'Cerita rakyat tidak diwariskan seperti gen; sifat yang sama bisa berasal dari film yang sama, jalur dagang, atau agama, bukan hanya dari leluhur bersama. Bacalah pohon ini sebagai peta kemiripan antarversi cerita, bukan sejarah roh-roh itu sendiri. Periksa setiap entri dengan sumber etnografi primer sebelum mengutipnya.'
                  : 'Folklore is not inherited like genes; shared traits may come from shared film portrayals, trade routes, or religion as much as from common descent. Read the tree as a map of resemblance among tellings, not a history of the spirits themselves. Verify any entry against primary ethnographic sources before citing it.',
            ),
          ]),
        ],
      ),
    ];

    return PageScroll(
      children: [
        PageTitle(
          title: context.t('navMethods'),
          kicker: id
              ? 'Dari lembar kerja ke pohon'
              : 'From spreadsheet to tree',
          lead: id
              ? 'Setiap angka di aplikasi ini dihitung oleh pipeline dalam pipeline/ghostphylo/ dan dijalankan ulang oleh GitHub Actions setiap kali datanya berubah.'
              : 'Every number in this app is computed by the pipeline in pipeline/ghostphylo/, rerun by GitHub Actions whenever the data change.',
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (title, children) in sections) ...[
                  Glass(
                    padding: EdgeInsets.all(
                      MediaQuery.sizeOf(context).width >= 640 ? 32 : 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: serif(size: 24, color: k.ink),
                          ),
                        ),
                        ...children,
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
