# 🐉 GAMEZERO — DOCUMENTAÇÃO TÉCNICA E MANUAL DE ENGENHARIA DO PROJETO

**Versão:** 1.5.0 (Master Polish & Subsystems Edition)  
**Motor Gráfico:** Godot Engine 4.3 LTS  
**Plataforma de Desenvolvimento:** Linux WSL2 (Ubuntu / Hardware RTX 3060)  
**Estilo & Gênero:** ARPG Isométrico 3D (Fusão estilística *Diablo IV* + *Mu Online* + Universo de *Alagaësia / Eragon*)

---

## 1. Visão Geral e Pilares de Design

O **GameZero** é um ARPG isométrico de alta fidelidade desenvolvido sobre a arquitetura do **Godot 4.3**. O projeto combina a plasticidade de combate ágil e atmosfera sombria de *Diablo*, o prestígio de progressão visual (equipamentos reluzentes, refinos de +0 a +15, asas de arcanjo/cristal e joias místicas) de *Mu Online*, com o lore épico de Cavaleiros de Dragão inspirado no ciclo da herança (*Eragon* / *Alagaësia*).

### Principais Pilares
1. **Locomoção Orgânica e Cinemática Procedural:** Movimentação sem animações enlatadas rígidas; pernas, braços, asas, capa e corpo reagem à velocidade, curvas (banking/lean), aceleração e impacto de solo.
2. **Combate Reativo e Tático:** Golpes melee em cadeia com arcos de lâmina luminosos, magias em cone e radial, câmera com hit-stop e screen shake proporcional, e sistema estrito de cooldowns com bloqueio de input e contagem regressiva visual sobre os botões.
3. **Áudio Procedural em Tempo Real (DSP SciPy/NumPy):** 100% dos efeitos sonoros, vozes de barks, passos por superfície e ambiências foram sintetizados via matemática DSP local no WSL, garantindo determinismo, riqueza espectral e ausência de dependências de bibliotecas de terceiros.
4. **Economia & Refino Profundo:** Mochila real de 33 slots com arrastar/mover, Joias da Bênção, Alma e Caos, máquina de combinações do ferreiro e cálculo dinâmico de Poder de Combate (CP).

---

## 2. Arquitetura de Pastas e Componentes

```
GameZero/
├── assets/
│   ├── audio/           # Bancos de áudio Vorbis OGG (SFX, Ambient, Music)
│   ├── models/          # Modelos GLB esculpidos (Zero, Saphira, Inimigos, Cenário)
│   ├── shaders/         # Shaders PBR (Asas, Vórtice, Água, Estrada de Pedra)
│   └── ui/              # Cartografia e recursos gráficos do HUD
├── docs/
│   └── superpowers/     # Planos de implementação e especificações
├── scenes/
│   ├── enemies/         # Cena enemy_mob.tscn
│   ├── maps/            # Cena elven_forest_mockup.tscn (Mapa jogável)
│   ├── mounts/          # Cena dragon_mount.tscn
│   ├── npcs/            # Cena npc_base.tscn
│   ├── player/          # Cena player.tscn
│   └── ui/              # Cenas hud.tscn, inventory_window.tscn, forge_window.tscn, world_map.tscn
├── scripts/
│   ├── ai/              # enemy_ai.gd (Máquina de estados, detecção, safe zone)
│   ├── data/            # items_database.gd, mobs_database.gd, forge_recipes.gd
│   ├── environment/     # map_builder.gd, isometric_camera.gd
│   ├── mounts/          # dragon_mount.gd (Voo, sela, bater de asas da Saphira)
│   ├── npcs/            # npc_base.gd (Diálogos, serviços, missões)
│   ├── player/          # player.gd (Física, membros, cooldowns, skills, input)
│   ├── systems/         # character_stats.gd, audio_manager.gd, combat_vfx.gd, loot_system.gd
│   ├── tests/           # Suíte de testes headless automatizados
│   └── ui/              # hud.gd, blacksmith_forge_window.gd, inventory_window.gd
└── tools/
    ├── audio/           # generate_sfx.py (Sintetizador DSP com NumPy/SciPy)
    └── studio/          # Geradores de modelos Blender e renderizadores
```

---

## 3. Locomoção e Cinemática Procedural Anatômica

