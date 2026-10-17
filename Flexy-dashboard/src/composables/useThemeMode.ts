import { ref, computed } from 'vue';
import { useTheme } from 'vuetify';

const savedTheme = localStorage.getItem('flexi_theme') || 'dark';
const currentThemeName = ref<string>(savedTheme);

export function useThemeMode() {
  const theme = useTheme();

  const isDark = computed(() => currentThemeName.value === 'dark');

  const setTheme = (name: 'light' | 'dark') => {
    currentThemeName.value = name;
    theme.global.name.value = name;
    localStorage.setItem('flexi_theme', name);
  };

  const toggleTheme = () => {
    const next = isDark.value ? 'light' : 'dark';
    setTheme(next);
  };

  const initTheme = () => {
    theme.global.name.value = currentThemeName.value;
  };

  return {
    isDark,
    currentThemeName,
    setTheme,
    toggleTheme,
    initTheme,
  };
}
