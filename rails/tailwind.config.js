// config/tailwind.config.js
const plugin = require('tailwindcss/plugin')

module.exports = {
  darkMode: 'class',
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  safelist: [
    "bg-primary", "text-primary", "border-primary",
    "bg-secondary", "text-secondary", "border-secondary",
    "bg-accent", "text-accent", "border-accent",
    "bg-neutral", "text-neutral", "border-neutral",
    "bg-info", "text-info", "border-info",
    "bg-success", "text-success", "border-success",
    "bg-warning", "text-warning", "border-warning",
    "bg-error", "text-error", "border-error",
  ],
  theme: {
    extend: {
      colors: {
        base: {
          100: 'hsl(var(--base-100) / <alpha-value>)',
          200: 'hsl(var(--base-200) / <alpha-value>)',
          300: 'hsl(var(--base-300) / <alpha-value>)',
          400: 'hsl(var(--base-400) / <alpha-value>)',
          500: 'hsl(var(--base-500) / <alpha-value>)',
          600: 'hsl(var(--base-600) / <alpha-value>)',
          700: 'hsl(var(--base-700) / <alpha-value>)',
          800: 'hsl(var(--base-800) / <alpha-value>)',
          900: 'hsl(var(--base-900) / <alpha-value>)',
        }
      }
    }
  },
  plugins: [
    require('daisyui'),
    plugin(function({ addBase }) {
      addBase({
        ':root': {
          '--base-100': '40 20% 97%',
          '--base-200': '40 15% 92%',
          '--base-300': '40 12% 87%',
          '--base-400': '40 10% 70%',
          '--base-500': '40 8% 50%',
          '--base-600': '40 8% 35%',
          '--base-700': '40 10% 20%',
          '--base-800': '40 12% 12%',
          '--base-900': '40 15% 5%',
        },
        '[data-theme="dark"]': {
          '--base-100': '220 15% 10%',
          '--base-200': '220 12% 15%',
          '--base-300': '220 10% 20%',
          '--base-400': '220 9% 35%',
          '--base-500': '220 8% 50%',
          '--base-600': '220 9% 65%',
          '--base-700': '220 10% 80%',
          '--base-800': '220 12% 90%',
          '--base-900': '220 15% 97%',
        }
      })
    })
  ],
  daisyui: {
    themes: [
      {
        light: {
          ...require("daisyui/src/theming/themes")["light"],
          "primary": "hsl(14 43% 51%)",
          "primary-content": "#ffffff",
          "secondary": "hsl(96 11% 49%)",
          "secondary-content": "#ffffff",
          "accent": "hsl(7 34% 48%)",
          "accent-content": "#ffffff",
          "neutral": "hsl(28 25% 29%)",
          "neutral-content": "#ffffff",
          "info": "hsl(263 14% 58%)",
          "info-content": "#ffffff",
          "success": "hsl(104 25% 54%)",
          "warning": "hsl(50 85% 68%)",
          "error": "hsl(10 54% 49%)",
          "base-100": "hsl(40 20% 97%)",
          "base-200": "hsl(40 15% 92%)",
          "base-300": "hsl(40 12% 87%)",
          "base-400": "hsl(40 10% 70%)",
          "base-500": "hsl(40 8% 50%)",
          "base-600": "hsl(40 8% 35%)",
          "base-700": "hsl(40 10% 20%)",
          "base-800": "hsl(40 12% 12%)",
          "base-900": "hsl(40 15% 5%)",
        },
        dark: {
          ...require("daisyui/src/theming/themes")["dark"],
          "primary": "hsl(12 58% 64%)",
          "primary-content": "#ffffff",
          "secondary": "hsl(95 16% 60%)",
          "secondary-content": "#ffffff",
          "accent": "hsl(11 61% 61%)",
          "accent-content": "#ffffff",
          "neutral": "hsl(40 29% 91%)",
          "neutral-content": "#ffffff",
          "info": "hsl(266 20% 66%)",
          "info-content": "#ffffff",
          "success": "hsl(101 31% 62%)",
          "warning": "hsl(52 77% 74%)",
          "error": "hsl(8 73% 63%)",
          "base-100": "hsl(220 15% 10%)",
          "base-200": "hsl(220 12% 15%)",
          "base-300": "hsl(220 10% 20%)",
          "base-400": "hsl(220 9% 35%)",
          "base-500": "hsl(220 8% 50%)",
          "base-600": "hsl(220 9% 65%)",
          "base-700": "hsl(220 10% 80%)",
          "base-800": "hsl(220 12% 90%)",
          "base-900": "hsl(220 15% 97%)",
        },
      },
    ],
    darkTheme: "dark",
    base: true,
    styled: true,
    utils: true,
  },
}
