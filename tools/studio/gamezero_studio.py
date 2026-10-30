#!/usr/bin/env python3
"""
===================================================================
🎮 GAMEZERO STUDIO - MÁQUINA DE PRODUÇÃO INDUSTRIAL NO WSL2
===================================================================
Orquestrador autônomo de desenvolvimento de jogos integrando:
- Blender 4.2 LTS (Geração e Exportação de Modelos PBR)
- Godot 4.3 Stable (Validação Headless, Testes e Shaders)
- Ollama Local / RTX 3060 (Geração de Quests, Itens e Lore)
- Pipeline de Áudio, VFX e Cartografia
===================================================================
"""

import os
import sys
import subprocess
import argparse
import time

STUDIO_ROOT = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(STUDIO_ROOT))
BLENDER_BIN = "blender"
GODOT_BIN = "godot"

def log(msg, tag="STUDIO"):
    colors = {
        "STUDIO": "\033[1;36m",
        "SUCCESS": "\033[1;32m",
        "WARN": "\033[1;33m",
        "ERROR": "\033[1;31m",
        "RESET": "\033[0m"
    }
    c = colors.get(tag, "\033[1;37m")
    r = colors["RESET"]
    print(f"{c}[{tag}] {msg}{r}")

def run_command(cmd, desc=""):
    if desc:
        log(desc, "STUDIO")
    t0 = time.time()
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    elapsed = time.time() - t0
    if res.returncode == 0:
        log(f"Concluído em {elapsed:.2f}s ✅", "SUCCESS")
        return True, res.stdout
    else:
        log(f"Falha após {elapsed:.2f}s: {res.stderr.strip()} ❌", "ERROR")
        return False, res.stderr

def build_3d_assets():
    log("Iniciando Forja 3D com Blender 4.2...", "STUDIO")
    scripts = [
        os.path.join(PROJECT_ROOT, "scripts/tools/generate_all_models.py"),
        os.path.join(PROJECT_ROOT, "scripts/tools/generate_characters_models.py"),
        os.path.join(PROJECT_ROOT, "scripts/tools/generate_gear_and_pet_models.py"),
        os.path.join(STUDIO_ROOT, "generate_environmental_props.py"),
        os.path.join(STUDIO_ROOT, "generate_npcs_and_plaza.py"),
        os.path.join(STUDIO_ROOT, "generate_dragon_mount.py"),
        os.path.join(STUDIO_ROOT, "generate_flora_props.py")
    ]
    all_ok = True
    for s in scripts:
        if os.path.exists(s):
            ok, out = run_command(f"{BLENDER_BIN} -b -P {s}", f"Executando {os.path.basename(s)}")
            if not ok: all_ok = False
    
    # Reimport no Godot
    run_command(f"{GODOT_BIN} --headless --path {PROJECT_ROOT} --editor --quit-after 10", "Reimportando GLBs no Godot")
    return all_ok

def build_cartography():
    log("Renderizando Mapa Cartográfico de Alagaësia...", "STUDIO")
    script = os.path.join(PROJECT_ROOT, "scripts/tools/generate_alagaesia_map.py")
    if os.path.exists(script):
        ok, _ = run_command(f"{BLENDER_BIN} -b -P {script}", "Renderizando alagaesia_cartography.png")
        if ok:
            run_command(f"{GODOT_BIN} --headless --path {PROJECT_ROOT} --editor --quit-after 10", "Importando Mapa no Godot")
            return True
    return False

def run_qa_suite():
    log("Executando Bateria de Testes Automatizados Headless...", "STUDIO")
    test_script = os.path.join(PROJECT_ROOT, "scripts/tests/run_paperdoll_tests.gd")
    ok, out = run_command(f"{GODOT_BIN} --headless --path {PROJECT_ROOT} -s {test_script}", "Rodando Unit Tests Paperdoll & Cenas")
    print(out)
    return ok

def status_audit():
    log("==================================================", "STUDIO")
    log("📊 AUDITORIA DO PROJETO GAMEZERO (WSL PIPELINE)", "STUDIO")
    log("==================================================", "STUDIO")

    models_dir = os.path.join(PROJECT_ROOT, "assets/models")
    glbs = [f for f in os.listdir(models_dir) if f.endswith(".glb")] if os.path.exists(models_dir) else []
    log(f"Modelos 3D PBR Ativos: {len(glbs)} modelos ({', '.join(glbs[:5])}...)", "SUCCESS")

    ui_dir = os.path.join(PROJECT_ROOT, "assets/ui")
    ui_assets = os.listdir(ui_dir) if os.path.exists(ui_dir) else []
    log(f"Assets de UI & Cartografia: {len(ui_assets)} arquivos ({', '.join(ui_assets)})", "SUCCESS")

    scenes_dir = os.path.join(PROJECT_ROOT, "scenes")
    tscn_count = 0
    for root, _, files in os.walk(scenes_dir):
        for f in files:
            if f.endswith(".tscn"): tscn_count += 1
    log(f"Cenas Godot Registradas: {tscn_count} cenas (.tscn)", "SUCCESS")

    scripts_dir = os.path.join(PROJECT_ROOT, "scripts")
    gd_count = 0
    for root, _, files in os.walk(scripts_dir):
        for f in files:
            if f.endswith(".gd"): gd_count += 1
    log(f"Scripts GDScript: {gd_count} módulos de lógica e sistemas", "SUCCESS")
    log("==================================================", "STUDIO")

def main():
    parser = argparse.ArgumentParser(description="GameZero Production Studio CLI")
    parser.add_argument("--pipeline", choices=["all", "3d", "map", "qa", "status"], default="status",
                        help="Executa uma pipeline da fábrica de jogos")
    args = parser.parse_args()

    if args.pipeline == "status":
        status_audit()
    elif args.pipeline == "3d":
        build_3d_assets()
    elif args.pipeline == "map":
        build_cartography()
    elif args.pipeline == "qa":
        run_qa_suite()
    elif args.pipeline == "all":
        build_3d_assets()
        build_cartography()
        run_qa_suite()
        status_audit()

if __name__ == "__main__":
    main()
