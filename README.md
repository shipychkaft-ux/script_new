# Nightix — ManaV2ForRoblox Edition

Чит-скрипт для Roblox с меню **Nightix** (портировано из Minecraft client Nightix 1.21.11).

## ✨ Особенности

- Полностью переработанное меню в стиле ClickGUI из Nightix
- **Иконка Nightix** (rbxassetid://80320370259758) — перекрашивается под выбранную тему
- 5 цветовых тем
- Поиск, анимации, прокрутка

## 🎮 Установка

### 1. Загрузите файлы на GitHub

1. Перейдите на https://github.com и создайте новый репозиторий (или используйте существующий `script_new`).
2. Загрузите в репозиторий **все файлы** из этой папки:
-   `GuiLibrary.lua`
-   `MainScript.lua`
-   `NightixMenu.lua`
-   `Universal.lua`
-   `espLibrary.lua`
-   `playersHandler.lua`
-   `toolHandler.lua`
-   `loadstring.lua`
-   `README.md`

### 2. Использование

В Roblox-эксплоите (Synapse, Fluxus, KRNL и т.д.) выполните:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/shipychkaft-ux/script_new/main/MainScript.lua"))()
```

Либо используйте `loadstring.lua` из папки.

## 🧭 Новое меню (в стиле Nightix)

Меню переработано по образцу ClickGUI из Minecraft-клиента **Nightix 1.21.11**:

- **Центральное окно** — одно окно по центру экрана
- **Слева** — иконки категорий (Combat, Movement, Render, Utility, World, Settings...)
- **По центру** — список модулей выбранной категории
- **Справа** — настройки выбранного модуля
- **Поиск** — фильтрация модулей + счётчик результатов
- **Темы** — точки переключения цветовой темы сверху
- **ЛКМ по модулю** — вкл/выкл
- **ПКМ по модулю** — открыть настройки
- **Плавные анимации** — появление, наведение, включение
- **Пустое состояние** — "Ничего не найдено"

## ⚙️ Управление

| Клавиша | Действие |
|---------|----------|
| `RightShift` | Открыть/закрыть меню |
| `ЛКМ` | Включить/выключить модуль |
| `ПКМ` | Открыть настройки модуля |

## 🛠 Структура

```
ManaV2ForRoblox/
├── MainScript.lua      — главный скрипт
├── GuiLibrary.lua      — библиотека GUI (опции, слайдеры, тумблеры)
├── NightixMenu.lua     — НОВОЕ меню в стиле Nightix
├── Universal.lua       — универсальные модули (AimAssist, Reach, ...)
├── playersHandler.lua  — обработчик игроков
├── toolHandler.lua     — обработчик инструментов
├── espLibrary.lua      — ESP библиотека
└── loadstring.lua      — загрузчик
```

## 📝 Credits

- **ManaV2ForRoblox** — Maanaaaa & Wowzers
- **Nightix 1.21.11** — ru.white / Xanax (дизайн, механики меню и иконка)
