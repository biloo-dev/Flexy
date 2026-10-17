import { ref, watch, onMounted } from 'vue';
import { useRtl } from 'vuetify';

export type Language = 'en' | 'ar';
export type Direction = 'ltr' | 'rtl';

const currentLanguage = ref<Language>((localStorage.getItem('flexi_lang') as Language) || 'en');
const isRtl = ref<boolean>(currentLanguage.value === 'ar');

export function useDirection() {
  const vuetifyRtl = useRtl();

  const setLanguage = (lang: Language) => {
    currentLanguage.value = lang;
    isRtl.value = lang === 'ar';
    localStorage.setItem('flexi_lang', lang);
    applyDirection();
  };

  const toggleLanguage = () => {
    setLanguage(currentLanguage.value === 'en' ? 'ar' : 'en');
  };

  const applyDirection = () => {
    const dir: Direction = isRtl.value ? 'rtl' : 'ltr';
    document.documentElement.setAttribute('dir', dir);
    document.documentElement.setAttribute('lang', currentLanguage.value);
    if (vuetifyRtl) {
      vuetifyRtl.isRtl.value = isRtl.value;
    }
  };

  onMounted(() => {
    applyDirection();
  });

  watch(currentLanguage, () => {
    applyDirection();
  });

  return {
    currentLanguage,
    isRtl,
    setLanguage,
    toggleLanguage,
    applyDirection,
  };
}
