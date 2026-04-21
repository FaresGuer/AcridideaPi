/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    darkMode: "class",
    theme: {
        extend: {
            colors: {
                "primary": "#3ce619",
                "background-light": "#f6f8f6",
                "background-dark": "#0a0d0a",
                "surface-dark": "#142111",
                "border-dark": "#243520",
                "sage": "#a3b899",
                "sage-accent": "#a3b899",
                "amber-alert": "#f59e0b",
                "slate-custom": "#1e293b",
                "slate-neutral": "#1e293b",
            },
            fontFamily: {
                "display": ["Space Grotesk", "sans-serif"],
                "sans": ["Space Grotesk", "sans-serif"],
            },
            borderRadius: {
                "DEFAULT": "0.25rem",
                "lg": "0.5rem",
                "xl": "0.75rem",
                "full": "9999px"
            },
        },
    },
    plugins: [],
    safelist: [
        // Add any dynamic classes here to prevent purging
        'dark:bg-background-dark',
        'light:bg-white',
    ]
}
