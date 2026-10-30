# GameZero

ARPG isométrico em **Godot 4** ambientado em Alagaësia (Ciclo da Herança): três classes,
mapa procedural de 600 × 600 m, loot com affixes, 21 conjuntos de armadura, forja estilo
MU Online, montaria de dragão e HUD com barra de chefe.

> Documentação técnica completa: [DOCUMENTACAO_GERAL_GAMEZERO.md](DOCUMENTACAO_GERAL_GAMEZERO.md)

---

## Requisitos

| Ferramenta | Versão | Observação |
|---|---|---|
| Godot | 4.3+ | `Forward+` (Vulkan). O binário precisa estar no `PATH`. |
| Python | 3.11+ | Só para as ferramentas de áudio/imagem em `tools/`. |
| ffmpeg | 5+ | Síntese e masterização de SFX. |
| Pillow + fontTools | — | `pip install pillow fonttools` (venv de áudio). |

## Como rodar

```bash
godot --path .                      # abre o jogo (ou o editor com -e)
./run_game.sh                       # WSL/Linux, força Vulkan
tools/dev/run_tests.sh              # suíte de testes headless
tools/dev/run_tests.sh stats        # filtra por nome
```

A cena inicial é `scenes/ui/auth_and_character_select.tscn` (login/registro + 4 slots).
O servidor REST é opcional: sem ele o jogo entra em modo híbrido com saves locais em
`user://saves/`.

## Controles

| Ação | Tecla |
|---|---|
| Mover | `WASD` / setas (ou clique no chão) |
| Atacar (combo de 3) | `F` ou clique direito |
| Magias 1–3 | `1` `2` `3` |
| Poção de vida / mana | `Q` / `R` |
| Dash | `Shift` |
| Montar / desmontar | `Z` |
| Mochila | `I` |
| Mapa-múndi | `M` |
| Tela cheia | `F11` |

As ações vivem em `scripts/systems/game_input.gd` (InputMap registrado em runtime):
mudar uma tecla ali vale para o jogo inteiro.

## Arquitetura

```
scenes/            cenas (.tscn) — player, mapa, HUD, modais
scripts/
  systems/         stats, save, loot, áudio, VFX, input, versão
  data/            catálogos (itens, classes, mobs, forjas, zonas, dragões)
  ui/              HUD, inventário, mapa, forja, tema global (ui_style.gd)
  environment/     map_builder (mundo procedural), câmera, props
  ai/              FSM dos inimigos + tiers de dificuldade
  tests/           testes headless (SceneTree)
assets/
  fonts/           Montserrat + Noto Emoji (OFL — ver license.txt ao lado)
  ui/ui_theme.tres tema global gerado por tools/dev/build_ui_theme.gd
  shaders/         terreno, água, folhagem, pós-processamento
tools/
  audio/           síntese, masterização e variações de SFX
  studio/          geração de modelos/props e capturas de tela
  dev/             runner de testes e utilitários de build
```

### Convenções importantes

- **Stats → combate**: o dano sai de `CharacterStats.get_attack_damage()`, que normaliza o
  poder de ataque pela curva de HP dos mobs. Nunca use dano fixo em scripts de gameplay.
- **Persistência**: `SaveManager.save_local()` grava em `.tmp` + `.bak` (atômico) e carrega
  o backup se o JSON principal estiver corrompido. `mark_dirty()` agrupa gravações.
- **Rede**: todas as chamadas passam pela fila serial de `NetworkManager` (um `HTTPRequest`
  por requisição). Não crie `HTTPRequest` solto.
- **Tema**: qualquer cor/fonte nova deve entrar em `scripts/ui/ui_style.gd` e o `.tres`
  precisa ser regerado com `tools/dev/build_ui_theme.gd`.

## Pipeline de áudio

```bash
python tools/audio/analyze_sfx.py          # relatório de loudness/picos
python tools/audio/make_variants.py        # cria variações dos sons repetidos
python tools/audio/master_sfx.py           # mixagem por categoria (RMS + pico)
python tools/audio/master_sfx.py --restore # volta aos originais
```

O alvo é definido por categoria (combate −16 dB RMS, vozes −15, UI −24, passos −26),
sempre respeitando o teto de pico de −1,5 dBTP.

## Testes

`tools/dev/run_tests.sh` roda 11 suítes headless (stats, sets, save, UI, mapa, mobs,
shaders, integração). O script retorna código de saída ≠ 0 quando algo falha — pronto
para CI.

## Licenças

- Fontes: **Montserrat** e **Noto Emoji**, ambas SIL Open Font License 1.1
  (`assets/fonts/OFL-*.txt`).
- Áudio e modelos 3D gerados proceduralmente por scripts em `tools/`.
- Código do jogo: **MIT** — veja [LICENSE](LICENSE).
