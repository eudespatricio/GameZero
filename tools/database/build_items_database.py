#!/usr/bin/env python3
"""
Gerador Canônico de Banco de Itens do GameZero (items_database.gd)
Gera:
- 21 Sets de Armadura completos (6 peças cada: head, shoulders, chest, gloves, pants, boots)
- 21 Armas especializadas por classe e tier
- 15 Escudos e Acessórios de Off-hand
- 15 Capas (1 por faixa de 10 lvls por classe)
- Asas Tiers 1 (Lv 30), 2 (Lv 40), 3 (Lv 50)
- 5 Tiers de Pets e Dragões
- Joias e Consumíveis MU Online
- Método canônico get_set_bonus(set_name, count) e get_all_sets()
"""

import os

OUTPUT_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "scripts/data/items_database.gd")

SETS_CONFIG = [
    # --- ZERO (Cavaleiro de Dragão) ---
    {
        "id": "recruta_carvahall", "name": "do Recruta de Carvahall", "class": "zero",
        "tier": 1, "min_lvl": 1, "rarity": "COMMON", "def_base": 18,
        "bonus_2": {"strength": 10}, "bonus_4": {"armor_pct": 12.0}, "bonus_6": {"all_damage_pct": 10.0}
    },
    {
        "id": "escudeiro_aco", "name": "do Escudeiro de Aço", "class": "zero",
        "tier": 2, "min_lvl": 11, "rarity": "MAGIC", "def_base": 45,
        "bonus_2": {"strength": 22}, "bonus_4": {"move_speed_pct": 15.0}, "bonus_6": {"fire_damage_pct": 18.0}
    },
    {
        "id": "cavaleiro_fogo", "name": "do Cavaleiro de Fogo", "class": "zero",
        "tier": 3, "min_lvl": 21, "rarity": "RARE", "def_base": 85,
        "bonus_2": {"strength": 38, "willpower": 25}, "bonus_4": {"cooldown_reduction": 15.0}, "bonus_6": {"burn_dot_pct": 25.0}
    },
    {
        "id": "dragon_knight", "name": "do Dragão Carmesim", "class": "zero",
        "tier": 4, "min_lvl": 31, "rarity": "EPIC", "def_base": 140,
        "bonus_2": {"strength": 55, "willpower": 40}, "bonus_4": {"barrier_absorb_pct": 20.0}, "bonus_6": {"fire_damage_pct": 35.0}
    },
    {
        "id": "soberano_sylveria", "name": "do Soberano de Sylveria", "class": "zero",
        "tier": 5, "min_lvl": 41, "rarity": "EPIC", "def_base": 210,
        "bonus_2": {"strength": 80, "willpower": 65}, "bonus_4": {"all_damage_pct": 30.0}, "bonus_6": {"meteor_proc_chance": 25.0}
    },
    {
        "id": "primeiros_cavaleiros", "name": "dos Primeiros Cavaleiros", "class": "zero",
        "tier": 5, "min_lvl": 1, "rarity": "LEGENDARY", "def_base": 260,
        "bonus_2": {"strength": 95, "willpower": 85}, "bonus_4": {"cooldown_reduction": 25.0}, "bonus_6": {"astral_shockwave_proc": 35.0}
    },
    {
        "id": "cosmico_vermund", "name": "Cósmico de Vermund", "class": "zero",
        "tier": 5, "min_lvl": 1, "rarity": "DIVINE", "def_base": 340,
        "bonus_2": {"strength": 140, "willpower": 120}, "bonus_4": {"all_damage_pct": 45.0}, "bonus_6": {"death_immunity_90s": 1.0, "divine_fire_pct": 50.0}
    },

    # --- ARYA (Guardiã Élfica) ---
    {
        "id": "rastreador_bosques", "name": "do Rastreador dos Bosques", "class": "arya",
        "tier": 1, "min_lvl": 1, "rarity": "COMMON", "def_base": 14,
        "bonus_2": {"dexterity": 10}, "bonus_4": {"move_speed_pct": 10.0}, "bonus_6": {"crit_chance": 6.0}
    },
    {
        "id": "patrulha_elfica", "name": "da Patrulha Élfica", "class": "arya",
        "tier": 2, "min_lvl": 11, "rarity": "MAGIC", "def_base": 36,
        "bonus_2": {"dexterity": 22}, "bonus_4": {"dodge_pct": 12.0}, "bonus_6": {"crit_damage_pct": 20.0}
    },
    {
        "id": "sombras_weldenvarden", "name": "das Sombras de Du Weldenvarden", "class": "arya",
        "tier": 3, "min_lvl": 21, "rarity": "RARE", "def_base": 70,
        "bonus_2": {"dexterity": 40, "willpower": 25}, "bonus_4": {"attack_speed_pct": 20.0}, "bonus_6": {"bleed_on_crit_pct": 30.0}
    },
    {
        "id": "prata_menoa", "name": "da Lâmina de Prata de Menoa", "class": "arya",
        "tier": 4, "min_lvl": 31, "rarity": "EPIC", "def_base": 115,
        "bonus_2": {"dexterity": 60, "willpower": 42}, "bonus_4": {"crit_damage_pct": 35.0}, "bonus_6": {"illusion_clone_dodge": 25.0}
    },
    {
        "id": "nobreza_ellesmera", "name": "da Nobreza de Ellesméra", "class": "arya",
        "tier": 5, "min_lvl": 41, "rarity": "EPIC", "def_base": 175,
        "bonus_2": {"dexterity": 85, "willpower": 65}, "bonus_4": {"penetration_pct": 35.0}, "bonus_6": {"floral_step_reset_on_kill": 1.0}
    },
    {
        "id": "rainha_islanzadi", "name": "da Rainha Islanzadí", "class": "arya",
        "tier": 5, "min_lvl": 1, "rarity": "LEGENDARY", "def_base": 220,
        "bonus_2": {"dexterity": 105, "willpower": 85}, "bonus_4": {"crit_chance": 25.0}, "bonus_6": {"menoa_bloom_annihilation": 40.0}
    },
    {
        "id": "astral_menoa", "name": "Astral da Deusa Menoa", "class": "arya",
        "tier": 5, "min_lvl": 1, "rarity": "DIVINE", "def_base": 290,
        "bonus_2": {"dexterity": 150, "willpower": 125}, "bonus_4": {"crit_damage_pct": 60.0}, "bonus_6": {"death_immunity_90s": 1.0, "true_pierce_100": 1.0}
    },

    # --- RORAN (Martelo-Forte) ---
    {
        "id": "aprendiz_forja", "name": "do Aprendiz de Forja", "class": "roran",
        "tier": 1, "min_lvl": 1, "rarity": "COMMON", "def_base": 24,
        "bonus_2": {"vitality": 12}, "bonus_4": {"armor_pct": 15.0}, "bonus_6": {"max_hp_bonus": 250.0}
    },
    {
        "id": "milicia_espinha", "name": "da Milícia da Espinha", "class": "roran",
        "tier": 2, "min_lvl": 11, "rarity": "MAGIC", "def_base": 55,
        "bonus_2": {"vitality": 26, "strength": 20}, "bonus_4": {"block_chance": 12.0}, "bonus_6": {"damage_reduction_pct": 12.0}
    },
    {
        "id": "rompedor_batalha", "name": "do Rompedor de Batalha", "class": "roran",
        "tier": 3, "min_lvl": 21, "rarity": "RARE", "def_base": 105,
        "bonus_2": {"vitality": 48, "strength": 38}, "bonus_4": {"armor_pct": 25.0}, "bonus_6": {"seismic_stun_duration": 1.5}
    },
    {
        "id": "flagelo_kulls", "name": "do Flagelo dos Kulls", "class": "roran",
        "tier": 4, "min_lvl": 31, "rarity": "EPIC", "def_base": 170,
        "bonus_2": {"vitality": 70, "strength": 55}, "bonus_4": {"block_chance": 22.0}, "bonus_6": {"reflect_damage_pct": 35.0}
    },
    {
        "id": "inquebravel_farthen", "name": "do Inquebrável de Farthen Dûr", "class": "roran",
        "tier": 5, "min_lvl": 41, "rarity": "EPIC", "def_base": 245,
        "bonus_2": {"vitality": 100, "strength": 80}, "bonus_4": {"armor_pct": 40.0}, "bonus_6": {"berserk_dmg_scale_pct": 50.0}
    },
    {
        "id": "rei_hrothgar", "name": "do Rei Hrothgar", "class": "roran",
        "tier": 5, "min_lvl": 1, "rarity": "LEGENDARY", "def_base": 300,
        "bonus_2": {"vitality": 125, "strength": 100}, "bonus_4": {"damage_reduction_pct": 25.0}, "bonus_6": {"titan_quake_aoe_triple": 1.0}
    },
    {
        "id": "titanico_helzvog", "name": "Titânico de Helzvog", "class": "roran",
        "tier": 5, "min_lvl": 1, "rarity": "DIVINE", "def_base": 390,
        "bonus_2": {"vitality": 180, "strength": 140}, "bonus_4": {"max_hp_bonus": 1500.0}, "bonus_6": {"death_immunity_90s": 1.0, "titan_invulnerable_barrier": 1.0}
    }
]

