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
     command = "bun run build"
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
brew "biber"
brew "texlive"
```

Netlify instala las fórmulas de `Brewfile.netlify` antes del build. `texlive` y `biber` solo son necesarios para PDF y LaTeX; si el sitio no genera esos formatos, se pueden quitar.

`netlify.toml` solo define lo mínimo:

```toml
[build]
  command = "bun run build"
  publish = "dist/files"

  [build.environment]
    BUN_VERSION = "1.4.2"
```

No hay scripts de despliegue: todo el build lo hace `iteraciones` con las herramientas del Brewfile.

Limitación conocida: Homebrew no conserva las fórmulas instaladas entre deploys, así que `texlive` se vuelve a instalar en cada build. La solución elegante es que `init sveltia` genere la configuración de Netlify (Brewfile, `netlify.toml`, caché y TeX) para que el usuario solo suba el repo y conecte Netlify, como en Quarto. Eso está pendiente en el CLI.

Nota sobre Quarto: su plugin de Netlify solo instala Quarto; para PDF recomienda instalar TinyTeX en GitHub Actions (`tinytex: true`) y publicar el resultado. Netlify no está pensado para instalar TeX en cada build.

Si Netlify no aplica el Brewfile en la imagen actual, queda como fallback el wrapper `tools/magick`, que usa `convert` y `compare` de ImageMagick 6. En ese caso hay que anteponer el PATH al comando:

```text
PATH="$PWD/tools:$PATH" bun run build
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
- Si falta un paquete LaTeX: el `texlive` de Homebrew instala la distribución completa; si aun así falta, agregarlo al `Brewfile.netlify` o al build.
- `minify` es opcional.

Si estas herramientas se instalan en cada build, cachear `.tools` para no descargarlas siempre.

## 6. Configurar OAuth de GitHub y Netlify

Sveltia usa el proveedor OAuth de Netlify. No hace falta `base_url` en `admin/config.yml`.

1. En `admin/config.yml`, reemplazar los tres placeholders con la URL real del sitio:

   ```yaml
   backend:
     site_domain: primera-iteracion.netlify.app
   site_url: https://primera-iteracion.netlify.app
   display_url: https://primera-iteracion.netlify.app
   ```

   `site_domain` es solo el dominio, sin `https://`. Sirve para que el login funcione también desde los deploy previews de los pull requests.

2. Crear una OAuth App en GitHub:
   - GitHub → Settings → Developer settings → OAuth Apps → New OAuth App.
   - Application name: el que quieras, por ejemplo `iteraciones primera-iteracion`.
   - Homepage URL: la URL del sitio en Netlify.
   - Authorization callback URL: `https://api.netlify.com/auth/done`.
   - Registrar y copiar el **Client ID**.
   - Generar un **Client Secret** y copiarlo; no se vuelve a mostrar.

3. En Netlify:
   - Project configuration → Security → OAuth.
   - **No** es la sección Identity.
   - Authentication Providers → Install Provider → GitHub.
   - Pegar Client ID y Client Secret, guardar.

4. Confirmar que `admin/config.yml` tiene:

   ```yaml
   backend:
     name: github
     repo: dcruzgalicia/primera-iteracion
     branch: main
     auth_scope: public_repo
     open_authoring: true

   publish_mode: editorial_workflow
   ```

   - `auth_scope: public_repo` es suficiente porque el repo es público.
   - Open Authoring exige `editorial_workflow` o `preview`. No usar `simple`.

No usar Netlify Identity ni Git Gateway: Sveltia no los soporta.

## 7. Probar el login y Open Authoring

### Login como dueño del repo

1. Abrir `https://TU-SITIO.netlify.app/admin/`.
2. Elegir **Sign in with GitHub**.
3. Autorizar la OAuth App.
4. Debe regresar al CMS con la lista de colecciones.

### Open Authoring con una cuenta sin permisos

1. Usar una segunda cuenta de GitHub que no sea colaboradora del repo, o una ventana de incógnito con otra cuenta.
2. Abrir `/admin/` e iniciar sesión.
3. Sveltia pide crear un fork del repositorio; aceptar.
4. Editar o crear una entrada.
5. Guardar y elegir **Send for Review**.
6. Debe abrirse un pull request desde el fork hacia `main`.
7. Netlify debe generar un deploy preview de ese PR.
8. Abrir `/admin/` en el deploy preview e iniciar sesión: gracias a `site_domain`, el OAuth debe funcionar también ahí.
9. Como dueño, revisar y mergear el PR. El cambio se publica y el build se ejecuta.

Si el login falla:

- Revisar que la callback URL sea exactamente `https://api.netlify.com/auth/done`.
- Revisar que el Client ID y el Secret estén en Netlify, no en Identity.
- Revisar que `site_domain` sea el dominio real de producción.
- Revisar que `base_url` no esté definido en `admin/config.yml`.
- Si el sitio usa un dominio propio, actualizar `site_url`, `display_url`, `site_domain`, la Homepage URL de la OAuth App y el dominio en Netlify.

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
