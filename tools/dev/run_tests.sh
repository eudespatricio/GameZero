#!/usr/bin/env bash
# Executa a suíte de testes headless do GameZero.
#
# Uso:
#   tools/dev/run_tests.sh            # todos os testes
#   tools/dev/run_tests.sh stats      # apenas os que casam com o filtro
#
# Variáveis:
#   GODOT=/caminho/para/godot         # binário do Godot 4 (default: godot do PATH)
#
# Retorna 0 somente se todos os testes passarem sem erros de script.
set -uo pipefail

cd "$(dirname "$0")/../.." || exit 1
GODOT="${GODOT:-godot}"
FILTER="${1:-}"

if ! command -v "$GODOT" >/dev/null 2>&1; then
	echo "✗ Godot não encontrado (defina GODOT=/caminho/do/godot)." >&2
	exit 127
fi

TESTS=(
	scripts/tests/run_paperdoll_tests.gd
	scripts/tests/run_sets_and_affixes_test.gd
	scripts/tests/test_character_level_persistence.gd
	scripts/tests/test_gear_visual_sync.gd
	scripts/tests/run_backend_and_version_tests.gd
	scripts/tests/run_quest_and_ui_enhancements_test.gd
	scripts/tests/run_polish_features_test.gd
	scripts/tests/run_gameplay_tests.gd
	scripts/tests/run_diablo4_mobs_test.gd
	scripts/tests/run_tree_occlusion_test.gd
	scripts/tests/test_character_selection.gd
)

passed=0
failed=0
failed_names=()

for t in "${TESTS[@]}"; do
	[ -n "$FILTER" ] && [[ "$t" != *"$FILTER"* ]] && continue
	name="$(basename "$t" .gd)"
	log="$(mktemp)"
	if timeout 300 "$GODOT" --headless --path . --script "$t" >"$log" 2>&1; then
		# Alguns testes sinalizam falha apenas no texto: procura marcadores.
		if grep -qE '❌|⚠️ [A-Z ]*ERRO|ERROS DETECTADOS|HOUVE FALHAS' "$log"; then
			printf '  ✗ %-38s (asserções falharam)\n' "$name"
			grep -E '❌' "$log" | head -5 | sed 's/^/      /'
			failed=$((failed + 1))
			failed_names+=("$name")
		elif grep -q 'SCRIPT ERROR' "$log"; then
			printf '  ✗ %-38s (erro de script)\n' "$name"
			grep -A2 'SCRIPT ERROR' "$log" | head -6 | sed 's/^/      /'
			failed=$((failed + 1))
			failed_names+=("$name")
		else
			printf '  ✓ %-38s\n' "$name"
			passed=$((passed + 1))
		fi
	else
		printf '  ✗ %-38s (exit != 0)\n' "$name"
		tail -12 "$log" | sed 's/^/      /'
		failed=$((failed + 1))
		failed_names+=("$name")
	fi
	rm -f "$log"
done

echo
echo "──────────────────────────────────────────────"
echo "  ✓ ${passed} passaram   ✗ ${failed} falharam"
if [ "${#failed_names[@]}" -gt 0 ]; then
	echo "  Falhas: ${failed_names[*]}"
fi
echo "──────────────────────────────────────────────"
[ "$failed" -eq 0 ]