### 3.1 Articulação dos Membros do Cavaleiro (`player.gd`)
Ao contrário de modelos estáticos com mero deslocamento vertical, o herói possui controle dinâmico dos sub-nós do modelo `character_zero.glb`:
- **Pernas (`Thigh_-1`, `Greave_-1`, `Thigh_1`, `Greave_1`):** Rotação angular em contrafase acoplada à frequência dos passos (`step_cycle`). Durante a passada, a coxa avança e a canela dobra o joelho para trás de forma proporcional à velocidade de caminhada ou corrida (`is_sprinting`).
- **Braços (`LeftUpperArm`, `RightUpperArm`):** O braço esquerdo (escudo) contra-balança o movimento das pernas com amortecimento tático. O braço direito (espada Brisingr) oscila em postura de guarda e reage de forma imediata na antecipação e finalização de golpes.
- **Capa Dorsal (`Cape`):** Oscila com o vento com base no vetor de velocidade planar e na física de descida/salto.
- **Respiração em Repouso (`Idle Breathing`):** Em velocidades inferiores a 0.4 m/s, o herói executa ciclo de respiração sutil que relaxa os membros e expande o tórax ritmicamente.

### 3.2 Bater de Asas de Cristal e Voo da Montaria Saphira
- **Asas de Cristal (`crystal_wings_detailed.glb`):** Quando desmotado, o conjunto dorsal pulsa com ondas senoidais, abrindo e fechando com maior amplitude durante a corrida ou o salto.
- **Saphira (`dragon_mount_saphira.glb`):**
  - Nós `SaphiraWing_-1` e `SaphiraWing_1` articulam batidas de asas em leque vertical e torção frontal com amplitude de até `0.70 rad` em alta velocidade.
  - A cauda (`TailFin`) oscila lateralmente para estabilização de voo.
  - A mandíbula inferior (`LowerJaw`) abre levemente ao emitir o rugido ou cuspir fogo.
  - A sela atrela o cavaleiro milimetricamente com inclinação de rédeas à frente.

---

## 4. Sistema de Combate, Habilidades e Mini-Cronômetro HUD

### 4.1 Habilidades e Tempos de Recarga
As habilidades do jogador consomem Mana e impõem tempos de recarga estritos:
| Habilidade | Tecla | Custo de MP | Cooldown | Efeito / Alcance |
|---|---|---|---|---|
| **Combo de Lâmina** | `F` / `Botão Direito` | 0 MP | 0.22s | Combo melee de 3 tempos com arco de choque e finalizador pesado |
| **[1] Brisingr** | `1` | 35 MP | **2.5s** | Labareda de fogo azul místico em cone frontal de 8.5m com dano massivo |
| **[2] Jierda** | `2` | 50 MP | **5.0s** | Impacto sísmico que rompe o solo em 360° (8.5m) arremessando inimigos |
| **[3] Vórtice de Sylveria**| `3` | 75 MP | **9.0s** | Vórtice gravitacional que suga criaturas próximas ao centro com dano contínuo |
| **Esquiva Rápida (Dash)** | `Shift` | 0 MP | **0.85s** | Propulsão fantasma com rastro de poeira e invulnerabilidade momentânea |
| **Poção de Vida** | `Q` | 0 MP | **1.2s** | Restaura vida com base no item do inventário |
| **Poção de Mana** | `R` | 0 MP | **1.2s** | Restaura mana com base no item do inventário |

### 4.2 Mini-Cronômetro e Bloqueio de Input no HUD (`hud.gd`)
- Cada botão de habilidade no `BottomBar` possui um overlay estilizado (`Panel` escuro translúcido com borda âmbar).
- **Bloqueio de Clique:** Enquanto em recarga, o overlay intercepta e consome cliques do mouse (`mouse_filter = MOUSE_FILTER_STOP`), e o script do jogador rejeita o comando via teclado emitindo feedback sonoro e flutuante (`Recarga: X.Xs`).
- **Contagem Regressiva Visual:** Um `Label` centralizado com contorno preto exibe o tempo exato com precisão de décimos de segundo (ex.: `2.4s`, `0.8s`).
- **Feedback de Prontidão:** Ao zerar o cronômetro, o overlay se oculta e o botão pisca com um brilho suave de recarga concluída.

---

