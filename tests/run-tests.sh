#!/usr/bin/env bash
# Self-tests for tests/validate.py: the valid fixture must pass, and each mutated
# copy of it must fail with a specific message. Bash 3.2 compatible (macOS).
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
validator="$here/validate.py"
fixture="$here/fixtures/valid"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
pass=0
fail=0

P=skills/party-mode/references/personas.md
R=skills/party-mode/references/rooms.md

expect_ok() { # name root [extra validator args...]
    local name="$1" root="$2" out
    shift 2
    if out=$(python3 "$validator" --root "$root" "$@" 2>&1); then
        pass=$((pass + 1)); echo "[OK] $name"
    else
        fail=$((fail + 1)); echo "[FAIL] $name — expected success, got:"; echo "$out"
    fi
}

expect_err() { # name root needle [extra validator args...]
    local name="$1" root="$2" needle="$3" out
    shift 3
    if out=$(python3 "$validator" --root "$root" "$@" 2>&1); then
        fail=$((fail + 1)); echo "[FAIL] $name — expected failure, validator passed"
    elif printf '%s' "$out" | grep -qF -- "$needle"; then
        pass=$((pass + 1)); echo "[OK] $name"
    else
        fail=$((fail + 1)); echo "[FAIL] $name — missing '$needle' in:"; echo "$out"
    fi
}

# mutant NAME FILE OLD NEW -> prints the path of a fixture copy with OLD replaced by NEW in FILE
mutant() {
    local dir="$tmp/$1"
    rm -rf "$dir"
    cp -R "$fixture" "$dir"
    python3 - "$dir/$2" "$3" "$4" <<'PY'
import sys
path, old, new = sys.argv[1:4]
with open(path, encoding="utf-8") as fh:
    text = fh.read()
assert old in text, "mutation anchor not found in %s: %r" % (path, old)
with open(path, "w", encoding="utf-8") as fh:
    fh.write(text.replace(old, new, 1))
PY
    printf '%s' "$dir"
}

expect_ok  "valid fixture" "$fixture"
expect_err "bad semver" "$(mutant semver .claude-plugin/plugin.json '"0.1.0"' '"0.1"')" "is not semver"
expect_err "missing skill description" "$(mutant skilldesc skills/party-mode/SKILL.md 'description: Fixture skill.' '')" "missing frontmatter 'description'"
expect_err "missing agent description" "$(mutant agentdesc agents/party-guest.md 'description: Fixture guest.' '')" "missing frontmatter 'description'"
expect_err "missing persona field" "$(mutant field $P '- signature_question: "What breaks?"' '')" "'beta' missing field 'signature_question'"
expect_err "empty persona field" "$(mutant empty $P '- voice: Curious.' '- voice:')" "'gamma' field 'voice' is empty"
expect_err "duplicate persona" "$(mutant dup $P '## gamma' '## alpha')" "duplicate entry 'alpha'"
expect_err "invalid persona code" "$(mutant code $P '## gamma' '## Gamma_X')" "invalid code 'Gamma_X'"
expect_err "unknown friction code" "$(mutant friction $P '- friction: beta (speed vs. safety)' '- friction: delta (speed vs. safety)')" "friction references unknown persona 'delta'"
expect_err "unknown room member" "$(mutant member $R '- members: alpha, beta, gamma' '- members: alpha, beta, delta')" "room 'round-table' has unknown member 'delta'"
expect_err "too few members" "$(mutant few $R '- members: alpha, beta, gamma' '- members: alpha, beta')" "room 'round-table' needs 3-5 members, has 2"
expect_err "memory not boolean" "$(mutant memory $R '- memory: false' '- memory: maybe')" "room 'round-table' memory must be true or false"
expect_err "default room missing" "$(mutant default $R '## round-table' '## other-room')" "default room 'round-table' missing"
expect_err "missing personas file" "$(mutant nofile $P '## alpha' '## alpha' >/dev/null && rm "$tmp/nofile/$P" && printf '%s' "$tmp/nofile")" "missing file"

# Project overrides (--party-dir)
mkdir -p "$tmp/party-ok" "$tmp/party-bad"
cat > "$tmp/party-ok/personas.md" <<'MD'
## delta
- name: Delta
- icon: 🔺
- role: Fourth voice
- voice: Loud.
- cares_about: Change.
- pushes_back_on: Status quo.
- signature_question: "Why not now?"
- friction: alpha
MD
cat > "$tmp/party-ok/rooms.md" <<'MD'
## pair-room
- name: Pair Room
- members: alpha, beta, delta
- memory: true
- scene: A smaller room.
MD
cat > "$tmp/party-bad/personas.md" <<'MD'
## delta
- name: Delta
MD
expect_ok  "valid project overrides" "$fixture" --party-dir "$tmp/party-ok"
expect_err "incomplete override persona" "$fixture" "'delta' missing field 'icon'" --party-dir "$tmp/party-bad"
expect_err "missing party dir" "$fixture" "party dir" --party-dir "$tmp/does-not-exist"
expect_err "duplicate room member" "$(mutant dupmember $R '- members: alpha, beta, gamma' '- members: alpha, alpha, beta')" "lists member 'alpha' twice"

# Override entries replace the base entry completely (no field merging)
mkdir -p "$tmp/party-replace" "$tmp/party-badroom"
cat > "$tmp/party-replace/personas.md" <<'MD'
## alpha
- name: A
MD
cat > "$tmp/party-badroom/rooms.md" <<'MD'
## bad-room
- name: Bad Room
- members: alpha, beta, nobody
- memory: false
- scene: A room with a stranger.
MD
expect_err "override persona replaces base" "$fixture" "'alpha' missing field 'icon'" --party-dir "$tmp/party-replace"
expect_err "override room unknown member" "$fixture" "room 'bad-room' has unknown member 'nobody'" --party-dir "$tmp/party-badroom"

# Manifest robustness: wrong JSON types must yield errors, not tracebacks
expect_err "non-string version" "$(mutant version .claude-plugin/plugin.json '"version": "0.1.0"' '"version": 1')" "version must be a string"
expect_err "author not an object" "$(mutant author .claude-plugin/plugin.json '"author": {"name": "Fixture"}' '"author": "Fixture"')" "missing key 'author.name'"
expect_err "manifest not an object" "$(mutant notobject .claude-plugin/plugin.json '"0.1.0"' '"0.1.0"' >/dev/null && printf '[]' > "$tmp/notobject/.claude-plugin/plugin.json" && printf '%s' "$tmp/notobject")" "manifest must be a JSON object"

# Persona friction and field checks
expect_ok  "friction reason with comma" "$(mutant frictioncomma $P '- friction: beta (speed vs. safety)' '- friction: beta (speed, not safety)')"
expect_err "field set twice" "$(mutant twice $P '- friction: none' $'- friction: none\n- friction: alpha')" "sets field 'friction' twice"
expect_err "self friction" "$(mutant selffriction $P '- friction: none' '- friction: gamma')" "lists itself in friction"
expect_err "wrong skill name" "$(mutant skillname skills/party-mode/SKILL.md 'name: party-mode' 'name: party')" "frontmatter name must be 'party-mode'"

echo "--- $pass passed, $fail failed ---"
[ "$fail" -eq 0 ]
