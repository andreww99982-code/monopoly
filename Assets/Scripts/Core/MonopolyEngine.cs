using System;
using System.Collections.Generic;

namespace Monopoly.Core
{
    /// <summary>
    /// Данные одного игрока в партии.
    /// </summary>
    [Serializable]
    public class PlayerData
    {
        public string playerName;
        public int balance;
        public int position;
        public bool isBankrupt;
        public bool isAI;
        public List<int> ownedProperties = new List<int>();

        public PlayerData(string name, int startBalance, bool ai = false)
        {
            playerName = name;
            balance = startBalance;
            position = 0;
            isBankrupt = false;
            isAI = ai;
            ownedProperties = new List<int>();
        }
    }

    /// <summary>
    /// Данные одной клетки игрового поля.
    /// </summary>
    [Serializable]
    public class PropertyTile
    {
        public string tileName;
        public int price;
        public int rent;
        public int ownerIndex = -1; // -1 означает, что клетка свободна

        public PropertyTile(string name, int price, int rent)
        {
            tileName = name;
            this.price = price;
            this.rent = rent;
            ownerIndex = -1;
        }
    }

    /// <summary>
    /// Центральный игровой движок «Монополии»: хранит состояние партии,
    /// обрабатывает ходы, броски кубиков, покупку и оплату аренды.
    /// Не зависит от UI и может использоваться в тестах или на сервере.
    /// </summary>
    public class MonopolyEngine
    {
        public event Action<PlayerData> OnPlayerMoved;
        public event Action<PlayerData, PropertyTile> OnPropertyPurchased;
        public event Action<PlayerData, PlayerData, int> OnRentPaid;
        public event Action<PlayerData> OnPlayerBankrupt;
        public event Action<PlayerData> OnGameWon;
        public event Action OnTurnChanged;

        public List<PlayerData> Players { get; private set; } = new List<PlayerData>();
        public List<PropertyTile> Board { get; private set; } = new List<PropertyTile>();

        public int CurrentPlayerIndex { get; private set; }
        public int TurnNumber { get; private set; }

        private const int StartingBalance = 1500;
        private System.Random _random;

        public MonopolyEngine(int boardSize = 24, int? randomSeed = null)
        {
            _random = randomSeed.HasValue ? new System.Random(randomSeed.Value) : new System.Random();
            GenerateBoard(boardSize);
        }

        /// <summary>
        /// Создаёт упрощённое игровое поле из заданного количества клеток.
        /// </summary>
        private void GenerateBoard(int boardSize)
        {
            Board = new List<PropertyTile>(boardSize);
            for (int i = 0; i < boardSize; i++)
            {
                if (i == 0)
                {
                    Board.Add(new PropertyTile("Старт", 0, 0));
                    continue;
                }

                int basePrice = 60 + (i * 20);
                int rent = basePrice / 10;
                Board.Add(new PropertyTile($"Улица {i}", basePrice, rent));
            }
        }

        /// <summary>
        /// Добавляет нового игрока (человека или ИИ) в партию.
        /// </summary>
        public PlayerData AddPlayer(string name, bool isAI = false)
        {
            var player = new PlayerData(name, StartingBalance, isAI);
            Players.Add(player);
            return player;
        }

        /// <summary>
        /// Бросает два кубика и возвращает сумму выпавших очков.
        /// </summary>
        public int RollDice()
        {
            int d1 = _random.Next(1, 7);
            int d2 = _random.Next(1, 7);
            return d1 + d2;
        }

        /// <summary>
        /// Выполняет ход текущего игрока: перемещение по полю и обработку клетки.
        /// </summary>
        public void PlayTurn()
        {
            if (Players.Count == 0)
            {
                return;
            }

            var player = Players[CurrentPlayerIndex];
            if (player.isBankrupt)
            {
                AdvanceTurn();
                return;
            }

            int steps = RollDice();
            MovePlayer(player, steps);
            ResolveTile(player);

            TurnNumber++;
            OnTurnChanged?.Invoke();
            AdvanceTurn();
            CheckForWinner();
        }

        private void MovePlayer(PlayerData player, int steps)
        {
            int boardSize = Board.Count;
            int newPosition = (player.position + steps) % boardSize;

            // Круг пройден — начисляем бонус за прохождение старта.
            if (newPosition < player.position)
            {
                player.balance += 200;
            }

            player.position = newPosition;
            OnPlayerMoved?.Invoke(player);
        }

        private void ResolveTile(PlayerData player)
        {
            var tile = Board[player.position];
            if (tile.price <= 0)
            {
                return; // Клетка "Старт" или служебная — ничего не делаем.
            }

            if (tile.ownerIndex == -1)
            {
                return; // Свободная клетка, решение о покупке принимает вызывающий код (игрок/ИИ).
            }

            if (tile.ownerIndex == Players.IndexOf(player))
            {
                return; // Игрок стоит на собственной клетке.
            }

            var owner = Players[tile.ownerIndex];
            PayRent(player, owner, tile);
        }

        /// <summary>
        /// Пытается купить клетку, на которой стоит игрок. Возвращает true при успехе.
        /// </summary>
        public bool TryPurchaseCurrentTile(PlayerData player)
        {
            var tile = Board[player.position];
            if (tile.ownerIndex != -1 || tile.price <= 0)
            {
                return false;
            }

            if (player.balance < tile.price)
            {
                return false;
            }

            player.balance -= tile.price;
            tile.ownerIndex = Players.IndexOf(player);
            player.ownedProperties.Add(player.position);

            OnPropertyPurchased?.Invoke(player, tile);
            return true;
        }

        private void PayRent(PlayerData payer, PlayerData owner, PropertyTile tile)
        {
            int amount = Math.Min(tile.rent, payer.balance);
            payer.balance -= amount;
            owner.balance += amount;

            OnRentPaid?.Invoke(payer, owner, amount);

            if (payer.balance <= 0)
            {
                DeclareBankrupt(payer);
            }
        }

        private void DeclareBankrupt(PlayerData player)
        {
            player.isBankrupt = true;

            // Освобождаем все клетки, принадлежавшие игроку.
            foreach (var tile in Board)
            {
                if (tile.ownerIndex == Players.IndexOf(player))
                {
                    tile.ownerIndex = -1;
                }
            }

            OnPlayerBankrupt?.Invoke(player);
        }

        private void AdvanceTurn()
        {
            if (Players.Count == 0)
            {
                return;
            }

            int attempts = 0;
            do
            {
                CurrentPlayerIndex = (CurrentPlayerIndex + 1) % Players.Count;
                attempts++;
            }
            while (Players[CurrentPlayerIndex].isBankrupt && attempts < Players.Count);
        }

        private void CheckForWinner()
        {
            PlayerData last = null;
            int aliveCount = 0;

            foreach (var player in Players)
            {
                if (!player.isBankrupt)
                {
                    aliveCount++;
                    last = player;
                }
            }

            if (aliveCount == 1 && Players.Count > 1)
            {
                OnGameWon?.Invoke(last);
            }
        }
    }
}
