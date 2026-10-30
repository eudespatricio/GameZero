import sqlite3
import os
import hashlib
import secrets
import json
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(__file__), "gamezero.db")

def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_connection()
    c = conn.cursor()
    c.execute("""
    CREATE TABLE IF NOT EXISTS accounts (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        role TEXT DEFAULT 'player',
        created_at TEXT NOT NULL,
        last_login TEXT
    )
    """)
    c.execute("""
    CREATE TABLE IF NOT EXISTS sessions (
        token TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts(id)
    )
    """)
    c.execute("""
    CREATE TABLE IF NOT EXISTS characters (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        slot_index INTEGER NOT NULL,
        name TEXT NOT NULL,
        class_id TEXT NOT NULL,
        level INTEGER DEFAULT 1,
        current_xp INTEGER DEFAULT 0,
        gold INTEGER DEFAULT 500,
        stat_points INTEGER DEFAULT 0,
        strength INTEGER DEFAULT 20,
        dexterity INTEGER DEFAULT 20,
        vitality INTEGER DEFAULT 20,
        willpower INTEGER DEFAULT 20,
        wings_tier INTEGER DEFAULT 0,
        weapon_refine INTEGER DEFAULT 0,
        armor_refine INTEGER DEFAULT 0,
        ritual_awakened INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        last_played TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts(id),
        UNIQUE(account_id, slot_index)
    )
    """)
    c.execute("""
    CREATE TABLE IF NOT EXISTS character_data (
        character_id TEXT PRIMARY KEY,
        equipped_gear_json TEXT NOT NULL,
        bag_json TEXT NOT NULL,
        quests_json TEXT NOT NULL,
        FOREIGN KEY (character_id) REFERENCES characters(id)
    )
    """)
    conn.commit()
    conn.close()

def hash_password(password: str, salt: str = None):
    if not salt:
        salt = secrets.token_hex(16)
    hashed = hashlib.sha256((salt + password).encode("utf-8")).hexdigest()
    return hashed, salt

def register_account(username, password):
    username = username.strip().lower()
    if len(username) < 3 or len(password) < 4:
        return False, "Usuário deve ter ao menos 3 caracteres e senha ao menos 4."
    
    conn = get_connection()
    c = conn.cursor()
    c.execute("SELECT id FROM accounts WHERE username = ?", (username,))
    if c.fetchone():
        conn.close()
        return False, "Nome de usuário já está em uso."
    
    account_id = "acc_" + secrets.token_hex(8)
    pwd_hash, salt = hash_password(password)
    now = datetime.utcnow().isoformat()
    
    c.execute("""
    INSERT INTO accounts (id, username, password_hash, salt, created_at, last_login)
    VALUES (?, ?, ?, ?, ?, ?)
    """, (account_id, username, pwd_hash, salt, now, now))
    conn.commit()
    conn.close()
    return True, {"id": account_id, "username": username}

def login_account(username, password):
    username = username.strip().lower()
    conn = get_connection()
    c = conn.cursor()
    c.execute("SELECT * FROM accounts WHERE username = ?", (username,))
    row = c.fetchone()
    if not row:
        conn.close()
        return False, "Usuário ou senha incorretos."
    
    pwd_hash, _ = hash_password(password, row["salt"])
    if pwd_hash != row["password_hash"]:
        conn.close()
        return False, "Usuário ou senha incorretos."
    
    now = datetime.utcnow().isoformat()
    token = "gz_tok_" + secrets.token_hex(24)
    # Sessão válida por 30 dias
    c.execute("""
    INSERT INTO sessions (token, account_id, created_at, expires_at)
    VALUES (?, ?, ?, ?)
    """, (token, row["id"], now, "2099-12-31T23:59:59"))
    c.execute("UPDATE accounts SET last_login = ? WHERE id = ?", (now, row["id"]))
    conn.commit()
    conn.close()
    return True, {"token": token, "account_id": row["id"], "username": row["username"]}

def get_account_from_token(token):
    if not token:
        return None
    conn = get_connection()
    c = conn.cursor()
    c.execute("""
    SELECT a.id, a.username, a.role FROM sessions s
    JOIN accounts a ON s.account_id = a.id
    WHERE s.token = ?
    """, (token,))
    row = c.fetchone()
    conn.close()
    if row:
        return dict(row)
    return None

def get_characters(account_id):
    conn = get_connection()
    c = conn.cursor()
    c.execute("SELECT * FROM characters WHERE account_id = ? ORDER BY slot_index ASC", (account_id,))
    rows = c.fetchall()
    conn.close()
    return [dict(r) for r in rows]