## 5. Engenharia Sonora e Áudio Procedural DSP

O áudio do projeto é gerado localmente pelo script `tools/audio/generate_sfx.py` usando `scipy.signal` e `numpy`, exportado em **OGG Vorbis a 44.1 kHz**:

### 5.1 Rugidos e Impactos Intimidadores de Chefes
- **`boss_roar_intimidating.ogg` (4.75s):** Rugido sísmico de três camadas:
  1. *Sub-bass sísmico:* Onda senoidal com glide de 68 Hz até 28 Hz com modulação de amplitude de 5 Hz.
  2. *Ressonância de garganta gutural:* Onda dente-de-serra com formantes de besta em 120-600 Hz e 700-1800 Hz.
  3. *Camada áspera de estilhaço:* Ruído branco filtrado com saturação analógica (`softclip`) e reverb cavernoso.
- **`boss_slam_heavy.ogg` (2.49s):** Pancada de solo com queda rápida de 95 Hz para 22 Hz, estalo de rochas estilhaçadas e onda de choque de ruído expansivo.
- **`miniboss_growl.ogg` (2.42s):** Rosnado visceral de predador alfa com modulação agressiva.

### 5.2 Barks Vocais dos Personagens e NPCs
- **Ferreiro Horst (`npc_horst.ogg`):** Grunt grave e rouco de anão/ferreiro de placas de aço ao abrir a forja.
- **Herborista Angela (`npc_angela.ogg`):** Entonação mística e etérea com harmônicos cintilantes e sussurro suave.
- **Brom (`npc_brom.ogg`):** Ressonância profunda de ancião e contador de lendas ao interagir com missões.
- **Guerreiro Zero:** Sons de esforço atlético (`player_exert_1`, `player_exert_2`) nos golpes do combo e grito triunfante de vitória (`player_victory`).

---

## 6. Economia, Mochila e Paperdoll de Equipamentos

### 6.1 Paperdoll de 15 Slots
O jogador gerencia slots anatômicos:
- `weapon_main`, `weapon_offhand` (escudos/orbes)
- `armor_head`, `armor_shoulder`, `armor_chest`, `armor_gloves`, `armor_pants`, `armor_boots`
- `cape`, `wings`, `amulet`, `ring_1`, `ring_2`
- `mount`, `pet`

### 6.2 Mochila Real de 33 Slots
- Sistema completo com suporte a empilhamento de itens idênticos (`jewel_bless`, `potion_health`).
- Troca de itens por arraste e solte (`move_bag_item`), equipar direto da mochila (`equip_from_bag`) e devolução ao desequipar (`unequip_to_bag`).
- Bloqueio estrito de overflow quando a mochila estiver com os 33 slots ocupados.

### 6.3 Joias Lendárias & Refino (+0 a +15)
- **💎 Joia da Bênção (Bless):** Aprimora até +6 com 100% de chance.
- **🔮 Joia da Alma (Soul):** Aprimora de +7 até +9 (50% de chance básica).
- **🔥 Joia do Caos (Chaos):** Combustível da Máquina do Caos e refino de +10 a +15.
- **Evolução Visual de Brilho (+Glow):** A arma do herói projeta iluminação mística (`GedweyLight`) cuja intensidade e tonalidade crescem a cada nível de refino.

---

## 7. Forja de Combinações do Ferreiro (Chaos Machine)

Acessível através do NPC Horst no Santuário de Sylveria:
- **Receitas Registradas:**
  1. *Asas de Cristal Nvl 2:* Penas Sagradas + Joias do Caos + Ouro (75% sucesso).
  2. *Asas Celestiais Nvl 3:* Asas Nvl 2 + Pedra da Criação + Joias da Alma (60% sucesso).
  3. *Lâmina Zar'roc Flamejante:* Aço Brilhante + Joias do Caos (70% sucesso).
  4. *Arco Élfico de Ellesméra:* Madeira Sagrada + Joias da Bênção (80% sucesso).
  5. *Orbe do Caos Concentrado:* Transmutação de 10 fragmentos em 1 Joia do Caos (90% sucesso).
- **Segurança Transacional:** Consome os materiais e o ouro do jogador de forma atômica; em caso de falha, toca áudio e feedback visual de colapso de transmutação sem quebrar o estado do jogo.

---

