using UnityEngine;

namespace Monopoly.Core
{
    /// <summary>
    /// ScriptableObject-описание визуальной темы игры (цвета, шрифты, названия).
    /// Позволяет добавлять новые темы без изменения кода — достаточно создать новый ассет.
    /// </summary>
    [CreateAssetMenu(fileName = "НоваяТема", menuName = "Монополия/Тема оформления", order = 0)]
    public class GameThemeSO : ScriptableObject
    {
        [Header("Общая информация")]
        [Tooltip("Отображаемое название темы, видимое игроку")]
        public string themeName = "Классическая";

        [TextArea]
        [Tooltip("Краткое описание темы для экрана выбора")]
        public string description = "Стандартная тема оформления игры.";

        [Header("Цветовая палитра")]
        public Color primaryColor = Color.white;
        public Color secondaryColor = Color.gray;
        public Color accentColor = Color.yellow;
        public Color boardBackgroundColor = Color.green;
        public Color textColor = Color.black;

        [Header("Игровые обозначения")]
        [Tooltip("Название игровой валюты, например 'руб.' или 'кредиты'")]
        public string currencyName = "руб.";

        [Header("Визуальные ресурсы (необязательно)")]
        public Sprite boardBackground;
        public Sprite diceSprite;
        public AudioClip themeMusic;

        /// <summary>
        /// Форматирует денежную сумму согласно оформлению темы.
        /// </summary>
        public string FormatCurrency(int amount)
        {
            return $"{amount} {currencyName}";
        }
    }
}
