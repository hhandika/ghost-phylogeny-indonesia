/**
 * Two languages: American English (default, at /…) and Indonesian (at /id/…).
 * Interface strings live here; text from the data is translated through the
 * table the pipeline embeds in phylogeny.json (data/translations/id.json).
 */
import { data, withBase, type Coding, type Ghost } from "../utils/data";

export type Lang = "en" | "id";
export const LANGS: Lang[] = ["en", "id"];
export const HTML_LANG: Record<Lang, string> = { en: "en-US", id: "id" };
export const LANG_NAME: Record<Lang, string> = { en: "English (US)", id: "Bahasa Indonesia" };

/** Static paths for every localized page: English has no prefix. */
export const localeParams = () => [{ params: { locale: undefined } }, { params: { locale: "id" } }];
export const langOf = (locale: string | undefined): Lang => (locale === "id" ? "id" : "en");

/** Site path in a language, with the deploy base. */
export const localePath = (lang: Lang, path: string, base?: string) =>
  withBase(lang === "id" ? (path === "/" ? "/id" : `/id${path}`) : path, base);

/** Translate a string that came from the data (names of clades, traits, behaviors…). */
const table = (data as unknown as { i18n?: Record<string, Record<string, string>> }).i18n ?? {};
export const tr = (lang: Lang, s: string | null | undefined) => (s == null ? "" : lang === "en" ? s : table[lang]?.[s] ?? s);

export const num = (lang: Lang, n: number, digits = 0) =>
  n.toLocaleString(HTML_LANG[lang], { minimumFractionDigits: digits, maximumFractionDigits: digits });