## 8. Inteligência Artificial e Bestiário (`enemy_ai.gd`)

- **Máquina de Estados:** `IDLE` ➔ `PATROL` ➔ `CHASE` ➔ `ATTACK` ➔ `RETURN` ➔ `DEAD`.
- **Barreira do Santuário de Sylveria (Safe Zone de 24m):** Qualquer monstro que tentar perseguir o jogador para dentro do raio de 24 metros é repelido imediatamente por repulsão física e forçado ao estado de retorno.
- **Ataques Telegrafados de Chefes (`_boss_slam`):** Projeta um anel expansivo no chão indicando a área de impacto sísmico (5 metros). O jogador possui 1.0s para se esquivar com o `Dash` antes da onda de choque detonar.

---

## 9. Sistema de Oclusão e Texturização de Vegetação Élfica (Padrão Diablo IV / PoE)

### 9.1 Oclusão Dinâmica de Visão (See-Through Transparency)
Em ARPGs com câmera isométrica elevada, copas densas e troncos robustos de árvores bloqueiam frequentemente a visão do herói, de mobs e de itens no solo. Para solucionar esse problema com máxima plasticidade, foi implementado um sistema de transparência procedural em tempo real:
1. **Passagem por Baixo da Copa (Proximity Fade):** Quando o herói transita sob a árvore ($dist_{xz} < 6.8\text{ m}$ e $Y_{folhagem} > Y_{herói} + 0.6\text{ m}$), a folhagem sobrejacente fadeia suavemente de forma circular até $\alpha = 0.18$, tornando o herói, a mira e os monstros 100% visíveis.
2. **Desobstrução da Linha de Visão da Câmera (Line-of-Sight Capsule Fade):** Árvores situadas ao sul do herói ou intermediárias entre a câmera e o jogador projetam uma cápsula de corte tridimensional ($raio \le 3.6\text{ m}$) ao longo do segmento $[P_{herói}, P_{câmera}]$, atenuando troncos e copas para $\alpha = 0.20$.
3. **Preservação de Silhueta com Rim Highlight:** Quando o objeto se torna translúcido, um brilho de borda baseado em Fresnel (`pow(1.0 - dot(N, V), 3.0)`) mantém o contorno gracioso da árvore élfica legível sem poluir a visão de combate.
4. **Sincronização em Tempo Real:** As posições de mundo `player_world_pos` e `camera_world_pos` são alimentadas continuamente pelo `isometric_camera.gd` e `player.gd` no `RenderingServer`.

### 9.2 Shaders Procedurais PBR de Alta Fidelidade
- **Folhagem Élfica (`assets/shaders/tree_foliage.gdshader`):**
  - Paleta multi-tom: Esmeralda profundo de sombra (`#0f2e1c`), verde viridiano médio (`#216135`), folhas expostas ao sol (`#479442`) e pontas élficas douradas (`#7ac761`).
  - Ruído procedural em camadas (FBM macro e micro-células de folhas).
  - Translucência / Subsurface Scattering (`BACKLIGHT`) simulando a passagem de raios de sol através das folhas.
  - Balanço orgânico suave com o vento em `vertex()` com amortecimento por altura.
- **Casca de Madeira Ancestral (`assets/shaders/tree_bark.gdshader`):**
  - Paleta de madeira antiga: Sulcos de sombra profunda (`#0d0906`), casca carvalho escuro (`#241710`), cristas elevadas (`#402e1f`) e musgo verdejante ancestral (`#1f4d24`).
  - Fibras verticais alongadas via FBM cilíndrico com derivação de gradiente de normais 3D (`bump_strength`).
  - Crescimento de musgo biológico em superfícies horizontais e superiores (`NORMAL.y > 0.28`).

### 9.3 Otimização Geométrica do Modelo 3D (`elven_tree_detailed.glb`)
- O modelo original continha 16 meshes isoladas (10 cones + 6 esferas), forçando 16 `MultiMeshInstance3D` para cobrir 780 árvores espalhadas pelo `MapBuilder` (12.480 nós instanciados).
- Foi re-esculpido no **Blender 4.2 LTS** em duas meshes unificadas:
  - **`Trunk`**: Tronco afilado com torção espiralada, 6 raízes monumentais contrafortes e 6 galhos arquitetônicos, com Smart UV Project e material `AncientBarkPBR`.
  - **`Canopy`**: 9 cúpulas e boughs de folhagem orgânicos com deformação Voronoi recortada e sombreamento de normais suaves.
