# Car Launcher

Launcher (tela inicial) em **Flutter** para centrais multimídia / tablets
automotivos Android. Pensado para uso em modo paisagem, com blocos grandes e
alto contraste para leitura rápida ao dirigir.

## Recursos

- **Relógio grande** com data em português (atualiza a cada segundo).
- **Velocímetro por GPS** (km/h) usando o stream de localização do dispositivo.
- **Clima atual** via [Open-Meteo](https://open-meteo.com/) — API gratuita e
  sem necessidade de chave.
- **Atalhos em blocos grandes** para Google Maps, Waze, Spotify, YouTube,
  Telefone e Ajustes. Apps ausentes caem para a Play Store/URL.
- Configurado como **HOME launcher**: `category.HOME` + `category.DEFAULT` no
  `AndroidManifest.xml`, orientação travada em paisagem e UI imersiva.

## Estrutura

```
lib/
  main.dart                 # entrada; trava paisagem + UI imersiva
  theme/app_theme.dart      # paleta e estilos dos blocos
  models/launcher_app.dart  # definição dos atalhos
  services/
    location_service.dart   # permissões + stream de GPS
    weather_service.dart    # consulta Open-Meteo
  screens/home_screen.dart  # layout principal (paisagem)
  widgets/
    clock_card.dart
    speedometer_card.dart
    weather_card.dart
    app_shortcut_card.dart
```

## Como rodar

```bash
flutter pub get
flutter run            # com emulador/dispositivo conectado
flutter build apk      # APK release
```

### Definir como tela inicial

Após instalar, pressione o botão Home do Android e escolha **Car Launcher**
como aplicativo de início (defina como padrão). A primeira execução pede
permissão de localização (necessária para velocímetro e clima).

## Permissões

- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` — velocímetro e clima.
- `INTERNET` — consulta de clima.
