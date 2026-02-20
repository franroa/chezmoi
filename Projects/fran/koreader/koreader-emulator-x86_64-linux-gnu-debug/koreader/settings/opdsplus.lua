-- ./settings/opdsplus.lua
return {
    ["downloads"] = {},
    ["pending_syncs"] = {},
    ["servers"] = {
        [1] = {
            ["title"] = "Project Gutenberg",
            ["url"] = "https://m.gutenberg.org/ebooks.opds/?format=opds",
        },
        [2] = {
            ["title"] = "Standard Ebooks",
            ["url"] = "https://standardebooks.org/feeds/opds",
        },
        [3] = {
            ["title"] = "ManyBooks",
            ["url"] = "http://manybooks.net/opds/index.php",
        },
        [4] = {
            ["title"] = "Internet Archive",
            ["url"] = "https://bookserver.archive.org/",
        },
        [5] = {
            ["title"] = "textos.info (Spanish)",
            ["url"] = "https://www.textos.info/catalogo.atom",
        },
        [6] = {
            ["title"] = "Gallica (French)",
            ["url"] = "https://gallica.bnf.fr/opds",
        },
    },
    ["settings"] = {
        ["cover_height_ratio"] = 0.1,
        ["cover_size_preset"] = "Regular",
        ["debug_mode"] = false,
        ["display_mode"] = "list",
        ["grid_border_color"] = "dark_gray",
        ["grid_border_size"] = 2,
        ["grid_border_style"] = "none",
        ["grid_columns"] = 3,
        ["grid_cover_height_ratio"] = 0.2,
        ["grid_size_preset"] = "Balanced",
        ["info_bold"] = false,
        ["info_color"] = "dark_gray",
        ["info_font"] = "smallinfofont",
        ["info_size"] = 14,
        ["title_bold"] = true,
        ["title_font"] = "smallinfofont",
        ["title_size"] = 16,
        ["use_same_font"] = true,
    },
}
