import 'vuetify/styles';
import '@mdi/font/css/materialdesignicons.css';
import { createVuetify } from 'vuetify';
import * as components from 'vuetify/components';
import * as directives from 'vuetify/directives';
import { lightTheme, darkTheme } from '@/theme';

const savedTheme = localStorage.getItem('flexi_theme') || 'dark';
const savedLang = localStorage.getItem('flexi_lang') || 'en';

export const vuetify = createVuetify({
  components,
  directives,
  locale: {
    locale: savedLang,
    fallback: 'en',
    rtl: {
      ar: true,
      en: false,
    },
  },
  theme: {
    defaultTheme: savedTheme,
    themes: {
      light: lightTheme,
      dark: darkTheme,
    },
  },
  defaults: {
    VCard: {
      elevation: 0,
      rounded: 'lg',
      class: 'border-thin',
    },
    VBtn: {
      rounded: 'md',
      elevation: 0,
      style: 'text-transform: none; font-weight: 600; letter-spacing: normal;',
    },
    VTextField: {
      variant: 'outlined',
      density: 'comfortable',
      hideDetails: 'auto',
    },
    VSelect: {
      variant: 'outlined',
      density: 'comfortable',
      hideDetails: 'auto',
    },
    VChip: {
      size: 'small',
      rounded: 'md',
      elevation: 0,
    },
  },
});

export default vuetify;
