# Despliegue en Netlify

Este documento es para el proyecto de prueba `primera-iteracion`. La idea es que `iteraciones init sveltia` genere la mayor parte y que aquí quede solo lo que depende de cuentas externas.

## 1. Antes de crear cuentas

En el proyecto deben existir:

- `admin/index.html`
- `admin/config.yml`
- `admin/vendor/sveltia-cms.js`
- `package.json`
- `bun.lock`

`init sveltia` ya se ejecutó en este proyecto, así que esos archivos existen. El build copia `admin/` automáticamente.

## CLI temporal sin publicar

Este proyecto de prueba incluye:

```text
vendor/iteraciones-cli-0.27.0.tgz
```

y en `package.json`:

```json
"dependencies": {
  "iteraciones-cli": "file:vendor/iteraciones-cli-0.27.0.tgz"
}
```

Eso permite que Netlify ejecute `bun install` y tenga el binario `iteraciones` sin publicar el paquete en npm.

Para un proyecto real, lo correcto es publicar la CLI o usar un release/tag fijo (#2771). El tarball es solo para esta prueba.

## 2. Crear el repositorio en GitHub

1. Crear un repositorio, por ejemplo `usuario/primera-iteracion`.
2. En el proyecto, si todavía no tiene remoto:

```bash
git add .
git commit -m "proyecto inicial"
git remote add origin git@github.com:usuario/primera-iteracion.git
git push -u origin main
```

El proyecto ya tiene repositorio Git local.

3. Decidir si el repositorio será público o privado.

- Público: Open Authoring es más sencillo.
- Privado: debe ser de una organización para que Open Authoring funcione con permisos de lectura.

## 3. Actualizar `admin/config.yml`

Reemplazar los placeholders:

```yaml
backend:
  name: github
  repo: usuario/primera-iteracion
  branch: main
  open_authoring: true
  auth_scope: public_repo
```

Y, si todavía no existe el sitio en Netlify, deja los placeholders o elimina estas dos líneas:

```yaml
site_url: https://TU-SITIO.netlify.app
display_url: https://TU-SITIO.netlify.app
```

No inventes un dominio real todavía. `site_url` solo afecta enlaces de preview y la URL que muestra Sveltia; no es necesario para iniciar sesión ni para el OAuth.

Notas:

- Si el repo es privado, usar `auth_scope: repo`.
- No agregar `base_url` si se usa el OAuth de Netlify.
- `publish_mode: editorial_workflow` debe quedar activo si se usa Open Authoring.
- `site_url` puede quedar con la URL de Netlify mientras no haya dominio propio.

## 4. Crear el sitio en Netlify

1. En Netlify: Add new site → Import an existing project.
2. Conectar GitHub y elegir el repositorio.
3. El repositorio incluye `netlify.toml`, así que no hace falta configurar el build command en la UI: el archivo tiene prioridad.

   ```toml
   [build]
     command = "..."
     publish = "dist/files"
   ```

4. `BUN_VERSION` también está en `netlify.toml`:

   ```toml
   [build.environment]
     BUN_VERSION = "1.4.2"
   ```

5. Cuando Netlify termine de crear el sitio, copia la URL que te da, por ejemplo:

   ```text
   https://nombre-aleatorio.netlify.app
   ```

6. Actualiza `admin/config.yml` con esa URL:

   ```yaml
   site_url: https://nombre-aleatorio.netlify.app
   display_url: https://nombre-aleatorio.netlify.app
   ```

   Si después agregas un dominio propio, cambias esas dos URLs por el dominio final.

## 5. Verificar las herramientas de Netlify

Netlify no incluye `magick` (ImageMagick 7) por defecto. El proyecto incluye:

```text
Brewfile.netlify
```

con:

```ruby
brew "pandoc"
brew "imagemagick"
brew "minify"
brew "poppler"
```

Netlify instala las fórmulas de `Brewfile.netlify` antes del build.

### LaTeX

TeX Live no se instala con Homebrew: se instala TinyTeX desde `netlify.toml`.

`netlify.toml` no tiene un campo para instalar paquetes del sistema, así que la instalación va en `build.command`. No hay scripts aparte: todo queda en el TOML.

TinyTeX ya incluye KOMA-Script (`scrbook`, `scrlayer-scrpage`), `newtxtext`/`newtxmath`, `biblatex`, `biber`, `latexmk` y los paquetes base que usa Pandoc. El comando agrega los que los preámbulos de iteraciones necesitan y TinyTeX no trae:

```text
babel-spanish cjk pdfx biblatex-apa
```

Si un proyecto usa paquetes adicionales, se declaran en:

```text
texlive-packages.txt
```

un paquete por línea. El comando los instala con `tlmgr` en el siguiente build. Por ejemplo, para un sitio en francés:

```text
babel-french
```

El caché se resuelve con el plugin genérico `netlify-plugin-cache`, declarado en `netlify.toml`:

```toml
[[plugins]]
  package = "netlify-plugin-cache"

  [plugins.inputs]
    paths = [".TinyTeX", ".iteraciones", "dist"]
```

Así TinyTeX se instala una sola vez, y también se conservan `.iteraciones` y `dist` entre deploys. El plugin guarda solo si el build termina bien.

Nota: Quarto resuelve el PDF de forma parecida, pero fuera de Netlify. Su plugin de Netlify solo instala Quarto; para PDF recomienda instalar TinyTeX en GitHub Actions (`tinytex: true`) y publicar el resultado. Netlify no está pensado para instalar TeX en cada build.

Si Netlify no aplica el Brewfile en la imagen actual, queda como fallback el wrapper `tools/magick`, que usa `convert` y `compare` de ImageMagick 6. En ese caso hay que anteponer el PATH al comando de `netlify.toml`:

```text
PATH="$PWD/tools:$PATH" <comando actual>
```

Netlify no garantiza Pandoc, LaTeX ni ImageMagick. En el primer build revisar:

```bash
iteraciones doctor
pandoc --version
magick -version
pdflatex --version
```

- Si falta Pandoc: instalarlo en el build o en un paso previo.
- Si falta `magick` o hay ImageMagick 6: instalar ImageMagick 7.
- Si falta un paquete LaTeX: agregarlo a `texlive-packages.txt`.
- `minify` es opcional.

Si estas herramientas se instalan en cada build, cachear `.tools` para no descargarlas siempre.

## 6. Configurar OAuth de GitHub

1. Crear una OAuth App en GitHub:
   - Homepage URL: la URL del sitio.
   - Authorization callback URL: `https://api.netlify.com/auth/done`
2. Copiar Client ID y Client Secret.
3. En Netlify: Project configuration → Security → OAuth.
4. Instalar el proveedor GitHub con esas credenciales.

No usar Netlify Identity ni Git Gateway: Sveltia no los soporta.

## 7. Probar antes del dominio

1. Abrir `https://TU-SITIO.netlify.app/admin/`.
2. Iniciar sesión con GitHub.
3. Editar un texto.
4. Crear una palabra clave.
5. Subir una imagen.
6. Confirmar que el build se ejecuta.
7. Probar un pull request de Open Authoring con una cuenta sin permiso de escritura.
8. Confirmar que el deploy preview funciona.

## 8. Cache incremental (opcional)

El primer despliegue no necesita cache. Si los builds se vuelven lentos, se puede agregar después un plugin de cache para:

- `.iteraciones`
- `dist/files`
- `.tools` si se instalan herramientas

El primer build de una rama será completo. Los siguientes pueden ser incrementales. No es requisito para el primer deploy.

## 9. Dominio

1. Mantener el sitio anterior vivo hasta que todo funcione, si existe.
2. Agregar el dominio en Netlify.
3. Configurar DNS.
4. Verificar HTTPS.
5. Revisar que no se rompan correos u otros registros DNS.

## 10. Pendiente de la CLI

Lo que todavía no está resuelto es la publicación estable de la CLI:

- #2771 publicar `iteraciones-cli` o dar un release instalable.

Mientras tanto, este proyecto usa el tarball de `vendor/`. Eso es suficiente para desplegar la prueba en Netlify.
