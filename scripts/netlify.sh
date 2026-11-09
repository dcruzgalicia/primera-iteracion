#!/usr/bin/env bash
set -euo pipefail

# TeX Live vía TinyTeX.
# TinyTeX ya incluye KOMA-Script, newtxtext/newtxmath, biblatex, biber,
# latexmk y los paquetes base de Pandoc. Aquí solo se agregan los que
# iteraciones necesita además de eso, y los que declare el proyecto.
#
# El caché de Netlify persiste entre deploys de la misma rama. Si está
# disponible, TinyTeX se instala ahí; si no, se reinstala en cada deploy.

cache="${NETLIFY_CACHE_DIR:-}"
if [ -z "$cache" ] || [ ! -w "$cache" ]; then
  cache=""
  for candidate in /opt/build/cache /opt/buildhome/cache; do
    if [ -d "$candidate" ] && [ -w "$candidate" ]; then
      cache="$candidate"
      break
    fi
  done
fi
cache="${cache:-$PWD}"

tex_root="$cache/.tinytex"
tex="$tex_root/.TinyTeX"
texbin="$tex/bin/x86_64-linux"

echo "→ TinyTeX: $tex"

if [ ! -x "$texbin/pdflatex" ]; then
  echo "→ instalando TinyTeX"
  curl -fsSL https://yihui.org/tinytex/install-bin-unix.sh | TINYTEX_DIR="$tex_root" sh
fi

# Paquetes que los preámbulos de iteraciones usan y que TinyTeX no trae.
packages="babel-spanish cjk pdfx biblatex-apa"

# Paquetes extra del proyecto (opcional), uno por línea.
if [ -f texlive-packages.txt ]; then
  extra="$(sed 's/#.*//' texlive-packages.txt | tr '\n' ' ')"
  packages="$packages $extra"
fi

installed="$(cat "$tex/.iteraciones-packages" 2>/dev/null || true)"
if [ "$packages" != "$installed" ]; then
  echo "→ instalando paquetes TeX: $packages"
  # shellcheck disable=SC2086
  "$texbin/tlmgr" install --no-interaction $packages
  printf '%s' "$packages" > "$tex/.iteraciones-packages"
fi

export PATH="$texbin:$PATH"
bun run build
