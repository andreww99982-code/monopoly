# Монополия (Monopoly)

Минимальный, но полностью компилируемый каркас Unity-проекта «Монополия»
для сборки под Android. Проект не использует сторонние пакеты — только
стандартные модули Unity — и спроектирован так, чтобы его было легко
расширять новым контентом (клетками поля, темами оформления, экранами UI).

## Структура проекта

```
Assets/
  Scripts/
    Core/
      MonopolyEngine.cs   — игровой движок: поле, ходы, кубики, покупка, аренда, банкротство
      MonopolyAI.cs       — простой ИИ для ботов (решения о покупке недвижимости)
      GameThemeSO.cs       — ScriptableObject-описание темы оформления
    Managers/
      SaveManager.cs       — сохранение/загрузка партии в JSON (persistentDataPath)
      AudioManager.cs      — управление музыкой и звуковыми эффектами
      ThemeManager.cs      — загрузка и применение тем из Resources/Themes
    UI/
      UIManager.cs         — переключение экранов интерфейса (меню, игра, настройки и т.д.)
  Resources/
    Themes/                — 4 готовые темы оформления (ScriptableObject-ассеты):
      Theme_Classic.asset  — «Классическая»
      Theme_Neon.asset     — «Неоновая»
      Theme_Retro.asset    — «Ретро»
      Theme_Fantasy.asset  — «Фэнтези»
  Scenes/
    Bootstrap.unity        — сцена-заглушка для инициализации
    MainMenu.unity         — сцена-заглушка главного меню
    Game.unity             — сцена-заглушка игрового процесса
ProjectSettings/           — настройки проекта Unity, включая параметры Android
Packages/manifest.json     — список встроенных модулей Unity (без внешних зависимостей)
.github/workflows/build-android.yml — CI-сборка APK через GameCI
```

## Архитектура

- **MonopolyEngine** — независимый от Unity API движок партии (генерация поля,
  броски кубиков, перемещение, покупка клеток, оплата аренды, банкротство,
  определение победителя через события `OnPlayerMoved`, `OnPropertyPurchased` и т.д.).
- **MonopolyAI** — принимает решения за ботов на основе баланса и уровня
  «осторожности», не привязан к конкретной реализации UI.
- **GameThemeSO** — ScriptableObject, задающий палитру цветов, название валюты
  и медиа-ресурсы темы. Новая тема добавляется созданием нового ассета в
  `Assets/Resources/Themes` — без изменения кода.
- **SaveManager / AudioManager / ThemeManager / UIManager** — реализованы как
  ленивые синглтоны (создаются автоматически через `RuntimeInitializeOnLoadMethod`
  или статическое свойство `Instance`), поэтому не требуют ручного размещения
  в сценах и легко переиспользуются между сценами благодаря `DontDestroyOnLoad`.

## Требования

- Unity **2022.3 LTS** (версия зафиксирована в `ProjectSettings/ProjectVersion.txt`).
- Модуль **Android Build Support** (для локальной сборки в редакторе).
- Внешние зависимости не требуются — используются только модули Unity
  (перечислены в `Packages/manifest.json`).

## Сборка под Android

### Локально

1. Откройте проект в Unity Hub (версия из `ProjectVersion.txt`).
2. Убедитесь, что установлен модуль **Android Build Support**.
3. `File → Build Settings → Android → Switch Platform`.
4. `File → Build Settings → Build` для получения APK/AAB.

### Через GitHub Actions (GameCI)

Сборка автоматизирована в `.github/workflows/build-android.yml` с помощью
[game-ci/unity-builder](https://github.com/game-ci/unity-builder). Для работы
воркфлоу добавьте в секреты репозитория:

- `UNITY_LICENSE`
- `UNITY_EMAIL`
- `UNITY_PASSWORD`

Готовый APK публикуется как артефакт сборки (`android-build`).

## Расширение проекта

- **Новая тема**: создайте ассет через `Create → Монополия → Тема оформления`
  в папке `Assets/Resources/Themes` — `ThemeManager` подхватит её автоматически.
- **Новая логика поля/событий**: расширяйте `MonopolyEngine` и подписывайтесь
  на его события из UI-слоя, не создавая жёстких связей между модулями.
- **Новый экран UI**: добавьте значение в `enum UIScreen` и зарегистрируйте
  панель через `UIManager.Instance.RegisterPanel(...)`.
