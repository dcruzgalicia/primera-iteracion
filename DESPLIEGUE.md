# Despliegue en Netlify

Este documento es para el proyecto de prueba `primera-iteracion`. La idea es que `iteraciones init sveltia` genere la mayor parte y que aquí quede solo lo que depende de cuentas externas.

## 1. Antes de crear cuentas

En el proyecto deben existir:

- `admin/index.html`
- `admin/config.yml`
- `admin/vendor/sveltia-cms.js`
- `package.json`
- `bun.lock`
- `netlify.toml` (opcional; Netlify también puede configurarse desde la UI)

Si todavía no existen, hay que esperar a que estén implementados:

- #2769 `init sveltia`
- #2770 copia automática de `admin/` en el build
- #2771 instalación de la CLI para Netlify/CI

## 2. Crear el repositorio en GitHub

1. Crear un repositorio, por ejemplo `usuario/primera-iteracion`.
2. En el proyecto:

```bash
git init
git add .
git commit -m "proyecto inicial"
git remote add origin git@github.com:usuario/primera-iteracion.git
git push -u origin main
```

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

Y:

```yaml
site_url: https://TU-DOMINIO
display_url: https://TU-DOMINIO
```

Notas:

- Si el repo es privado, usar `auth_scope: repo`.
- No agregar `base_url` si se usa el OAuth de Netlify.
- `publish_mode: editorial_workflow` debe quedar activo si se usa Open Authoring.
- `site_url` puede quedar con la URL de Netlify mientras no haya dominio propio.

## 4. Crear el sitio en Netlify

1. En Netlify: Add new site → Import an existing project.
2. Conectar GitHub y elegir el repositorio.
3. Configurar:
   - Build command: `bun run build`
   - Publish directory: `dist/files`
   - `BUN_VERSION`: la versión usada localmente, por ejemplo `1.4`
4. El `netlify.toml` es opcional. Si no existe, configura build command, publish directory y `BUN_VERSION` en la UI de Netlify. Si existe, revisa que coincida con la UI.

## 5. Verificar las herramientas de Netlify

Netlify no garantiza Pandoc, LaTeX ni ImageMagick. En el primer build revisar:

```bash
iteraciones doctor
pandoc --version
magick -version
```

- Si falta Pandoc: instalarlo en el build o en un paso previo.
- Si falta `magick` o hay ImageMagick 6: instalar ImageMagick 7.
- LaTeX/PDF no hace falta si PDF sigue desactivado.
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

## 8. Cache incremental

El `netlify.toml` debería cachear:

- `.iteraciones`
- `dist/files`
- `.tools` si se instalan herramientas

El primer build de una rama será completo. Los siguientes deben ser incrementales. Probar con dos commits seguidos y revisar el log.

## 9. Dominio

1. Mantener WordPress vivo hasta que todo funcione.
2. Agregar el dominio en Netlify.
3. Configurar DNS.
4. Verificar HTTPS.
5. Revisar que no se rompan correos u otros registros DNS.

## 10. Pendiente de la CLI

Lo que todavía no está resuelto:

- `init sveltia` (#2769)
- copia automática de `admin/` al build (#2770)
- instalación estable de la CLI en Netlify (#2771)

Hasta que esos issues estén resueltos, este proyecto no se puede desplegar con el flujo automatizado completo.
