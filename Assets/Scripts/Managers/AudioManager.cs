using System.Collections.Generic;
using UnityEngine;

namespace Monopoly.Managers
{
    /// <summary>
    /// Управляет фоновой музыкой и звуковыми эффектами игры.
    /// Создаётся автоматически при старте приложения — не требует размещения в сцене.
    /// </summary>
    public class AudioManager : MonoBehaviour
    {
        private static AudioManager _instance;

        public static AudioManager Instance
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

        [Range(0f, 1f)]
        public float musicVolume = 0.7f;

        [Range(0f, 1f)]
        public float sfxVolume = 1f;

        private AudioSource _musicSource;
        private AudioSource _sfxSource;
        private readonly Dictionary<string, AudioClip> _clipCache = new Dictionary<string, AudioClip>();

        /// <summary>
        /// Гарантированно создаёт единственный экземпляр менеджера до загрузки первой сцены.
        /// </summary>
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void CreateInstance()
        {
            if (_instance != null)
            {
                return;
            }

            var go = new GameObject(nameof(AudioManager));
            _instance = go.AddComponent<AudioManager>();
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

            _musicSource = gameObject.AddComponent<AudioSource>();
            _musicSource.loop = true;
            _musicSource.playOnAwake = false;

            _sfxSource = gameObject.AddComponent<AudioSource>();
            _sfxSource.playOnAwake = false;
        }

        /// <summary>
        /// Проигрывает фоновую музыку темы по кругу. Если клип уже играет, ничего не делает.
        /// </summary>
        public void PlayMusic(AudioClip clip)
        {
            if (clip == null || _musicSource.clip == clip && _musicSource.isPlaying)
            {
                return;
            }

            _musicSource.clip = clip;
            _musicSource.volume = musicVolume;
            _musicSource.Play();
        }

        public void StopMusic()
        {
            _musicSource.Stop();
        }

        /// <summary>
        /// Проигрывает короткий звуковой эффект (кубики, покупка, банкротство и т.д.).
        /// </summary>
        public void PlaySfx(AudioClip clip)
        {
            if (clip == null)
            {
                return;
            }

            _sfxSource.PlayOneShot(clip, sfxVolume);
        }

        public void SetMusicVolume(float volume)
        {
            musicVolume = Mathf.Clamp01(volume);
            if (_musicSource != null)
            {
                _musicSource.volume = musicVolume;
            }
        }

        public void SetSfxVolume(float volume)
        {
            sfxVolume = Mathf.Clamp01(volume);
        }
    }
}
