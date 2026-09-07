using System;
using System.IO;
using UnityEngine;

namespace Monopoly.Managers
{
    /// <summary>
    /// Сериализуемая структура сохранения партии.
    /// </summary>
    [Serializable]
    public class SaveData
    {
        public int savedBalanceSum;
        public int lastTurnNumber;
        public string selectedThemeName = "Классическая";
        public string saveDateIso;
    }

    /// <summary>
    /// Отвечает за сохранение и загрузку прогресса игры в локальный JSON-файл.
    /// Реализован как ленивый синглтон, не требующий размещения в сцене.
    /// </summary>
    public class SaveManager
    {
        private const string SaveFileName = "monopoly_save.json";

        private static SaveManager _instance;
        public static SaveManager Instance => _instance ??= new SaveManager();

        private string SavePath => Path.Combine(Application.persistentDataPath, SaveFileName);

        private SaveManager()
        {
        }

        /// <summary>
        /// Сохраняет данные партии на диск в формате JSON.
        /// </summary>
        public void Save(SaveData data)
        {
            if (data == null)
            {
                throw new ArgumentNullException(nameof(data));
            }

            data.saveDateIso = DateTime.UtcNow.ToString("o");

            try
            {
                string json = JsonUtility.ToJson(data, true);
                File.WriteAllText(SavePath, json);
                Debug.Log($"[SaveManager] Игра сохранена: {SavePath}");
            }
            catch (Exception e)
            {
                Debug.LogError($"[SaveManager] Ошибка сохранения: {e.Message}");
            }
        }

        /// <summary>
        /// Загружает данные партии с диска. Возвращает null, если сохранение отсутствует.
        /// </summary>
        public SaveData Load()
        {
            if (!HasSave())
            {
                return null;
            }

            try
            {
                string json = File.ReadAllText(SavePath);
                return JsonUtility.FromJson<SaveData>(json);
            }
            catch (Exception e)
            {
                Debug.LogError($"[SaveManager] Ошибка загрузки: {e.Message}");
                return null;
            }
        }

        /// <summary>
        /// Проверяет наличие файла сохранения.
        /// </summary>
        public bool HasSave()
        {
            return File.Exists(SavePath);
        }

        /// <summary>
        /// Удаляет файл сохранения, если он существует.
        /// </summary>
        public void DeleteSave()
        {
            if (HasSave())
            {
                File.Delete(SavePath);
            }
        }
    }
}
