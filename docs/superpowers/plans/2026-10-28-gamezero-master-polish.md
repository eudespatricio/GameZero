# GameZero Master Polish & Subsystems Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar o sistema completo de cooldowns com mini-cronômetros visuais no HUD, plasticidade procedural anatômica (pernas, braços e asas para o herói e montaria Saphira), banco de áudio intimidador para chefes, falas/barks de NPCs e jogador, auditoria estrita de integridade de dados sem fallbacks erráticos, e documentação técnica geral em Markdown.

**Architecture:**
- HUD & Combat: Mapeamento de cooldowns no `Player` com sinalização e overlay dinâmico no `GameHUD` exibindo contagem regressiva e bloqueio de input.
- Procedural Animation: Acesso aos sub-nós anatômicos dos modelos GLB (`character_zero.glb`, `crystal_wings_detailed.glb`, `dragon_mount_saphira.glb`) para cinemática direta com ondas senoidais acopladas à velocidade, física e estados de ação.
- Áudio & Barks: Síntese de áudio procedural via script Python local em WSL (`tools/audio/generate_sfx.py`) com processamento de sinal DSP (numpy/scipy) e exportação em OGG Vorbis, integrando-se nativamente ao `AudioManager`.
- Documentação: Criação de `DOCUMENTACAO_GERAL_GAMEZERO.md` contendo todo o ecossistema do projeto.

**Tech Stack:** Godot 4.3 LTS (GDScript, CharacterBody3D, CanvasLayer, AudioStreamPlayer3D), Python 3 + SciPy/NumPy (WSL2), Blender 4.2 LTS GLTF/GLB.

---

## Tasks

- [x] **Task 1: Auditoria dos Bancos de Dados e Prevenção de Falhas/Fallbacks Erráticos**
  - Verificar `items_database.gd`, `mobs_database.gd`, `forge_recipes.gd`, `dragons_database.gd`, `classes_data.gd`.
  - Garantir consistência nas chamadas de chaves (`get()`, validação de tipos, arrays não nulos).
  - Executar testes automatizados headless para confirmar integridade.

- [x] **Task 2: Sistema de Cooldowns de Habilidades e Mini-Cronômetro no HUD**
  - Adicionar dicionário e controle de tempo de recarga no `player.gd`:
    - Skill 1 (Brisingr): 2.5s
    - Skill 2 (Jierda): 5.0s
    - Skill 3 (Vórtice de Sylveria): 10.0s
    - Dash: 0.85s
    - Poções: 1.0s
  - Bloquear acionamento via teclado (1, 2, 3, Shift, Q, R) e cliques do mouse enquanto em recarga.
  - Modificar `scenes/ui/hud.tscn` e `scripts/ui/hud.gd` com overlays visuais escuros e etiquetas de contagem numérica regressiva (`Label` de CD centralizada) sobre cada botão de habilidade.
  - Emitir feedback visual e sonoro sutil quando a habilidade estiver pronta novamente.

- [x] **Task 3: Cinemática e Plasticidade Procedural de Membros (Pernas e Braços)**
  - Localizar referências dos membros no `player.gd`:
    - Pernas: `Thigh_-1`, `Thigh_1`, `Greave_-1`, `Greave_1`, `Sabaton_-1`, `Sabaton_1`.
    - Braços: `LeftUpperArm`, `RightUpperArm`, `LeftForearm`, `RightForearm`.
  - Implementar rotação harmônica alternada durante locomoção (caminhada e corrida).
  - Adicionar balanço de braços dinâmico em oposição às pernas e animação de relaxamento/respiração em repouso.
  - Articular o golpe de ataque melee com antecipação e recuperação fluida.

- [x] **Task 4: Plasticidade e Animação de Bater de Asas (Herói e Dragão Saphira)**
  - Integrar oscilação angular de asas de cristal no `player.gd` para as lâminas/arcos do modelo `crystal_wings_detailed.glb`.
  - No `scripts/mounts/dragon_mount.gd`, referenciar os nós `SaphiraWing_-1` e `SaphiraWing_1` e aplicar batimento majestoso de asas proporcional à velocidade horizontal e sustentação de voo.

- [x] **Task 5: Sons Intimidadores para Bosses e Minibosses**
  - Atualizar `tools/audio/generate_sfx.py` adicionando sintetizadores DSP com baixas frequências, distorção harmônica e ressonância para:
    - `boss_roar_intimidating.ogg`: Rugido sísmico profundo.
    - `boss_slam_heavy.ogg`: Tremor e impacto de solo massivo.
    - `miniboss_growl.ogg`: Rosnado gutural visceral.
  - Executar o script no WSL via `~/.venvs/gamezero-audio/bin/python`.
  - Mapear os novos sons no `scripts/systems/audio_manager.gd` e acioná-los em `scripts/ai/enemy_ai.gd`.

- [x] **Task 6: Sistema de Falas e Barks de NPCs e do Personagem**
  - Sintetizar efeitos de barks / vocalizações sutis para os NPCs e herói via DSP.
  - Em `scripts/npcs/npc_base.gd`, tocar sons de voz ao interagir com Horst, Angela e Brom, além de balões/barks contextuais.
  - No `player.gd`, disparar reações sonoras do herói (exerção no golpe, aviso de mana zerada, reação a dano pesado).

- [x] **Task 7: Validação e Testes Automatizados Headless no WSL**
  - Rodar `run_paperdoll_tests.gd` e `run_gameplay_tests.gd`.
  - Confirmar ausência de exceções no Godot 4.3 LTS.

- [x] **Task 8: Documentação Geral do Projeto (.md)**
  - Redigir `DOCUMENTACAO_GERAL_GAMEZERO.md` com arquitetura completa, controles, sistemas de itens, forja, combate, áudio procedural, mapa-mundi e guia do desenvolvedor.
