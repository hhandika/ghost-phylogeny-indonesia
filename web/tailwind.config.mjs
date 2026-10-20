/** @type {import('tailwindcss').Config} */
export default {
  darkMode: "class",
  content: ["./src/**/*.{astro,html,js,jsx,md,mdx,ts,tsx}"],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Figtree", "ui-sans-serif", "system-ui", "sans-serif"],
        serif: ["Newsreader", "ui-serif", "Georgia", "serif"],
      },
      colors: {
        // Ground: kain kafan, the unbleached burial shroud.
        paper: "#f5efe2",
        // Dark ground: malam Jumat Kliwon, the most haunted night of the week.
        night: "#110e1b",
        // "Malam" (night): indigo ink of a moonless sky and nila batik dye.
        malam: {
          50: "#f1f0f7",
          100: "#e2dfee",
          200: "#c6c0dd",
          300: "#a29ac4",
          400: "#7d73a6",
          500: "#5f5689",
          600: "#4a426e",
          700: "#3a3358",
          800: "#2a2442",
          900: "#1c1830",
          950: "#110e1b",
        },
        // "Kafan" (shroud): ivory to sogan brown, the batik of Solo.
        kafan: {
          50: "#fbf8f1",
          100: "#f5efe2",
          200: "#ebe1cc",
          300: "#dccdb0",
          400: "#c4ae88",
          500: "#a88f68",
          600: "#8a7253",
          700: "#6c5842",
          800: "#4f4033",
          900: "#352b24",
          950: "#1e1814",
        },
        // "Prada": the gold leaf on wayang puppets and Balinese cloth.
        prada: {
          50: "#fdf8e9",
          100: "#faefc8",
          200: "#f4dc8e",
          300: "#edc556",
          400: "#e0b03e",
          500: "#c9952a",
          600: "#a87622",
          700: "#865a1f",
          800: "#6e4a20",
          900: "#5d3e1f",
          950: "#36210e",
        },
        // "Darah" (blood): Kuntilanak Merah's dress, sirih-stained lips.
        darah: {
          50: "#fdf2f3",
          100: "#fbe3e5",
          200: "#f6c9ce",
          300: "#ee9ea7",
          400: "#e36b7a",
          500: "#d14257",
          600: "#b3243a",
          700: "#961b30",
          800: "#7d1a2d",
          900: "#6b1a2b",
          950: "#3b0912",
        },
        // "Kemenyan": the grey-violet smoke of burning benzoin incense.
        kemenyan: {
          50: "#f6f5f8",
          100: "#ebe8f0",
          200: "#d6d1e0",
          300: "#b7afc8",
          400: "#958aab",
          500: "#7a6e92",
          600: "#635879",
          700: "#524863",
          800: "#463e54",
          900: "#3c3548",
          950: "#27222f",
        },
      },
    },
  },
  plugins: [],
};
