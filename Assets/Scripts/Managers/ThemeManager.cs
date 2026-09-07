using System;
using System.Collections.Generic;
using System.Linq;
using Monopoly.Core;
using UnityEngine;

namespace Monopoly.Managers
{
    /// <summary>
    /// Загружает доступные темы оформления (GameThemeSO) из папки Resources
    /// и применяет выбранную тему ко всей игре. Новые темы добавляются
    /// простым созданием нового ассета в Assets/Resources/Themes — без изменения кода.
    /// </summary>
    public class ThemeManager : MonoBehaviour
    {
        private const string ThemesResourcesPath = "Themes";

        private static ThemeManager _instance;

        public static ThemeManager Instance
        {
            get
            {
                if (_instance == null)
                {
                    CreateInstance();
                }

                return _instance;
            }
        }

        public event Action<GameThemeSO> OnThemeChanged;

        public GameThemeSO CurrentTheme { get; private set; }
        public IReadOnlyList<GameThemeSO> AvailableThemes { get; private set; } = Array.Empty<GameThemeSO>();

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void CreateInstance()
        {
            if (_instance != null)
            {
                return;
            }

            var go = new GameObject(nameof(ThemeManager));
            _instance = go.AddComponent<ThemeManager>();
            DontDestroyOnLoad(go);
        }

        private void Awake()
        {
            if (_instance != null && _instance != this)
            {
                Destroy(gameObject);
                return;
            }

            _instance = this;
            DontDestroyOnLoad(gameObject);

            LoadAvailableThemes();
        }

        /// <summary>
        /// Загружает все ScriptableObject-темы из Resources/Themes.
        /// </summary>
        private void LoadAvailableThemes()
        {
            var themes = Resources.LoadAll<GameThemeSO>(ThemesResourcesPath);
            AvailableThemes = themes.OrderBy(t => t.themeName).ToList();

            if (AvailableThemes.Count > 0 && CurrentTheme == null)
            {
                ApplyTheme(AvailableThemes[0]);
            }
        }

        /// <summary>
        /// Применяет тему по имени. Возвращает true, если тема найдена и применена.
        /// </summary>
        public bool ApplyThemeByName(string themeName)
        {
            var theme = AvailableThemes.FirstOrDefault(t => t.themeName == themeName);
            if (theme == null)
            {
                Debug.LogWarning($"[ThemeManager] Тема '{themeName}' не найдена.");
                return false;
            }

            ApplyTheme(theme);
            return true;
        }

        /// <summary>
        /// Применяет конкретную тему оформления и уведомляет подписчиков (UI, аудио, поле).
        /// </summary>
        public void ApplyTheme(GameThemeSO theme)
        {
            if (theme == null)
            {
                return;
            }

            CurrentTheme = theme;

            if (theme.themeMusic != null)
            {
                AudioManager.Instance.PlayMusic(theme.themeMusic);
            }

            OnThemeChanged?.Invoke(theme);
            Debug.Log($"[ThemeManager] Применена тема: {theme.themeName}");
        }
    }
}