- **Resultado:** Redução de 8x nos draw calls do `MultiMeshInstance3D`, mantendo desempenho constante a 60+ FPS.

---

## 10. Suíte de Testes Automatizados Headless

O projeto conta com validação contínua executável via linha de comando no WSL sem necessidade de servidor gráfico X11:

```bash
# 1. Teste de Paperdoll, Itens e Forja
/home/eudespatricio/.gemini/antigravity/bin/godot --headless --path . --script scripts/tests/run_paperdoll_tests.gd

# 2. Teste de Integração (Mapa 600x600m, 446 Mobs, 19 Bosses, Loot e NPCs)
/home/eudespatricio/.gemini/antigravity/bin/godot --headless --path . --script scripts/tests/run_gameplay_tests.gd

# 3. Teste das Funcionalidades de Polish (Cooldowns, Membros, Asas e Barks)
/home/eudespatricio/.gemini/antigravity/bin/godot --headless --path . --script scripts/tests/run_polish_features_test.gd

# 4. Teste de Árvores, Shaders PBR e Desobstrução de Visão
/home/eudespatricio/.gemini/antigravity/bin/godot --headless --path . --script scripts/tests/run_tree_occlusion_test.gd

# 5. Teste de Mobs Diablo IV, Cinemática de Membros e Arenas Temáticas
/home/eudespatricio/.gemini/antigravity/bin/godot --headless --path . --script scripts/tests/run_diablo4_mobs_test.gd
```

Todos os testes rodam com **100% de sucesso e zero falhas de script**.

---

## 11. Sistema de Monstros Padrão Diablo IV, Escultura Lofted BMesh e HUD de Chefes

### 11.1 Escultura em Lofted BMesh Contínuo no Blender 4.2 LTS (Eliminação de Bonecos de Massinha)
Para eliminar definitivamente a aparência de primitivas geométricas empilhadas ("bonecos de massinha"), os 4 arquétipos foram recriados utilizando **Lofted BMesh Contínuo** com anéis anatômicos de perfil tridimensional, subdivisão Catmull-Clark suave (`Subsurf = 2`) e chanfros de aço martelado (`Bevel`):
1. **Urgal Warrior (`urgal_warrior.glb` - 37 nós):**
   - Torso contínuo esculpido com musculatura V-taper, peitorais definidos e abdômen atlético.
   - Chifres de carneiro espiralados envolventes que contornam as têmporas e a nuca em curva ameaçadora (5 segmentos contínuos).
   - Machado de Guerra Brutal: lâmina de corte frontal ampla em crescente chanfrada com espigão reverso de perfuração e decalque de sangue coagulado.
   - Couraça peitoral e cinturão de ferro forjado escuro com ombreiras sobrepostas e espigões.
2. **Spine Wolf (`wolf_spine.glb` - 34 nós):**
   - Corpo lupino contínuo e orgânico (focinho, crânio, pescoço arqueado, peito largo, flancos e quadris).
   - Coluna vertebral armada com 7 cristas ósseas pontiagudas de marfim envelhecido.
   - Mandíbula inferior articulada com presas afiadas expostas e olhos flamejantes.
3. **Root Golem Colossus (`root_golem.glb` - 23 nós):**
   - Tronco colossal contínuo de casca de carvalho ancestral e rochas basálticas.
   - Cavidade peitoral profunda abrigando o Núcleo de Seiva Bioluminescente âmbar (`SapCore`).
   - Ombros maciços de granito e punhos colossais para impactos sísmicos.
4. **Shade Wraith (`shade_wraith.glb` - 28 nós):**
   - Manto espectral fluido contínuo descendo do capuz pontiagudo até faixas esfarrapadas translúcidas.
   - Foices ósseas afiadas acopladas aos antebraços.
   - Anel de 5 estilhaços de obsidiana orbitando continuamente o torso em 3D.

