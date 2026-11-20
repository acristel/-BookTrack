# BookTrack

BookTrack permite importar libros PDF y EPUB, guardar el progreso de lectura y
solicita iniciar sesión con Google al abrir un libro.

## Configurar Google Sign-In en Android

1. En Google Cloud Console, crea un cliente OAuth para Android con el nombre de
   paquete `com.example.booktrack` y la huella SHA-1 de cada clave de firma que
   usarás. Para obtener la huella de depuración en PowerShell:

   ```powershell
   keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" `
     -alias androiddebugkey -storepass android -keypass android
   ```

2. Crea también un cliente OAuth de tipo aplicación web. No es un secreto; la
   app lo necesita para Google Sign-In. El ID web de este proyecto ya está
   configurado como valor predeterminado.
3. Si reemplazas ese cliente o usas otro proyecto, pasa su ID al ejecutar:

   ```powershell
   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID
   ```

   Usa la misma opción `--dart-define` al compilar la aplicación. Para una
   versión de producción, registra además la huella SHA-1 de la clave de firma
   de publicación en Google Cloud Console.

La autenticación es una puerta de acceso local a la lectura: no existe un
backend de BookTrack que valide identidades ni sincronice cuentas.

## Ejecutar en Web

1. En el cliente OAuth web, agrega estos orígenes JavaScript autorizados:
   `http://localhost` y `http://localhost:7357`.
2. Los libros y la biblioteca se guardan en IndexedDB del navegador. Mantén el
   mismo host y puerto para conservar los datos entre ejecuciones.
3. Inicia la app en Chrome:

   ```powershell
   flutter run -d chrome --web-hostname localhost --web-port 7357
   ```

Para publicar la versión web, agrega también el origen HTTPS del sitio en el
cliente OAuth web y ejecuta `flutter build web`.

## Ejecutar pruebas

```powershell
flutter test
flutter analyze
```
