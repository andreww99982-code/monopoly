using System;
using System.Collections.Generic;
using UnityEngine;

namespace Monopoly.UI
{
    /// <summary>
    /// Перечень экранов пользовательского интерфейса, доступных в игре.
    /// При добавлении нового экрана достаточно расширить это перечисление.
    /// </summary>
    public enum UIScreen
    {
        MainMenu,
        Game,
        Settings,
        Pause,
        GameOver
    }

    /// <summary>
    /// Централизованно управляет переключением экранов интерфейса.
    /// Экранные панели регистрируются во время выполнения (например, из своих Awake),
    /// что позволяет добавлять новые сцены/панели без правки этого класса.
    /// </summary>
    public class UIManager : MonoBehaviour
    {
        private static UIManager _instance;

        public static UIManager Instance
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

        public event Action<UIScreen> OnScreenChanged;

        public UIScreen CurrentScreen { get; private set; } = UIScreen.MainMenu;

        private readonly Dictionary<UIScreen, GameObject> _registeredPanels = new Dictionary<UIScreen, GameObject>();

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void CreateInstance()
        {
            if (_instance != null)
            {
                return;
            }

            var go = new GameObject(nameof(UIManager));
            _instance = go.AddComponent<UIManager>();
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
        }

        /// <summary>
        /// Регистрирует корневой GameObject панели для указанного экрана.
        /// Панели сцены должны вызывать этот метод из своего Awake/Start.
        /// </summary>
        public void RegisterPanel(UIScreen screen, GameObject panelRoot)
        {
            if (panelRoot == null)
            {
                return;
            }

            _registeredPanels[screen] = panelRoot;

            // Скрываем панель по умолчанию, если она не является активным экраном.
            panelRoot.SetActive(screen == CurrentScreen);
        }

        /// <summary>
        /// Снимает регистрацию панели (например, при выгрузке сцены).
        /// </summary>
        public void UnregisterPanel(UIScreen screen)
        {
            _registeredPanels.Remove(screen);
        }

        /// <summary>
        /// Переключает видимый экран интерфейса, скрывая предыдущий.
        /// </summary>
        public void ShowScreen(UIScreen screen)
        {
            if (_registeredPanels.TryGetValue(CurrentScreen, out var previousPanel) && previousPanel != null)
            {
                previousPanel.SetActive(false);
            }

            CurrentScreen = screen;

            if (_registeredPanels.TryGetValue(screen, out var nextPanel) && nextPanel != null)
            {
                nextPanel.SetActive(true);
            }

            OnScreenChanged?.Invoke(screen);
            Debug.Log($"[UIManager] Переключение на экран: {screen}");
        }
    }
}