### 11.2 Barra de Chefe Monumental no HUD (Estilo Diablo IV / Dark Souls)
- **Desobstrução do Espaço de Combate 3D:** O texto flutuante quilométrico de 90 caracteres que colidia na cabeça dos chefes foi eliminado.
- **Barra de Vida no HUD Superior:** Quando o jogador entra em combate ou se aproxima de um Miniboss ou World Boss, o HUD superior centraliza uma barra épica:
  - Título monumental em ouro rúnico (`☠ NAR GARZHVOG ☠`).
  - Subtítulo com afixos (`[WORLD BOSS] • Lorde Supremo • Imparável`).
  - Barra de vida de sangue carmesim com percentual e valores numéricos exatos (`15795 / 15795  (100%)`).
  - Animação suave de entrada e saída por aproximação/morte.
- **Minimalismo nos Mobs Comuns:** Nameplates 3D compactos e elegantes com tipografia cirúrgica (`font_size = 15..18`, outline reduzido), sem sobreposições poluentes.

### 11.3 Arenas Temáticas Abertas & Shaders PBR Dark Fantasy
- **Eliminação da Gaiola de Pedras:** O anel mecânico de pedregulhos esféricos que prendia o jogador e bloqueava a câmera foi completamente removido. O combate agora ocorre em terreno amplo e aberto.
- **Piso com Transição Orgânica (Radial Fade):**
  - **Pântano Tóxico (`assets/shaders/toxic_swamp.gdshader`):** A emissão verde limão fluorescente foi removida. O shader agora renderiza água estagnada escura, lodo orgânico fúnebre, alto reflexo especular úmido (`SPECULAR = 0.80`) e desvanecimento radial suave nas bordas (`smoothstep(1.0, 0.65, dist)`), integrando-se perfeitamente à grama.
  - **Caldeira Vulcânica (`assets/shaders/lava_pool.gdshader`):** Basalto queimado poroso com fissuras de magma de brilho incandescente equilibrado (sem cegueira de bloom) e fusão radial com o solo.
  - **Remoção de Aros Neon:** Aros de neon unshaded foram eliminados, substituídos por iluminação omnidirecional atmosférica suave.

### 11.4 Calibração de WorldEnvironment & Pós-Processamento
- **SSAO (Screen Space Ambient Occlusion):** Ativado com raio de 2.0m e intensidade de 2.8 para sombras de contato densas sob pés, patas e pedras.
- **Tonemap Filmic & Bloom Controlado:** Tonemap Filmic com exposição calibrada em 1.10, contraste de 1.12 e HDR Glow Threshold elevado para 1.10, garantindo que luzes mágicas e olhos brilhantes não estourem em manchas brancas.
- **Espaçamento de Chefes:** Distância mínima de segurança de 55 metros aplicada entre chefes e acampamentos, impedindo aglomerações indevidas.

---

## 12. Polimento de Áudio Visceral, Falas Intimidantes, Rio Orgânico e Rigging Anatômico

### 12.1 Rio Meandrado e Água PBR Fluida (`assets/models/elven_river_ribbon.glb`)
- **Eliminação do Bloco Reto de 640m:** A caixa reta e escura que cortava o mapa foi substituída por um rio orgânico com meandros naturais gerados proceduramente ao longo de 640 metros.
- **Encaixe Milimétrico com a Ponte de Madeira:** O leito do rio passa com precisão na coordenada `Z = 22.0` sob a ponte do Santuário (`X = 0`), curvando-se graciosamente em meandros florestais a leste e oeste.
- **Margens Pedregosas e Arenosas:** Faixas de transição com cascalho, areia fina e rochas arredondadas de leito fluvial (`RiverBanks` e `RiverStones`).
- **Shader de Água Cristalina (`assets/shaders/water_river.gdshader`):**
  - Tons azul-turquesa rasos e safira profunda translúcida.
  - Ondulação de correnteza em duas direções que percorre o leito fluvial.
  - Espuma alva natural que se forma nas margens rochosas e pilares.
  - Reflexos especulares PBR vítreos refletindo a luz solar (`SPECULAR = 0.70`, `ROUGHNESS = 0.08`).