type Value = string | ((...args: any[]) => string);
const ui = {
  // ---- Site ----------------------------------------------------------------
  siteName: { en: "Ghost phylogeny", id: "Filogeni hantu" },
  siteTitle: { en: "Ghost phylogeny, literally", id: "Filogeni hantu, secara harfiah" },
  literally: { en: "literally", id: "secara harfiah" },
  siteDescription: {
    en: "Ghost phylogeny, literally: a maximum-likelihood tree of Indonesian ghosts, spirits, and cryptids, built from a coded trait matrix with IQ-TREE.",
    id: "Filogeni hantu, secara harfiah: pohon kemungkinan maksimum hantu, roh, dan kriptid Indonesia, disusun dari matriks sifat berkode dengan IQ-TREE.",
  },
  skip: { en: "Skip to content", id: "Langsung ke konten" },
  navMain: { en: "Main", id: "Utama" },
  navOverview: { en: "Overview", id: "Ikhtisar" },
  navAtlas: { en: "Atlas", id: "Atlas" },
  navLantern: { en: "Lantern", id: "Lentera" },
  navBestiary: { en: "Bestiary", id: "Bestiari" },
  navPatterns: { en: "Patterns", id: "Pola" },
  navMethods: { en: "Methods", id: "Metode" },
  menu: { en: "Menu", id: "Menu" },
  language: { en: "Language", id: "Bahasa" },
  readIn: { en: "Read in American English", id: "Baca dalam Bahasa Indonesia" },
  toDark: { en: "Switch to dark mode", id: "Beralih ke mode gelap" },
  toLight: { en: "Switch to light mode", id: "Beralih ke mode terang" },
  toggleDark: { en: "Toggle dark mode", id: "Ganti mode gelap" },
  pauseMotion: { en: "Pause animations", id: "Jeda animasi" },
  playMotion: { en: "Play animations", id: "Putar animasi" },
  newTab: { en: "(opens in a new tab)", id: "(membuka tab baru)" },
  title: { en: (page: string) => `${page} · Ghost phylogeny, literally`, id: (page: string) => `${page} · Filogeni hantu, secara harfiah` },

  // ---- Shared ghost vocabulary --------------------------------------------
  danger1: { en: "Benign", id: "Jinak" },
  danger2: { en: "Unsettling", id: "Meresahkan" },
  danger3: { en: "Frightening", id: "Menakutkan" },
  danger4: { en: "Dangerous", id: "Berbahaya" },
  danger5: { en: "Lethal", id: "Mematikan" },
  dangerOf: { en: (n: number) => `Danger ${n} of 5:`, id: (n: number) => `Tingkat bahaya ${n} dari 5:` },
  codingSource: { en: "Coded in the source matrix", id: "Dikodekan dalam matriks sumber" },
  codingFilled: { en: "Some traits filled by folklore synthesis", id: "Sebagian sifat diisi lewat sintesis cerita rakyat" },
  codingNew: { en: "New entry coded by folklore synthesis", id: "Entri baru yang dikodekan lewat sintesis cerita rakyat" },
  sexFemale: { en: "Female", id: "Perempuan" },
  sexMale: { en: "Male", id: "Laki-laki" },
  sexUnspecified: { en: "Unspecified", id: "Tidak disebutkan" },
  outgroup: { en: "Outgroup", id: "Kelompok luar" },
  outgroups: { en: "Outgroups", id: "Kelompok luar" },
  form: { en: "Form", id: "Wujud" },
  origin: { en: "Origin", id: "Asal-usul" },
  behavior: { en: "Behavior", id: "Perilaku" },
  deterrents: { en: "Deterrents", id: "Penangkal" },
  deterrentsLong: { en: "Deterrents and vulnerabilities", id: "Penangkal dan kelemahan" },
  diet: { en: "Diet", id: "Makanan" },
  culture: { en: "Culture", id: "Budaya" },
  region: { en: "Region", id: "Wilayah" },
  sampling: { en: "Sampling", id: "Pengambilan sampel" },
  inBothTrees: { en: "In the original 61-taxon tree and in this one.", id: "Ada di pohon 61 takson yang asli dan di pohon ini." },
  newOnTree: { en: "Added in dataset v3–v5; first placed on a tree here.", id: "Ditambahkan di set data v3–v5; pertama kali ditempatkan pada pohon di sini." },
  codedTraits: { en: "Coded traits", id: "Sifat yang dikodekan" },
  codedCharacters: { en: "Coded characters", id: "Karakter yang dikodekan" },
  sexIs: { en: (s: string) => `Sex: ${s}.`, id: (s: string) => `Jenis kelamin: ${s}.` },
  twinsCard: {
    en: (names: string) => ` Shares an identical row with ${names}, so the tree cannot separate them.`,
    id: (names: string) => ` Barisnya identik dengan ${names}, sehingga pohon tidak dapat memisahkannya.`,
  },
  twinsPage: {
    en: (names: string) => `Identical coding to ${names}, so the tree cannot separate them.`,
    id: (names: string) => `Kodenya identik dengan ${names}, sehingga pohon tidak dapat memisahkannya.`,
  },
  nearest: { en: "Nearest on the tree", id: "Kerabat terdekat di pohon" },
  fullPage: { en: "Full specimen page", id: "Halaman spesimen lengkap" },
  cardOf: { en: (n: string) => `${n} card`, id: (n: string) => `Kartu ${n}` },
  drawnAs: { en: (n: string, m: string) => `${n}, drawn as ${m.toLowerCase()}`, id: (n: string, m: string) => `${n}, digambarkan sebagai ${m.toLowerCase()}` },
  selectedGhost: { en: "Selected ghost", id: "Hantu terpilih" },
  showingCard: { en: (n: string) => `Showing the card for ${n}.`, id: (n: string) => `Menampilkan kartu ${n}.` },
  unknown: { en: "Unknown", id: "Tidak diketahui" },
  ghosts: { en: (n: number) => `${n} ${n === 1 ? "ghost" : "ghosts"}`, id: (n: number) => `${n} hantu` },
  cladeColors: { en: "Clade colors", id: "Warna klad" },
  search: { en: "Search", id: "Cari" },
  allIslands: { en: "All islands", id: "Semua pulau" },
  compare: { en: "Compare", id: "Bandingkan" },
  close: { en: "Close", id: "Tutup" },

  // ---- Atlas ---------------------------------------------------------------
  atlasKicker: { en: "Tree and traits", id: "Pohon dan sifat" },
  atlasTitle: { en: "The atlas", id: "Atlas" },
  atlasLead: {
    en: (n: number) => `Every ghost on one maximum-likelihood tree, its ${n} coded characters lined up beside it, the way a phylogenetics paper would draw it. Select a name, or search and press Enter, to read its card.`,
    id: (n: number) => `Setiap hantu pada satu pohon kemungkinan maksimum, dengan ${n} karakter berkodenya berjajar di samping, seperti gambar dalam makalah filogenetika. Pilih sebuah nama, atau cari lalu tekan Enter, untuk membaca kartunya.`,
  },
  searchGhosts: { en: "Search ghosts", id: "Cari hantu" },
  searchNameIsland: { en: "Search by name or island", id: "Cari nama atau pulau" },
  highlight: { en: "Highlight", id: "Sorot" },
  noTrait: { en: "No trait", id: "Tanpa sifat" },
  branchLengths: { en: "Branch lengths", id: "Panjang cabang" },
  cladogram: { en: "Cladogram", id: "Kladogram" },
  phylogram: { en: "Phylogram", id: "Filogram" },
  nMatch: { en: (n: number, t: number) => `${n} of ${t} match`, id: (n: number, t: number) => `${n} dari ${t} cocok` },
  atlasFigure: { en: "Tree and trait matrix (scrolls sideways on small screens)", id: "Pohon dan matriks sifat (geser ke samping di layar kecil)" },
  atlasSvg: {
    en: (n: number, g: string) => `Maximum-likelihood tree of ${n} ghosts with their coded traits. ${g} is selected.`,
    id: (n: number, g: string) => `Pohon kemungkinan maksimum ${n} hantu beserta sifat berkodenya. ${g} sedang dipilih.`,
  },
  atlasCaption: {
    en: "Branches take the clade color where every tip below shares it. Filled dots mark ultrafast bootstrap ≥ 95, open dots 80–94. In the matrix, a filled square means present, an outlined square absent, a half-filled square variable, and a dot unknown; the last two columns give body plan and diet as state codes (see Methods). † outgroup, ◆ some or all traits coded by folklore synthesis.",
    id: "Cabang diberi warna klad bila semua ujung di bawahnya berklad sama. Titik penuh menandai ultrafast bootstrap ≥ 95, titik kosong 80–94. Dalam matriks, kotak penuh berarti ada, kotak bergaris tepi berarti tidak ada, kotak setengah penuh berarti bervariasi, dan titik berarti tidak diketahui; dua kolom terakhir memuat bentuk tubuh dan makanan sebagai kode keadaan (lihat Metode). † kelompok luar, ◆ sebagian atau semua sifat dikodekan lewat sintesis cerita rakyat.",
  },

  // ---- Lantern -------------------------------------------------------------
  lanternKicker: { en: "The circular tree", id: "Pohon melingkar" },
  lanternTitle: { en: "By lantern light", id: "Di bawah cahaya lentera" },
  lanternLead: {
    en: "The same tree bent into a circle and read at night. Pass the lantern over a ghost to trace its lineage to the root, or pick an island to see where its ghosts fall.",
    id: "Pohon yang sama dilengkungkan menjadi lingkaran dan dibaca pada malam hari. Arahkan lentera ke sebuah hantu untuk menelusuri garis keturunannya hingga ke akar, atau pilih pulau untuk melihat letak hantu-hantunya.",
  },
  filterIsland: { en: "Filter by island", id: "Saring menurut pulau" },
  lanternSvg: { en: (n: number, g: string) => `Circular tree of ${n} ghosts. ${g} is in the center.`, id: (n: number, g: string) => `Pohon melingkar ${n} hantu. ${g} berada di tengah.` },
  lanternCaption: {
    en: "Hover or focus a ghost to light its lineage; select it to read its card. Gold dots mark ultrafast bootstrap ≥ 95. The outer ring shows clades; the legend above names them.",
    id: "Arahkan kursor atau fokus ke sebuah hantu untuk menerangi garis keturunannya; pilih untuk membaca kartunya. Titik emas menandai ultrafast bootstrap ≥ 95. Cincin luar menunjukkan klad; keterangannya ada di atas.",
  },

  // ---- Bestiary ------------------------------------------------------------
  bestiaryKicker: { en: "Field guide", id: "Buku panduan lapangan" },
  bestiaryTitle: { en: "The bestiary", id: "Bestiari" },
  bestiaryLead: {
    en: (n: number) => `All ${n} specimens, kept in tree order so neighbors are relatives. Filter by island, clade, danger, or trait, and tick two cards to compare them character by character.`,
    id: (n: number) => `Seluruh ${n} spesimen, diurutkan menurut pohon sehingga yang bertetangga adalah kerabat. Saring menurut pulau, klad, tingkat bahaya, atau sifat, lalu centang dua kartu untuk membandingkannya karakter demi karakter.`,
  },
  filters: { en: "Filters", id: "Saringan" },
  searchBestiary: { en: "Search names, places, behavior", id: "Cari nama, tempat, perilaku" },
  island: { en: "Island", id: "Pulau" },
  minDanger: { en: "Minimum danger", id: "Tingkat bahaya minimum" },
  anyDanger: { en: "Any danger", id: "Semua tingkat bahaya" },
  orWorse: { en: (d: string) => `${d} or worse`, id: (d: string) => `${d} atau lebih` },
  sort: { en: "Sort", id: "Urutkan" },
  sortTree: { en: "Tree order", id: "Urutan pohon" },
  sortName: { en: "Name", id: "Nama" },
  sortDanger: { en: "Most dangerous", id: "Paling berbahaya" },
  clades: { en: "Clades", id: "Klad" },
  traitsAll: { en: "Traits, all must be present", id: "Sifat, semuanya harus ada" },
  nSpecimens: { en: (n: number, t: number) => `${n} of ${t} specimens.`, id: (n: number, t: number) => `${n} dari ${t} spesimen.` },
  clearFilters: { en: "Clear filters", id: "Hapus saringan" },
  pickOneMore: { en: "Pick one more", id: "Pilih satu lagi" },
  ready: { en: "Ready", id: "Siap" },
  clear: { en: "Clear", id: "Hapus" },
  comparison: { en: "Comparison", id: "Perbandingan" },
  character: { en: "Character", id: "Karakter" },
  compareSummary: {
    en: (d: number, n: number, steps: number, tips: string, sup: string) =>
      `They differ in ${d} of ${n} characters and sit ${steps} branches apart. Their last common ancestor unites ${tips} ghosts${sup ? ` (ultrafast bootstrap ${sup})` : ""}.`,
    id: (d: number, n: number, steps: number, tips: string, sup: string) =>
      `Keduanya berbeda pada ${d} dari ${n} karakter dan terpisah ${steps} cabang. Leluhur bersama terakhirnya menyatukan ${tips} hantu${sup ? ` (ultrafast bootstrap ${sup})` : ""}.`,
  },

  // ---- Patterns ------------------------------------------------------------
  patternsKicker: { en: "The whole dataset, chart by chart", id: "Seluruh data, bagan demi bagan" },
  patternsTitle: { en: "Patterns in the haunting", id: "Pola-pola penampakan" },
  patternsLead: {
    en: "The tree shows who is related to whom. These charts show everything else in the data: where each ghost lives, what it is made of, how dangerous it is, and how much of its coding is folklore synthesis.",
    id: "Pohon menunjukkan siapa berkerabat dengan siapa. Bagan-bagan ini menunjukkan semua hal lain dalam data: di mana setiap hantu tinggal, terbuat dari apa, seberapa berbahaya, dan seberapa banyak kodenya berasal dari sintesis cerita rakyat.",
  },
  chartsOnPage: { en: "Charts on this page", id: "Bagan di halaman ini" },
  secWhere: { en: "Where they haunt", id: "Tempat mereka bergentayangan" },
  secTraits: { en: "What each clade is made of", id: "Apa saja isi setiap klad" },
  secDanger: { en: "How dangerous", id: "Seberapa berbahaya" },
  secBodies: { en: "Bodies and diets", id: "Tubuh dan makanan" },
  secSupport: { en: "How sure the tree is", id: "Seberapa yakin pohonnya" },
  secTwins: { en: "Indistinguishable ghosts", id: "Hantu yang tak dapat dibedakan" },
  secProvenance: { en: "Where the codings come from", id: "Asal kode-kodenya" },
  leadWhere: {
    en: (a: string, an: number, b: string, bn: number, c: string, cn: number) =>
      `${a} has the most ghosts (${an}), then ${b} (${bn}) and ${c} (${cn}). Widespread motifs and outgroups from beyond Indonesia sit in the dashed boxes. Lower the sea to see the Pleistocene coastlines.`,
    id: (a: string, an: number, b: string, bn: number, c: string, cn: number) =>
      `${a} memiliki hantu terbanyak (${an}), disusul ${b} (${bn}) dan ${c} (${cn}). Motif yang tersebar luas dan kelompok luar dari luar Indonesia ada di kotak bergaris putus-putus. Turunkan permukaan laut untuk melihat garis pantai Pleistosen.`,
  },
  leadTraits: {
    en: (c: string, p: number) => `Each row is a clade, each column a coded trait. ${c} is the bloodiest clade: ${p}% of its members target blood, flesh, or organs.`,
    id: (c: string, p: number) => `Setiap baris adalah klad, setiap kolom sifat berkode. ${c} adalah klad paling haus darah: ${p}% anggotanya mengincar darah, daging, atau organ.`,
  },
  leadDanger: {
    en: (n: number, c: string, m: string) => `Each plate is one ghost, placed by clade and danger. ${n} are lethal in their dominant telling; ${c} has the highest mean danger (${m} of 5).`,
    id: (n: number, c: string, m: string) => `Setiap pelat adalah satu hantu, ditempatkan menurut klad dan tingkat bahaya. ${n} hantu mematikan dalam versi cerita utamanya; ${c} memiliki rata-rata bahaya tertinggi (${m} dari 5).`,
  },
  leadBodies: {
    en: (t: number, an: number, a: string, bn: number, b: string) => `Body plan and diet are characters 19 and 20 of the matrix. Of the ${t} blood-feeders, ${an} are ${a.toLowerCase()}s and ${bn} are ${b.toLowerCase()}s.`,
    id: (t: number, an: number, a: string, bn: number, b: string) => `Bentuk tubuh dan makanan adalah karakter ke-19 dan ke-20 dalam matriks. Dari ${t} pemakan darah, ${an} berwujud ${a.toLowerCase()} dan ${bn} berwujud ${b.toLowerCase()}.`,
  },
  leadSupport: {
    en: (n: number, s: number, w: number) => `Ultrafast bootstrap support across all ${n} internal nodes. Only ${s} reach 95; ${w} fall below 50.`,
    id: (n: number, s: number, w: number) => `Dukungan ultrafast bootstrap pada seluruh ${n} simpul internal. Hanya ${s} yang mencapai 95; ${w} di bawah 50.`,
  },
  leadTwins: {
    en: (n: number) => `${n} sets of ghosts share identical rows in the matrix, so no tree can separate them. They sit together with zero-length branches.`,
    id: (n: number) => `${n} kelompok hantu memiliki baris identik dalam matriks, sehingga tidak ada pohon yang dapat memisahkannya. Mereka berkumpul dengan cabang sepanjang nol.`,
  },
  leadProvenance: {
    en: (n: number, t: number) => `${n} of ${t} ghosts have some or all traits coded by folklore synthesis rather than the source matrix; the site marks them ◆.`,
    id: (n: number, t: number) => `${n} dari ${t} hantu memiliki sebagian atau semua sifat yang dikodekan lewat sintesis cerita rakyat, bukan dari matriks sumber; situs ini menandainya dengan ◆.`,
  },
  showTable: { en: "Show the data as a table", id: "Tampilkan data sebagai tabel" },
  scrollable: { en: (s: string) => `${s} (scrollable)`, id: (s: string) => `${s} (dapat digulir)` },
  seaLevel: { en: "Sea level", id: "Permukaan laut" },
  today: { en: "Today", id: "Kini" },
  play: { en: "Play", id: "Putar" },
  animateSea: { en: "Animate falling sea level", id: "Animasikan turunnya permukaan laut" },
  bioLines: { en: "Biogeographic lines", id: "Garis biogeografi" },
  lvlToday: { en: "present-day coastline", id: "garis pantai masa kini" },
  lvl40: { en: "shelves begin to emerge", id: "paparan mulai muncul" },
  lvl80: { en: "Sumatra, Java, and Borneo join Asia as Sundaland", id: "Sumatra, Jawa, dan Kalimantan menyatu dengan Asia sebagai Paparan Sunda" },
  lvl120: { en: "Last Glacial Maximum, about 20,000 years ago", id: "Puncak Zaman Es Terakhir, sekitar 20.000 tahun lalu" },
  seaStatus: { en: (l: string, note: string) => `Sea level ${l}: ${note}.`, id: (l: string, note: string) => `Permukaan laut ${l}: ${note}.` },
  seaToday: { en: "today", id: "kini" },
  seaLowNote: {
    en: " Most Indonesian ghosts west of Wallace's line shared one landmass; those of Sulawesi, Maluku, and Nusa Tenggara stayed on islands.",
    id: " Sebagian besar hantu Indonesia di barat Garis Wallace berbagi satu daratan; hantu Sulawesi, Maluku, dan Nusa Tenggara tetap di pulau masing-masing.",
  },
  mapRegion: { en: "Map of the archipelago (scrolls sideways on small screens)", id: "Peta kepulauan (geser ke samping di layar kecil)" },
  mapSvg: {
    en: (l: string, note: string) => `Map of the archipelago with one bubble per region, sized by number of ghosts. Sea level: ${l}, ${note}.`,
    id: (l: string, note: string) => `Peta kepulauan dengan satu gelembung per wilayah, berukuran menurut jumlah hantu. Permukaan laut: ${l}, ${note}.`,
  },
  mapIdle: {
    en: "Bubble area is proportional to the number of ghosts. Select a region to list its ghosts. Shelves are ETOPO1 bathymetry; line placements are approximate.",
    id: "Luas gelembung sebanding dengan jumlah hantu. Pilih wilayah untuk melihat daftar hantunya. Paparan berasal dari batimetri ETOPO1; letak garis bersifat perkiraan.",
  },
  regionSays: {
    en: (r: string, n: number, c: string, cn: number) => `${r}: ${n} ${n === 1 ? "ghost" : "ghosts"}; most are ${c} (${cn}).`,
    id: (r: string, n: number, c: string, cn: number) => `${r}: ${n} hantu; sebagian besar ${c} (${cn}).`,
  },
  showThem: { en: "Show them.", id: "Tampilkan." },
  mostCommonClade: { en: "Most common clade", id: "Klad paling umum" },
  ghostsWord: { en: "Ghosts", id: "Hantu" },
  regionTableCap: { en: "Ghosts per region and their most common clade", id: "Hantu per wilayah dan klad paling umumnya" },
  lineWallace: { en: "Wallace's line", id: "Garis Wallace" },
  lineHuxley: { en: "Huxley's line", id: "Garis Huxley" },
  lineWeber: { en: "Weber's line", id: "Garis Weber" },
  lineLydekker: { en: "Lydekker's line", id: "Garis Lydekker" },
  zoneSunda: { en: "Sundaland", id: "Paparan Sunda" },
  zoneWallacea: { en: "Wallacea", id: "Wallacea" },
  zoneSahul: { en: "Sahul Shelf", id: "Paparan Sahul" },
  allGhosts: { en: "All ghosts", id: "Semua hantu" },
  heatmapRegion: { en: "Trait heatmap (scrolls sideways)", id: "Peta panas sifat (geser ke samping)" },
  heatmapSvg: { en: "Heatmap of the share of each clade that has each trait. The table below lists every value.", id: "Peta panas proporsi setiap klad yang memiliki tiap sifat. Tabel di bawah memuat semua nilainya." },
  heatScale: { en: "Share with the trait", id: "Proporsi yang memiliki sifat" },
  colorScale: { en: "Color scale", id: "Skala warna" },
  heatSays: {
    en: (c: string, p: number, t: string, n: number, of: number) => `${c}: ${p}% have ${t.toLowerCase()} (${n} of ${of}).`,
    id: (c: string, p: number, t: string, n: number, of: number) => `${c}: ${p}% memiliki sifat ${t.toLowerCase()} (${n} dari ${of}).`,
  },
  heatIdle: { en: "Darker cells mean more of the clade has the trait. Hover a cell for the exact share.", id: "Sel yang lebih gelap berarti lebih banyak anggota klad yang memiliki sifat itu. Arahkan kursor ke sel untuk melihat proporsi tepatnya." },
  heatTableCap: { en: "Percent of each clade with each trait", id: "Persentase setiap klad yang memiliki tiap sifat" },
  clade: { en: "Clade", id: "Klad" },
  dangerRegion: { en: "Danger chart (scrolls sideways)", id: "Bagan bahaya (geser ke samping)" },
  dangerCap: { en: "Ghosts by clade and danger level; each plate is one ghost", id: "Hantu menurut klad dan tingkat bahaya; setiap pelat adalah satu hantu" },
  none: { en: "none", id: "tidak ada" },
  dangerSays: { en: (n: string, c: string, d: number, l: string) => `${n}: ${c}, danger ${d} (${l.toLowerCase()}).`, id: (n: string, c: string, d: number, l: string) => `${n}: ${c}, tingkat bahaya ${d} (${l.toLowerCase()}).` },
  dangerIdle: { en: "Each plate is one ghost. Hover a plate for its name; screen readers hear the names cell by cell.", id: "Setiap pelat adalah satu hantu. Arahkan kursor ke pelat untuk melihat namanya; pembaca layar membacakan nama-nama per sel." },
  bodyRegion: { en: "Body plan and diet chart (scrolls sideways)", id: "Bagan bentuk tubuh dan makanan (geser ke samping)" },
  bodySvg: { en: "Bubble matrix of body plan against diet; bubble area is the number of ghosts. The table below lists every count.", id: "Matriks gelembung bentuk tubuh terhadap makanan; luas gelembung adalah jumlah hantu. Tabel di bawah memuat semua jumlahnya." },
  bodySays: { en: (p: string, d: string, names: string) => `${p}, ${d.toLowerCase()}: ${names}.`, id: (p: string, d: string, names: string) => `${p}, ${d.toLowerCase()}: ${names}.` },
  bodyIdle: { en: "Bubble area is the number of ghosts with that body plan and diet. Hover a bubble to list them.", id: "Luas gelembung adalah jumlah hantu dengan bentuk tubuh dan makanan itu. Arahkan kursor ke gelembung untuk melihat daftarnya." },
  bodyTableCap: { en: "Ghosts by body plan and diet", id: "Hantu menurut bentuk tubuh dan makanan" },
  bodyPlan: { en: "Body plan", id: "Bentuk tubuh" },
  provSource: { en: "Source matrix", id: "Matriks sumber" },
  provFilled: { en: "Gaps filled by synthesis", id: "Celah diisi lewat sintesis" },
  provNew: { en: "New entry by synthesis", id: "Entri baru lewat sintesis" },
  legend: { en: "Legend", id: "Keterangan" },
  provSays: { en: (c: string, n: number, t: number, k: string) => `${c}: ${n} of ${t} — ${k.toLowerCase()}.`, id: (c: string, n: number, t: number, k: string) => `${c}: ${n} dari ${t} — ${k.toLowerCase()}.` },
  provIdle: { en: "Bar length is the clade size; segments show where each ghost's coding comes from.", id: "Panjang batang adalah ukuran klad; segmennya menunjukkan asal kode setiap hantu." },
  supportSvg: { en: (n: number) => `Histogram of ultrafast bootstrap support across ${n} nodes. The table below lists the counts.`, id: (n: number) => `Histogram dukungan ultrafast bootstrap pada ${n} simpul. Tabel di bawah memuat jumlahnya.` },
  supportSays: { en: (n: number, a: number, b: number) => `${n} ${n === 1 ? "node" : "nodes"} with support ${a}–${b}.`, id: (n: number, a: number, b: number) => `${n} simpul dengan dukungan ${a}–${b}.` },
  supportIdle: { en: "Most nodes have low support, so the deep branching is unresolved. Bars at 90 and above are highlighted.", id: "Sebagian besar simpul berdukungan rendah, sehingga percabangan dalamnya belum terpecahkan. Batang 90 ke atas disorot." },
  supportCap: { en: "Nodes by support bin", id: "Simpul menurut kelas dukungan" },
  support: { en: "Support", id: "Dukungan" },
  nodes: { en: "Nodes", id: "Simpul" },
  and: { en: "and", id: "dan" },

  // ---- Overview ------------------------------------------------------------
  heroKicker: { en: "Pohon kekerabatan hantu Nusantara", id: "Pohon kekerabatan hantu Nusantara" },
  heroLead: {
    en: (n: number, c: number) =>
      `Not a metaphor. Kuntilanak, pocong, tuyul, and ${n} more spirits of the archipelago are scored like museum specimens on ${c} traits, and <a href="https://iqtree.github.io/" class="accent whitespace-nowrap font-semibold underline underline-offset-2">IQ-TREE</a> infers their family tree with the same maximum-likelihood methods biologists use for any living organism, from bacteria to plants to people.`,
    id: (n: number, c: number) =>
      `Bukan kiasan. Kuntilanak, pocong, tuyul, dan ${n} roh lain dari Nusantara dinilai seperti spesimen museum berdasarkan ${c} sifat, lalu <a href="https://iqtree.github.io/" class="accent whitespace-nowrap font-semibold underline underline-offset-2">IQ-TREE</a> menyimpulkan pohon kekerabatannya dengan metode kemungkinan maksimum yang sama yang dipakai ahli biologi untuk makhluk hidup apa pun, dari bakteri, tumbuhan, hingga manusia.`,
  },
  aFewGhosts: { en: "A few of the ghosts", id: "Beberapa hantu" },
  statGhosts: { en: "Indonesian ghosts", id: "hantu Indonesia" },
  statOutgroups: { en: "outgroup cousins", id: "sepupu kelompok luar" },
  statChars: { en: "coded characters", id: "karakter berkode" },
  statIslands: { en: "island regions", id: "wilayah kepulauan" },
  fourWays: { en: "Four ways in", id: "Empat pintu masuk" },
  fourWaysLead: { en: "Three ways to read the same tree, and one for everything else in the data. Every ghost also has its own specimen page.", id: "Tiga cara membaca pohon yang sama, dan satu untuk semua hal lain dalam data. Setiap hantu juga punya halaman spesimennya sendiri." },
  kindAtlas: { en: "Tree and traits", id: "Pohon dan sifat" },
  kindLantern: { en: "Circular tree", id: "Pohon melingkar" },
  kindBestiary: { en: "Field guide", id: "Buku panduan lapangan" },
  kindPatterns: { en: "The whole dataset", id: "Seluruh data" },
  blurbAtlas: { en: "The rectangular tree with every coded character lined up beside it, and a card for whichever ghost you pick.", id: "Pohon persegi dengan semua karakter berkode berjajar di sampingnya, serta kartu untuk hantu mana pun yang Anda pilih." },
  blurbLantern: { en: "The tree bent into a circle on a night canvas. Light a ghost's lineage back to the root, or filter by island.", id: "Pohon yang dilengkungkan menjadi lingkaran di atas kanvas malam. Terangi garis keturunan seekor hantu hingga ke akar, atau saring menurut pulau." },
  blurbBestiary: { en: "Specimen cards in tree order, with filters for clade, island, danger, and trait, and a two-ghost comparison.", id: "Kartu spesimen menurut urutan pohon, dengan saringan klad, pulau, tingkat bahaya, dan sifat, serta perbandingan dua hantu." },
  blurbPatterns: { en: "A map of the archipelago, a trait heatmap, a danger chart made of the plates themselves, and more.", id: "Peta kepulauan, peta panas sifat, bagan bahaya yang tersusun dari pelat-pelat hantu itu sendiri, dan lainnya." },
  open: { en: (v: string) => `Open ${v}`, id: (v: string) => `Buka ${v}` },
  kinships: { en: "Strongest kinships", id: "Kekerabatan terkuat" },
  kinshipsLead: {
    en: (s: number, n: number) => `Small clades with ultrafast bootstrap of 90 or more. Most of the deep tree is unresolved: only ${s} of ${n} nodes reach 95.`,
    id: (s: number, n: number) => `Klad kecil dengan ultrafast bootstrap 90 atau lebih. Sebagian besar bagian dalam pohon belum terpecahkan: hanya ${s} dari ${n} simpul yang mencapai 95.`,
  },
  howBuilt: { en: "How the tree is built", id: "Cara pohon disusun" },
  stepParse: { en: "Parse", id: "Urai" },
  stepEncode: { en: "Encode", id: "Kodekan" },
  stepInfer: { en: "Infer", id: "Simpulkan" },
  stepPublish: { en: "Publish", id: "Terbitkan" },
  stepParseText: { en: (n: number) => `Read ${n} taxa from the dataset and clean names, clades, and regions.`, id: (n: number) => `Membaca ${n} takson dari set data serta merapikan nama, klad, dan wilayah.` },
  stepEncodeText: { en: (n: number, c: number) => `Write a ${n} × ${c} morphological matrix in Nexus format.`, id: (n: number, c: number) => `Menulis matriks morfologi ${n} × ${c} dalam format Nexus.` },
  stepInferText: { en: (s: string, m: string) => `${s} picks ${m} and runs 1000 ultrafast bootstraps.`, id: (s: string, m: string) => `${s} memilih ${m} dan menjalankan 1000 ultrafast bootstrap.` },
  stepPublishText: { en: "Root on the outgroups, draw a plate per ghost, and build this site.", id: "Mengakarkan pohon pada kelompok luar, menggambar pelat untuk setiap hantu, dan membangun situs ini." },
  workflowNote: { en: "Every push that touches the data reruns all four steps in a GitHub workflow.", id: "Setiap perubahan pada data menjalankan ulang keempat langkah ini dalam alur kerja GitHub." },
  readMethods: { en: "Read the methods", id: "Baca metodenya" },

  // ---- Specimen page -------------------------------------------------------
  neighbors: { en: "Neighbors on the tree", id: "Tetangga di pohon" },
  previous: { en: "Previous on the tree:", id: "Sebelumnya di pohon:" },
  next: { en: "Next on the tree:", id: "Berikutnya di pohon:" },
  downloadPlate: { en: "Download plate (SVG)", id: "Unduh pelat (SVG)" },
  dangerLine: { en: (n: number, l: string) => `Danger ${n} of 5 · ${l}`, id: (n: number, l: string) => `Tingkat bahaya ${n} dari 5 · ${l}` },
  charsCaption: { en: (n: number, g: string) => `The ${n} characters coded for ${g}`, id: (n: number, g: string) => `${n} karakter yang dikodekan untuk ${g}` },
  ghostDescription: { en: (n: string, m: string, r: string) => `${n}: ${m} from ${r}, placed on a phylogeny of Indonesian ghosts.`, id: (n: string, m: string, r: string) => `${n}: ${m} dari ${r}, ditempatkan pada filogeni hantu Indonesia.` },
} satisfies Record<string, { en: Value; id: Value }>;