PIECES = [
    ("helm", "🪖 Elmo", "ARMOR_HEAD", 1.0, "head"),
    ("shoulders", "🛡️ Ombreiras", "ARMOR_SHOULDER", 0.75, "shoulders"),
    ("chest", "🥋 Peitoral", "ARMOR_CHEST", 1.45, "chest"),
    ("gloves", "🧤 Luvas", "ARMOR_GLOVES", 0.70, "gloves"),
    ("pants", "👖 Calças", "ARMOR_PANTS", 1.15, "pants"),
    ("boots", "🥾 Botas", "ARMOR_BOOTS", 0.80, "boots"),
]

def generate():
    lines = []
    lines.append('extends RefCounted')
    lines.append('class_name ItemsDatabase')
    lines.append('## Catálogo Canônico de Itens, Sets, Asas, Capas e Joias do GameZero.')
    lines.append('')
    lines.append('enum Rarity {')
    lines.append('\tCOMMON,      # 0 Cinza (Ferro Rústico)')
    lines.append('\tMAGIC,       # 1 Verde (Imbuído com Ervas/Runas)')
    lines.append('\tRARE,        # 2 Azul (Aço Temperado)')
    lines.append('\tEPIC,        # 3 Roxo (Relíquias de Batalha)')
    lines.append('\tLEGENDARY,   # 4 Dourado (Brightsteel / Ouro Élfico)')
    lines.append('\tMYTHIC,      # 5 Vermelho / Mítico (Reis Cavaleiros)')
    lines.append('\tDIVINE       # 6 Rosa Prismático / Celestial (Origem Primordial)')
    lines.append('}')
    lines.append('')
    lines.append('enum ItemType {')
    lines.append('\tWEAPON,            # Arma Principal')
    lines.append('\tWEAPON_OFFHAND,    # Escudo / Orbe Secundário')
    lines.append('\tARMOR_HEAD,        # Elmo')
    lines.append('\tARMOR_SHOULDER,    # Ombreiras')
    lines.append('\tARMOR_CHEST,       # Peitoral')
    lines.append('\tARMOR_GLOVES,      # Luvas')
    lines.append('\tARMOR_PANTS,       # Calças')
    lines.append('\tARMOR_BOOTS,       # Botas')
    lines.append('\tCAPE,              # Capa')
    lines.append('\tWINGS,             # Asas')
    lines.append('\tAMULET,            # Colar / Amuleto')
    lines.append('\tRING,              # Anel')
    lines.append('\tMOUNT,             # Montaria (Dragão)')
    lines.append('\tPET,               # Pet Companheiro')
    lines.append('\tTOME,              # Livro de Habilidade')
    lines.append('\tJEWEL,             # Joias MU Online')
    lines.append('\tCONSUMABLE         # Poções e Pedras')
    lines.append('}')
    lines.append('')
    lines.append('static func get_all_items() -> Dictionary:')
    lines.append('\treturn {')

    # 1. Joias
    lines.append('\t\t# --- JOIAS ESTILO MU ONLINE ---')
    jewels = [
        ('jewel_bless', '💎 Joia da Bênção (Bless)', 'RARE', 5000, 'Color(0.2, 0.7, 1.0)', 'Aprimora equipamentos de +0 até +6 com 100% de sucesso. Emite sino cristalino lendário ao tocar o chão.'),
        ('jewel_soul', '🔮 Joia da Alma (Soul)', 'EPIC', 15000, 'Color(0.8, 0.3, 0.9)', 'Fragmento de alma de dragão ancestral. Necessária para refinos de +7 até +9.'),
        ('jewel_chaos', '🔥 Joia do Caos (Chaos)', 'EPIC', 25000, 'Color(1.0, 0.4, 0.1)', 'Energia elemental da Máquina do Caos. Essencial para criar Asas e elevar equipamentos de +10 a +15.'),
        ('jewel_creation', '💎 Joia da Criação (Creation)', 'LEGENDARY', 50000, 'Color(0.95, 0.85, 0.25)', 'Cristal puro que emana energia primordial do santuário de Sylveria.')
    ]
    for k, name, rar, val, col, desc in jewels:
        lines.append(f'\t\t"{k}": {{')
        lines.append(f'\t\t\t"name": "{name}",')
        lines.append(f'\t\t\t"type": ItemType.JEWEL,')
        lines.append(f'\t\t\t"rarity": Rarity.{rar},')
        lines.append(f'\t\t\t"description": "{desc}",')
        lines.append(f'\t\t\t"value_gold": {val},')
        lines.append(f'\t\t\t"glow_color": {col}')
        lines.append('\t\t},')

    # 2. As 21 Sets de Armadura (6 peças cada)
    lines.append('\n\t\t# --- OS 21 SETS DE ARMADURA (6 PEÇAS POR SET) ---')
    for s in SETS_CONFIG:
        for p_code, p_name_prefix, i_type, def_mult, slot_name in PIECES:
            key = f"{p_code}_{s['id']}"
            display_name = f"{p_name_prefix} {s['name']}"
            base_def = int(s["def_base"] * def_mult)
            magic_res = int(base_def * 0.45)
            gold_val = int(s["tier"] * 4500 * def_mult)
            lines.append(f'\t\t"{key}": {{')
            lines.append(f'\t\t\t"name": "{display_name}",')
            lines.append(f'\t\t\t"type": ItemType.{i_type},')
            lines.append(f'\t\t\t"rarity": Rarity.{s["rarity"]},')
            lines.append(f'\t\t\t"class_req": "{s["class"]}",')
            lines.append(f'\t\t\t"level_req": {s["min_lvl"]},')
            lines.append(f'\t\t\t"base_defense": {base_def},')
            lines.append(f'\t\t\t"magic_resist": {magic_res},')
            lines.append(f'\t\t\t"set_name": "{s["id"]}",')
            lines.append(f'\t\t\t"set_display_name": "{s["name"]}",')
            lines.append(f'\t\t\t"value_gold": {gold_val}')
            lines.append('\t\t},')

    # 3. Armas por classe e tier (7 por classe = 21 armas)
    lines.append('\n\t\t# --- ARMAS ESPECIALIZADAS POR CLASSE (21 ARMAS) ---')
    weapons_data = [
        # Zero (Espadas)
        ("sword_recruta", "🗡️ Espada de Treino de Carvahall", "zero", 1, "COMMON", 45, 1200),
        ("sword_escudeiro", "🗡️ Espada Larga de Aço de Sylveria", "zero", 11, "MAGIC", 110, 4800),
        ("sword_fogo", "🔥 Espada Flamejante dos Cavaleiros", "zero", 21, "RARE", 215, 14000),
        ("sword_brisingr", "⚔️ Brisingr (A Lâmina de Fogo)", "zero", 31, "EPIC", 380, 42000),
        ("sword_soberana", "⚔️ Espada Bastarda do Soberano", "zero", 41, "EPIC", 560, 95000),
        ("sword_zarroc", "🩸 Zar'roc (A Lâmina Carmesim da Miséria)", "zero", 1, "LEGENDARY", 740, 220000),
        ("sword_vermund_divine", "🌟 Lâmina Solar Primordial de Vermund", "zero", 1, "DIVINE", 980, 600000),

        # Arya (Lâminas Élficas & Arcos)
        ("blade_rastreador", "🗡️ Adaga Curta dos Bosques", "arya", 1, "COMMON", 42, 1100),
        ("bow_patrulha", "🏹 Arco Recurvo da Patrulha", "arya", 11, "MAGIC", 105, 4600),
        ("blade_sombras", "🗡️ Florete das Sombras de Du Weldenvarden", "arya", 21, "RARE", 205, 13500),
        ("bow_ellesmera", "🏹 Arco Longo Sagrado de Ellesméra", "arya", 31, "EPIC", 365, 41000),
        ("blade_nobreza", "🗡️ Lâmina Fina da Nobreza Élfica", "arya", 41, "EPIC", 540, 92000),
        ("blade_tamerlein", "⚔️ Tamerlein (A Espada Verde Esmeralda)", "arya", 1, "LEGENDARY", 720, 215000),
        ("bow_menoa_divine", "🌟 Arco Astral da Grande Árvore Menoa", "arya", 1, "DIVINE", 960, 590000),

        # Roran (Martelos & Machados)
        ("hammer_aprendiz", "🔨 Martelo Forjado Rústico", "roran", 1, "COMMON", 52, 1300),
        ("hammer_milicia", "🔨 Martelo de Guerra Pesado", "roran", 11, "MAGIC", 125, 5200),
        ("hammer_rompedor", "🔨 Quebra-Crânios dos Vales", "roran", 21, "RARE", 240, 15500),
        ("hammer_kulls", "🔨 Demolidor de Urgals e Kulls", "roran", 31, "EPIC", 410, 45000),
        ("hammer_roran", "🔨 O Martelo-Forte de Carvahall", "roran", 41, "EPIC", 610, 105000),
        ("hammer_volund", "⚡ Volund (O Machado do Rei Anão)", "roran", 1, "LEGENDARY", 790, 240000),
        ("hammer_helzvog_divine", "🌟 Martelo Titânico Criador de Helzvog", "roran", 1, "DIVINE", 1050, 650000),
    ]
    for wid, wname, wclass, wlvl, wrar, watk, wgold in weapons_data:
        lines.append(f'\t\t"{wid}": {{')
        lines.append(f'\t\t\t"name": "{wname}",')
        lines.append(f'\t\t\t"type": ItemType.WEAPON,')
        lines.append(f'\t\t\t"rarity": Rarity.{wrar},')
        lines.append(f'\t\t\t"class_req": "{wclass}",')
        lines.append(f'\t\t\t"level_req": {wlvl},')
        lines.append(f'\t\t\t"base_attack": {watk},')
        lines.append(f'\t\t\t"value_gold": {wgold}')
        lines.append('\t\t},')

    # 4. Escudos e Off-hands (7)
    lines.append('\n\t\t# --- ESCUDOS E ACESSÓRIOS OFF-HAND ---')
    offhands = [
        ("shield_madeira", "🛡️ Escudo de Madeira com Rebites de Ferro", "roran", 1, "COMMON", 25, 800),
        ("shield_aco", "🛡️ Escudo de Aço Maciço da Espinha", "roran", 11, "MAGIC", 60, 3200),
        ("shield_dragon_scale", "🛡️ Escudo de Escamas de Dragão", "zero", 31, "EPIC", 160, 38000),
        ("shield_farthen_dur", "🛡️ Broquel Rúnico dos Anões", "roran", 41, "EPIC", 220, 85000),
        ("shield_hrothgar", "🛡️ Baluarte da Barreira de Farthen Dûr", "roran", 1, "LEGENDARY", 310, 210000),
        ("shield_helzvog", "🌟 Muralha Indestrutível de Helzvog", "roran", 1, "MYTHIC", 420, 520000),
        ("orb_angela", "🔮 Orbe da Vidente Angela", "zero", 25, "RARE", 95, 22000),
        ("orb_astral", "🌟 Orbe Astral dos Espíritos Ancestrais", "arya", 41, "EPIC", 185, 88000)
    ]
    for oid, oname, oclass, olvl, orar, odef, ogold in offhands:
        lines.append(f'\t\t"{oid}": {{')
        lines.append(f'\t\t\t"name": "{oname}",')
        lines.append(f'\t\t\t"type": ItemType.WEAPON_OFFHAND,')
        lines.append(f'\t\t\t"rarity": Rarity.{orar},')
        lines.append(f'\t\t\t"class_req": "{oclass}",')
        lines.append(f'\t\t\t"level_req": {olvl},')
        lines.append(f'\t\t\t"base_defense": {odef},')
        lines.append(f'\t\t\t"value_gold": {ogold}')
        lines.append('\t\t},')

    # 5. Asas (Wings: Nv 30, 40, 50)
    lines.append('\n\t\t# --- ASAS (REQUISITOS DE NÍVEL RÍGIDOS: 30, 40, 50) ---')
    wings_data = [
        ("wings_tier1", "🪽 Asas Espirituais de Fada (Nvl 1)", 1, 30, "RARE", 1.20, 15.0, 15.0, 60000, "Asas etéreas leves com energia feérica. Concedem velocidade e absorção básica."),
        ("wings_crystal_tier2", "🪽 Asas de Cristal Puro (Nvl 2)", 2, 40, "EPIC", 1.35, 30.0, 30.0, 180000, "Forjadas na Máquina do Caos com Joias Creation. Emanam brilho translúcido estonteante."),
        ("wings_tier3_supreme", "🪽 Asas Cósmicas de Saphira (Nvl 3 / Supremas)", 3, 50, "LEGENDARY", 1.50, 50.0, 50.0, 500000, "A glória suprema dos Cavaleiros. Deixam rastro de partículas celestes e concedem poder supremo.")
    ]
    for wid, wname, wtier, wlvl, wrar, wspeed, wdmg, wabs, wval, wdesc in wings_data:
        lines.append(f'\t\t"{wid}": {{')
        lines.append(f'\t\t\t"name": "{wname}",')
        lines.append(f'\t\t\t"type": ItemType.WINGS,')
        lines.append(f'\t\t\t"tier": {wtier},')
        lines.append(f'\t\t\t"level_req": {wlvl},')
        lines.append(f'\t\t\t"rarity": Rarity.{wrar},')
        lines.append(f'\t\t\t"move_speed_multiplier": {wspeed},')
        lines.append(f'\t\t\t"damage_bonus_pct": {wdmg},')
        lines.append(f'\t\t\t"absorb_bonus_pct": {wabs},')
        lines.append(f'\t\t\t"value_gold": {wval},')
        lines.append(f'\t\t\t"description": "{wdesc}"')
        lines.append('\t\t},')

    # 6. Capas por classe (1 por faixa de 10 lvls = 15 capas)
    lines.append('\n\t\t# --- CAPAS (1 POR FAIXA DE 10 NÍVEIS POR CLASSE = 15 CAPAS) ---')
    capes_data = [
        # Zero
        ("cape_recruta_1", "🧣 Capa de Linho do Recruta", "zero", 1, "COMMON", 15, 1000),
        ("cape_escudeiro_2", "🧣 Manto de Aço do Escudeiro", "zero", 11, "MAGIC", 35, 3500),
        ("cape_rider", "🧣 Manto dos Cavaleiros de Dragão", "zero", 21, "RARE", 75, 12000),
        ("cape_dragao_4", "🧣 Capa de Escamas Carmesim", "zero", 31, "EPIC", 130, 35000),
        ("cape_soberano_5", "🧣 Manto Estelar do Soberano", "zero", 41, "LEGENDARY", 210, 95000),

        # Arya
        ("cape_linho_1", "🧣 Manto de Camuflagem dos Bosques", "arya", 1, "COMMON", 12, 1000),
        ("cape_patrulha_2", "🧣 Capa da Patrulha de Ellesméra", "arya", 11, "MAGIC", 30, 3500),
        ("cape_elven_cloak", "🧣 Manto dos Bosques de Du Weldenvarden", "arya", 21, "RARE", 68, 12000),
        ("cape_mestre_4", "🧣 Capa da Ordem dos Magos Élficos", "arya", 31, "EPIC", 120, 35000),
        ("cape_rainha_5", "🧣 Manto da Rainha das Estrelas", "arya", 41, "LEGENDARY", 195, 95000),

        # Roran
        ("cape_pele_1", "🧣 Manto de Peles de Urso", "roran", 1, "COMMON", 20, 1000),
        ("cape_couro_2", "🧣 Capa de Couro Reforçado da Espinha", "roran", 11, "MAGIC", 45, 3500),
        ("cape_carvahall_3", "🧣 Manto da Resistência de Carvahall", "roran", 21, "RARE", 90, 12000),
        ("cape_kulls_4", "🧣 Capa Pesada do Conquistador", "roran", 31, "EPIC", 155, 35000),
        ("cape_titan_5", "🧣 Manto Indomável dos Anões de Beor", "roran", 41, "LEGENDARY", 240, 95000),
    ]
    for cid, cname, cclass, clvl, crar, cdef, cgold in capes_data:
        lines.append(f'\t\t"{cid}": {{')
        lines.append(f'\t\t\t"name": "{cname}",')
        lines.append(f'\t\t\t"type": ItemType.CAPE,')
        lines.append(f'\t\t\t"rarity": Rarity.{crar},')
        lines.append(f'\t\t\t"class_req": "{cclass}",')
        lines.append(f'\t\t\t"level_req": {clvl},')
        lines.append(f'\t\t\t"base_defense": {cdef},')
        lines.append(f'\t\t\t"value_gold": {cgold}')
        lines.append('\t\t},')

    # 7. Pets e Dragões
    lines.append('\n\t\t# --- PETS E MONTARIAS ---')
    pets_data = [
        ("pet_cao_guarda", "🐾 Cão de Caça Leal (Tier 1)", "COMMON", 1, 5000, "Coleta moedas de ouro próximas.", 100.0, 0.0),
        ("pet_falcao_ventos", "🐾 Falcão dos Ventos (Tier 2)", "MAGIC", 11, 15000, "Coleta poções e materiais comuns. +8% Vel. Ataque.", 150.0, 8.0),
        ("pet_mystic_owl", "🐾 Coruja dos Presságios (Tier 3)", "RARE", 21, 45000, "Alerta contra emboscadas e coleta orbes. +12% Dano Crítico.", 200.0, 12.0),
        ("pet_raposa_astral", "🐾 Raposa Astral de Menoa (Tier 4)", "EPIC", 31, 120000, "Coleta joias Bless e Soul automaticamente. +15% Regen de Mana.", 300.0, 18.0),
        ("pet_baby_dragon", "🐾 Dragãozinho Filhote Nieda (Tier 5)", "LEGENDARY", 41, 350000, "Sucção magnética de tela inteira. +15% Dano Geral e +25% Magic Find.", 500.0, 25.0)
    ]
    for pid, pname, prar, plvl, pval, pdesc, php, pdmg in pets_data:
        lines.append(f'\t\t"{pid}": {{')
        lines.append(f'\t\t\t"name": "{pname}",')
        lines.append(f'\t\t\t"type": ItemType.PET,')
        lines.append(f'\t\t\t"rarity": Rarity.{prar},')
        lines.append(f'\t\t\t"level_req": {plvl},')
        lines.append(f'\t\t\t"description": "{pdesc}",')
        lines.append(f'\t\t\t"max_hp_bonus": {php},')
        lines.append(f'\t\t\t"value_gold": {pval}')
        lines.append('\t\t},')

    # Montarias
    lines.append('\t\t"mount_saphira": {')
    lines.append('\t\t\t"name": "🐉 Saphira (A Dama Safira)",')
    lines.append('\t\t\t"type": ItemType.MOUNT,')
    lines.append('\t\t\t"rarity": Rarity.MYTHIC,')
    lines.append('\t\t\t"level_req": 30,')
    lines.append('\t\t\t"move_speed_bonus": 2.2,')
    lines.append('\t\t\t"value_gold": 500000')
    lines.append('\t\t},')

    # 8. Anéis e Colares
    lines.append('\n\t\t# --- ANÉIS E COLARES ---')
    accessories = [
        ("ring_mithril", "💍 Anel de Mithril Élfico", "RING", "RARE", 15, {"magic_resist": 45, "willpower": 12}, 18000),
        ("ring_aren", "💍 Aren (O Anel da Princesa Brom)", "RING", "EPIC", 25, {"max_mp": 280, "spell_power": 45}, 48000),
        ("ring_starfire", "💍 Anel de Fogo Estelar", "RING", "LEGENDARY", 35, {"fire_dmg_pct": 22.0, "strength": 25}, 120000),
        ("ring_vermund_divine", "💍 Selo Cósmico de Vermund", "RING", "MYTHIC", 1, {"all_stats": 30, "all_damage_pct": 20.0}, 450000),
        ("amulet_menoa_tear", "📿 Lágrima de Menoa", "AMULET", "RARE", 20, {"max_hp": 350, "hp_regen": 5.0}, 22000),
        ("amulet_ancient_language", "📿 Colar da Língua Antiga", "AMULET", "EPIC", 30, {"all_stats": 18, "cooldown_reduction": 10.0}, 65000),
        ("amulet_helzvog_eye", "📿 Olho Titânico de Helzvog", "AMULET", "MYTHIC", 1, {"armor_pct": 35.0, "max_hp": 800}, 480000)
    ]
    for aid, aname, atype, arar, alvl, astats, agold in accessories:
        lines.append(f'\t\t"{aid}": {{')
        lines.append(f'\t\t\t"name": "{aname}",')
        lines.append(f'\t\t\t"type": ItemType.{atype},')
        lines.append(f'\t\t\t"rarity": Rarity.{arar},')
        lines.append(f'\t\t\t"level_req": {alvl},')
        for sk, sv in astats.items():
            lines.append(f'\t\t\t"{sk}": {sv},')
        lines.append(f'\t\t\t"value_gold": {agold}')
        lines.append('\t\t},')

    # 9. Consumíveis e Materiais
    lines.append('\n\t\t# --- CONSUMÍVEIS E MATERIAIS ---')
    consumables = [
        ("potion_health", "🧪 Poção de Vida Grande", "CONSUMABLE", "MAGIC", 150, "Restaura instantaneamente 1.200 pontos de vida."),
        ("potion_mana", "🧪 Poção de Mana Grande", "CONSUMABLE", "MAGIC", 150, "Restaura instantaneamente 800 pontos de mana."),
        ("fairth_stone", "💎 Pedra de Fairth (Memória)", "CONSUMABLE", "RARE", 2500, "Cristal de luz que grava imagens da mente."),
        ("brightsteel_fragment", "🔩 Fragmento de Brightsteel", "CONSUMABLE", "EPIC", 5000, "Metal estelar raríssimo usado na forja das lâminas dos Cavaleiros."),
        ("menoa_bark", "🪵 Casca da Grande Árvore Menoa", "CONSUMABLE", "RARE", 1800, "Madeira élfica sagrada usada em cajados, arcos e escudos."),
        ("tome_ancient_language", "📖 Tomo da Língua Antiga", "TOME", "EPIC", 35000, "Ensina o vocábulo de poder primordial.")
    ]
    for cid, cname, ctype, crar, cgold, cdesc in consumables:
        lines.append(f'\t\t"{cid}": {{')
        lines.append(f'\t\t\t"name": "{cname}",')
        lines.append(f'\t\t\t"type": ItemType.{ctype},')
        lines.append(f'\t\t\t"rarity": Rarity.{crar},')
        lines.append(f'\t\t\t"value_gold": {cgold},')
        lines.append(f'\t\t\t"description": "{cdesc}"')
        lines.append('\t\t},')

    lines.append('\t}')
    lines.append('')

    # Helper métodos
    lines.append('## Retorna o dicionário de todos os 21 sets com seus metadados')
    lines.append('static func get_all_sets() -> Dictionary:')
    lines.append('\tvar dict = {}')
    for s in SETS_CONFIG:
        lines.append(f'\tdict["{s["id"]}"] = {{')
        lines.append(f'\t\t"name": "{s["name"]}",')
        lines.append(f'\t\t"class": "{s["class"]}",')
        lines.append(f'\t\t"tier": {s["tier"]},')
        lines.append(f'\t\t"bonus_2": {str(s["bonus_2"])},')
        lines.append(f'\t\t"bonus_4": {str(s["bonus_4"])},')
        lines.append(f'\t\t"bonus_6": {str(s["bonus_6"])}')
        lines.append('\t}')
    lines.append('\treturn dict')
    lines.append('')

    lines.append('## Retorna os bônus de conjunto ativos conforme a quantidade de peças equipadas')
    lines.append('static func get_set_bonus(set_name: String, piece_count: int) -> Dictionary:')
    lines.append('\tvar sets = get_all_sets()')
    lines.append('\tif not sets.has(set_name):')
    lines.append('\t\treturn {}')
    lines.append('\tvar s = sets[set_name]')
    lines.append('\tvar active_bonuses = {}')
    lines.append('\tif piece_count >= 2:')
    lines.append('\t\tfor k in s["bonus_2"].keys(): active_bonuses[k] = active_bonuses.get(k, 0.0) + s["bonus_2"][k]')
    lines.append('\tif piece_count >= 4:')
    lines.append('\t\tfor k in s["bonus_4"].keys(): active_bonuses[k] = active_bonuses.get(k, 0.0) + s["bonus_4"][k]')
    lines.append('\tif piece_count >= 6:')
    lines.append('\t\tfor k in s["bonus_6"].keys(): active_bonuses[k] = active_bonuses.get(k, 0.0) + s["bonus_6"][k]')
    lines.append('\treturn active_bonuses')
    lines.append('')
    lines.append('static func get_set_definition(set_name: String) -> Dictionary:')
    lines.append('\tvar sets = get_all_sets()')
    lines.append('\treturn sets.get(set_name, {})')
    lines.append('')

    lines.append('static func get_slot_key_for_type(type: int) -> String:')
    lines.append('\tmatch type:')
    lines.append('\t\tItemType.ARMOR_HEAD: return "head"')
    lines.append('\t\tItemType.ARMOR_SHOULDER: return "shoulders"')
    lines.append('\t\tItemType.ARMOR_CHEST: return "chest"')
    lines.append('\t\tItemType.ARMOR_GLOVES: return "gloves"')
    lines.append('\t\tItemType.ARMOR_PANTS: return "pants"')
    lines.append('\t\tItemType.ARMOR_BOOTS: return "boots"')
    lines.append('\t\tItemType.CAPE: return "cape"')
    lines.append('\t\tItemType.WINGS: return "wings"')
    lines.append('\t\tItemType.WEAPON: return "weapon_main"')
    lines.append('\t\tItemType.WEAPON_OFFHAND: return "weapon_off"')
    lines.append('\t\tItemType.RING: return "ring_1"')
    lines.append('\t\tItemType.AMULET: return "amulet"')
    lines.append('\t\tItemType.MOUNT: return "mount"')
    lines.append('\t\tItemType.PET: return "pet"')
    lines.append('\treturn ""')
    lines.append('')
    lines.append('static func get_slot_name_for_type(type: int) -> String:')
    lines.append('\treturn get_slot_key_for_type(type)')

    content = "\n".join(lines)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"✅ ItemsDatabase gerado com sucesso em {OUTPUT_PATH}")

if __name__ == "__main__":
    generate()