### 12.2 Eliminação do Padrão "Polka-Dot" na Caldeira Vulcânica (`assets/shaders/lava_pool.gdshader`)
- **Fissuras Tectônicas Reais (Voronoi F2 - F1 Edge-Cracking):** O padrão artificial de "bolinhas/ovos incandescentes" (causado pelo cálculo invertido de distância ao centro da célula Voronoi) foi completamente erradicado.
- **Placas de Basalto Queimado:** As placas rochosas são escuras, porosas e foscas (`basalt_crust` com `ROUGHNESS = 0.92`).
- **Magma Incandescente nos Veios:** O magma flui com convecção orgânica exclusivamente nas fissuras e frestas irregulares entre as placas, com calor intenso no núcleo e fusão radial com o solo florestal.

### 12.3 Rigging Anatômico e Hierarquia dos Mobs (`urgal_warrior.glb`)
- **Eliminação de Membros Desconexos:** Os membros dos monstros não são mais cilindros soltos flutuando em coordenadas mundiais arbitrárias.
- **Origem Exata nas Articulações:**
  - `Thigh` possui sua origem no quadril (Hip Joint).
  - `Shin` é filho direto de `Thigh` com origem no joelho (Knee Joint).
  - `Foot` é filho de `Shin` com origem no tornozelo (Ankle Joint).
  - `Arm` possui origem no ombro, `Forearm` no cotovelo e `Hand` no punho.
  - `WarAxe` é empunhado solidamente na mão direita do Urgal.
- Ao girar os membros durante a marcha ou ataque, os joelhos dobram de forma coesa sem desconectar a malha ou criar "bonecos de massinha".

### 12.4 Vozes e Falas Intimidantes de Bosses
- **Brados de Guerra e Vozes Monstruosas:**
  - `voice_boss_gromk_aggro.ogg`: Rugido gutural de guerra com ressonância profunda de formantes: *"VOU ESMAGAR SEUS OSSOS!"*.
  - `voice_boss_gromk_slam.ogg`: Brado violento antes do golpe sísmico: *"MORRA SOB MEU MACHADO!"*.
  - `voice_boss_durza_aggro.ogg`: Sussurro espectral abissal com reverberação sombria: *"SUA ALMA PERTENCE ÀS SOMBRAS..."*.
  - `voice_boss_knight_aggro.ogg`: Decreto fanático da Guarda Imperial: *"PELA GLÓRIA DE GALBATORIX!"*.
- **Exibição Visual Coordenada (HUD & 3D):**
  - A citação intimidadora do Chefe é exibida em destaque no subtítulo da barra de chefe do HUD superior.
  - Um balão de combate com o brado surge flutuando em 3D sobre o Boss (`FloatingCombatText.TextType.BOSS_SHOUT`).

### 12.5 Efeitos Sonoros Viscerais de Ataque de Mobs
- O áudio genérico de bipe sintético foi substituído por uma biblioteca de ataques viscerais dedicados:
  - **Ataque Pesado de Lâminas (`mob_attack_heavy_1` e `mob_attack_heavy_2`):** Rushing whoosh de aço pesado + soco subsônico + rasgo violento no ar.
  - **Ataques de Feras (`mob_attack_beast_1` e `mob_attack_beast_2`):** Estalo potente de mandíbulas, rosnado e unhadas cortantes.
  - **Impacto Contundente (`mob_attack_blunt_1`):** Terremoto de pedra e estalo de impacto em baixa frequência para Golems.
  - **Corte Espectral (`mob_attack_spectral_1`):** Foice do vazio com silvo místico e rastro reverberado para Wraiths.

### 12.6 Limpeza Total de Textos 3D em Chefes
- Quando um monstro é `MINIBOSS` ou `WORLD_BOSS`, sua barra de vida no HUD do topo da tela é a protagonista.
- A billboard flutuante de texto em 3D (`Label3D`) sobre a cabeça do monstro é desativada, eliminando colisões de texto, sobreposições de nomes e poluição visual na câmera isométrica.

---

## 13. Conclusão e Próximos Passos

O GameZero alcançou a consistência visual, plástica e acústica exigida para um ARPG Dark Fantasy moderno:
1. Cenário fluido com rio meandrado, pontes integradas e leito orgânico.
2. Shaders PBR equilibrados para lava (sem bolinhas/polka dots) e brejo tóxico (sem verde neon).
3. Monstros modelados e articulados com hierarquia de juntas sólida.
4. Áudio visceral e imersivo com falas intimidadoras de chefes e ataques brutais.
5. 100% de aprovação em todos os 5 bancos de testes automatizados no Godot headless.