def create_character(account_id, name, class_id):
    name = name.strip()
    class_id = class_id.strip().lower()
    if len(name) < 2 or len(name) > 16:
        return False, "Nome do personagem deve ter entre 2 e 16 caracteres."
    if class_id not in ["zero", "arya", "roran"]:
        return False, "Classe inválida. Escolha entre Zero, Arya ou Roran."
    
    conn = get_connection()
    c = conn.cursor()
    # Checar slots ocupados (máx 4)
    c.execute("SELECT slot_index FROM characters WHERE account_id = ?", (account_id,))
    occupied = [r["slot_index"] for r in c.fetchall()]
    if len(occupied) >= 4:
        conn.close()
        return False, "Limite máximo de 4 personagens atingido para esta conta."
    
    free_slot = 0
    for s in range(4):
        if s not in occupied:
            free_slot = s
            break
            
    # Checar se nome já existe globalmente
    c.execute("SELECT id FROM characters WHERE LOWER(name) = ?", (name.lower(),))
    if c.fetchone():
        conn.close()
        return False, "Já existe um personagem com este nome."
        
    char_id = "char_" + secrets.token_hex(8)
    now = datetime.utcnow().isoformat()
    
    # Atributos iniciais conforme a classe (armas iniciais registradas no ItemsDatabase)
    stats_map = {
        "zero":  {"hp": 2450, "mp": 1180, "str": 28, "dex": 22, "vit": 25, "wil": 24, "wep": "sword_recruta"},
        "arya":  {"hp": 1850, "mp": 1950, "str": 16, "dex": 38, "vit": 18, "wil": 36, "wep": "blade_rastreador"},
        "roran": {"hp": 3400, "mp": 450,  "str": 42, "dex": 14, "vit": 44, "wil": 12, "wep": "hammer_aprendiz"}
    }
    s = stats_map[class_id]
    
    c.execute("""
    INSERT INTO characters (
        id, account_id, slot_index, name, class_id, level, current_xp, gold,
        stat_points, strength, dexterity, vitality, willpower, wings_tier,
        weapon_refine, armor_refine, ritual_awakened, created_at, last_played
    ) VALUES (?, ?, ?, ?, ?, 1, 0, 500, 0, ?, ?, ?, ?, 0, 0, 0, 0, ?, ?)
    """, (char_id, account_id, free_slot, name, class_id, s["str"], s["dex"], s["vit"], s["wil"], now, now))
    
    # Equipamentos e mochila iniciais
    initial_gear = {
        "head": "",
        "shoulders": "",
        "chest": "",
        "gloves": "",
        "pants": "",
        "boots": "",
        "cape": "",
        "wings": "",
        "weapon_main": s["wep"],
        "weapon_off": "",
        "ring_1": "",
        "ring_2": "",
        "amulet": "",
        "mount": "",
        "pet": ""
    }
    
    # 33 slots de mochila vazios
    initial_bag = [{} for _ in range(33)]
    initial_bag[0] = {"id": "potion_health", "count": 5}
    initial_bag[1] = {"id": "potion_mana", "count": 3}
    
    initial_quests = {
        "hunt_1": {"title": "Caçada ao Chifre", "progress": 0, "goal": 5, "done": False, "claimed": False, "status": "in_progress"}
    }
    
    c.execute("""
    INSERT INTO character_data (character_id, equipped_gear_json, bag_json, quests_json)
    VALUES (?, ?, ?, ?)
    """, (char_id, json.dumps(initial_gear), json.dumps(initial_bag), json.dumps(initial_quests)))
    
    conn.commit()
    conn.close()
    return True, {"id": char_id, "name": name, "class_id": class_id, "slot_index": free_slot, "level": 1}

def delete_character(account_id, character_id):
    conn = get_connection()
    c = conn.cursor()
    c.execute("SELECT id FROM characters WHERE id = ? AND account_id = ?", (character_id, account_id))
    if not c.fetchone():
        conn.close()
        return False, "Personagem não encontrado ou não pertence a esta conta."
    
    c.execute("DELETE FROM character_data WHERE character_id = ?", (character_id,))
    c.execute("DELETE FROM characters WHERE id = ?", (character_id,))
    conn.commit()
    conn.close()
    return True, "Personagem excluído com sucesso."

def get_character_full(character_id):
    conn = get_connection()
    c = conn.cursor()
    c.execute("SELECT * FROM characters WHERE id = ?", (character_id,))
    char_row = c.fetchone()
    if not char_row:
        conn.close()
        return None
        
    c.execute("SELECT * FROM character_data WHERE character_id = ?", (character_id,))
    data_row = c.fetchone()
    conn.close()
    
    char_dict = dict(char_row)
    if data_row:
        char_dict["equipped_gear"] = json.loads(data_row["equipped_gear_json"])
        char_dict["bag"] = json.loads(data_row["bag_json"])
        char_dict["quests"] = json.loads(data_row["quests_json"])
    else:
        char_dict["equipped_gear"] = {}
        char_dict["bag"] = [{} for _ in range(33)]
        char_dict["quests"] = {}
        
    return char_dict

def save_character_full(account_id, character_id, payload):
    conn = get_connection()
    c = conn.cursor()
    c.execute("SELECT id FROM characters WHERE id = ? AND account_id = ?", (character_id, account_id))
    if not c.fetchone():
        conn.close()
        return False, "Personagem não pertence a esta conta."
        
    now = datetime.utcnow().isoformat()
    c.execute("""
    UPDATE characters SET
        level = ?, current_xp = ?, gold = ?, stat_points = ?,
        strength = ?, dexterity = ?, vitality = ?, willpower = ?,
        wings_tier = ?, weapon_refine = ?, armor_refine = ?,
        ritual_awakened = ?, last_played = ?
    WHERE id = ?
    """, (
        payload.get("level", 1), payload.get("current_xp", 0), payload.get("gold", 0),
        payload.get("stat_points", 0), payload.get("strength", 20), payload.get("dexterity", 20),
        payload.get("vitality", 20), payload.get("willpower", 20), payload.get("wings_tier", 0),
        payload.get("weapon_refine", 0), payload.get("armor_refine", 0),
        payload.get("ritual_awakened", 0), now, character_id
    ))
    
    if "equipped_gear" in payload or "bag" in payload or "quests" in payload:
        gear_json = json.dumps(payload.get("equipped_gear", {}))
        bag_json = json.dumps(payload.get("bag", []))
        quests_json = json.dumps(payload.get("quests", {}))
        c.execute("""
        INSERT INTO character_data (character_id, equipped_gear_json, bag_json, quests_json)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(character_id) DO UPDATE SET
            equipped_gear_json = excluded.equipped_gear_json,
            bag_json = excluded.bag_json,
            quests_json = excluded.quests_json
        """, (character_id, gear_json, bag_json, quests_json))
        
    conn.commit()
    conn.close()
    return True, "Progresso sincronizado com sucesso."