export type Key = keyof typeof ui;

/** Interface strings for one language. Functions take their arguments. */
export function useT(lang: Lang) {
  return <K extends Key>(key: K, ...args: unknown[]): string => {
    const v = ui[key][lang] as Value;
    return typeof v === "function" ? v(...args) : v;
  };
}

export const dangerLabel = (lang: Lang, level: number) => useT(lang)(`danger${level}` as Key);

export const codingLabel = (lang: Lang, c: Coding) =>
  useT(lang)(c === "source" ? "codingSource" : c === "filled" ? "codingFilled" : "codingNew");

export const sexLabel = (lang: Lang, g: Ghost) =>
  useT(lang)(g.traits.sex === 1 ? "sexFemale" : g.traits.sex === 0 ? "sexMale" : "sexUnspecified");

/** Present traits in plain words, for chips and summaries. */
export const presentTraits = (lang: Lang, g: Ghost) =>
  data.characters
    .slice(0, 18)
    .filter((c) => c.id !== "sex" && g.traits[c.id] === 1)
    .map((c) => tr(lang, c.label));

/** A region group as shown to readers ("Outgroup" reads as a plural). */
export const regionName = (lang: Lang, r: string) => (r === "Outgroup" ? useT(lang)("outgroups") : tr(lang, r));
