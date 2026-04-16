# Tempra Hub — module registry tasks
# Usage: just <recipe>

set shell := ["bash", "-euo", "pipefail", "-c"]

# ==================== Validation ====================

# Validate all module TOML files parse correctly
validate:
    #!/usr/bin/env bash
    set -euo pipefail
    errors=0
    for f in modules/**/*.toml; do
        if ! python3 -c "import tomllib; tomllib.load(open('$f','rb'))" 2>/dev/null; then
            if ! python3 -c "import toml; toml.load('$f')" 2>/dev/null; then
                echo "FAIL: $f"
                errors=$((errors + 1))
            fi
        fi
        echo "  OK: $f"
    done
    if [[ $errors -gt 0 ]]; then
        echo "${errors} module(s) failed validation"
        exit 1
    fi
    echo "All modules valid."

# Regenerate SHA256 checksums in channels/stable.toml
checksums:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "SHA256 checksums for stable channel:"
    for f in modules/**/*.toml; do
        sha=$(sha256sum "$f" | cut -d' ' -f1)
        echo "  $f: $sha"
    done
    echo ""
    echo "Update channels/stable.toml manually with these values."

# ==================== Git helpers ====================

# Sign unsigned commits since origin/main
sign-commits:
    #!/usr/bin/env bash
    set -euo pipefail

    UPSTREAM="origin/main"

    UNSIGNED=$(git log --format='%H %G?' "${UPSTREAM}..HEAD" 2>/dev/null | grep -v ' G$' | grep -v ' U$' | wc -l)

    if [[ "$UNSIGNED" -eq 0 ]]; then
        echo "All commits since ${UPSTREAM} are already signed."
        exit 0
    fi

    echo "Signing ${UNSIGNED} commit(s) since ${UPSTREAM}..."
    git rebase --exec 'git commit --amend -S --no-edit' "${UPSTREAM}"
    echo "Done."

# Sign and force-push in one step
sign-and-push: sign-commits
    git push --force-with-lease

# ==================== Release ====================

# Tag a release (add --sign for GPG-signed tag)
release *flags:
    #!/usr/bin/env bash
    set -euo pipefail

    SIGN=false
    for flag in {{ flags }}; do
        case "${flag}" in
            --sign|-s) SIGN=true ;;
            *) echo "Unknown flag: ${flag}"; exit 1 ;;
        esac
    done

    CURRENT_TAG=$(git tag --sort=-v:refname --list "v*" | head -1)
    if [[ -z "${CURRENT_TAG}" ]]; then
        CURRENT_VERSION="0.0.0"
    else
        CURRENT_VERSION="${CURRENT_TAG#v}"
    fi

    IFS='.' read -r MAJOR MINOR PATCH <<< "${CURRENT_VERSION}"
    NEXT_PATCH="${MAJOR}.${MINOR}.$((PATCH + 1))"
    NEXT_MINOR="${MAJOR}.$((MINOR + 1)).0"

    NEXT_MAJOR="$((MAJOR + 1)).0.0"

    echo "Current: v${CURRENT_VERSION}"

    if command -v gum >/dev/null 2>&1; then
        NEXT_VERSION=$(gum choose --header "Next version?" \
            "${NEXT_PATCH} (patch)" \
            "${NEXT_MINOR} (minor)" \
            "${NEXT_MAJOR} (major)" \
            "custom")

        case "${NEXT_VERSION}" in
            *patch*)  NEXT_VERSION="${NEXT_PATCH}" ;;
            *minor*)  NEXT_VERSION="${NEXT_MINOR}" ;;
            *major*)  NEXT_VERSION="${NEXT_MAJOR}" ;;
            custom)   NEXT_VERSION=$(gum input --header "Enter version:" --placeholder "${NEXT_PATCH}") ;;
        esac
    else
        echo ""
        echo "  1) ${NEXT_PATCH} (patch)"
        echo "  2) ${NEXT_MINOR} (minor)"
        echo "  3) ${NEXT_MAJOR} (major)"
        read -rp "Pick [1-3]: " choice
        case "${choice}" in
            1) NEXT_VERSION="${NEXT_PATCH}" ;;
            2) NEXT_VERSION="${NEXT_MINOR}" ;;
            3) NEXT_VERSION="${NEXT_MAJOR}" ;;
            *) echo "Invalid choice"; exit 1 ;;
        esac
    fi

    TAG="v${NEXT_VERSION}"

    if git rev-parse "${TAG}" >/dev/null 2>&1; then
        echo "ERROR: Tag ${TAG} already exists"
        exit 1
    fi

    if ! grep -q "## v${NEXT_VERSION}" CHANGELOG.md 2>/dev/null; then
        echo "ERROR: No CHANGELOG.md entry for v${NEXT_VERSION}"
        exit 1
    fi

    if [[ "${SIGN}" == "true" ]]; then
        git tag -s "${TAG}" -m "Release ${TAG}"
    else
        git tag -a "${TAG}" -m "Release ${TAG}"
    fi

    echo ""
    echo "Tag ${TAG} created."
    echo "Next: git push && git push origin ${TAG}"

# Show current version
version:
    @echo "Latest tag:"
    @git tag --sort=-v:refname --list "v*" | head -1 || echo "(no tags)"
