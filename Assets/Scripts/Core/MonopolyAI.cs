using System;

namespace Monopoly.Core
{
    /// <summary>
    /// Простой искусственный интеллект для управления ботами.
    /// Принимает решения о покупке недвижимости на основе баланса и базовой стратегии.
    /// Не зависит от Unity API, поэтому легко тестируется и расширяется новыми стратегиями.
    /// </summary>
    public class MonopolyAI
    {
        /// <summary>
        /// Уровень "осторожности" ИИ: чем выше, тем больший запас средств бот старается сохранить.
        /// </summary>
        public float CautionFactor { get; set; } = 0.3f;

        private readonly System.Random _random;

        public MonopolyAI(int? randomSeed = null)
        {
            _random = randomSeed.HasValue ? new System.Random(randomSeed.Value) : new System.Random();
        }

        /// <summary>
        /// Решает, стоит ли боту покупать клетку, на которой он остановился.
        /// </summary>
        public bool ShouldPurchaseTile(PlayerData player, PropertyTile tile)
        {
            if (tile == null || player == null)
            {
                return false;
            }

            if (tile.ownerIndex != -1 || tile.price <= 0)
            {
                return false;
            }

            // Бот не тратит деньги, если после покупки останется меньше "неприкосновенного запаса".
            int safetyReserve = (int)(player.balance * CautionFactor);
            bool canAfford = player.balance - tile.price >= safetyReserve;

            return canAfford && player.balance >= tile.price;
        }

        /// <summary>
        /// Выполняет полный ход бота: покупка клетки при необходимости.
        /// Логика перемещения и оплаты аренды остаётся в MonopolyEngine.
        /// </summary>
        public void TakeTurn(MonopolyEngine engine, PlayerData player)
        {
            if (engine == null || player == null)
            {
                return;
            }

            var tile = engine.Board[player.position];
            if (ShouldPurchaseTile(player, tile))
            {
                engine.TryPurchaseCurrentTile(player);
            }
        }

        /// <summary>
        /// Возвращает случайную "фразу" бота для чата/лога — для оживления игрового процесса.
        /// </summary>
        public string GetRandomTaunt()
        {
            string[] phrases =
            {
                "Отличный ход!",
                "Похоже, удача сегодня на моей стороне.",
                "Придётся раскошелиться...",
                "Эта клетка будет моей!",
                "Банкротство мне не грозит."
            };

            int index = _random.Next(phrases.Length);
            return phrases[index];
        }
    }
}
