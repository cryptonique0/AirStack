import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

const resources = {
  en: {
    translation: {
      welcome: 'Welcome to AirStack!',
      connectWallet: 'Connect Wallet',
      profileSetup: 'Profile Setup',
      firstClaim: 'First Claim',
      exploreDashboard: 'Explore Dashboard',
      next: 'Next',
      back: 'Back',
      finish: 'Finish',
      // ...add more keys as needed
    },
  },
  es: {
    translation: {
      welcome: '¡Bienvenido a AirStack!',
      connectWallet: 'Conectar Billetera',
      profileSetup: 'Configurar Perfil',
      firstClaim: 'Primer Reclamo',
      exploreDashboard: 'Explorar Panel',
      next: 'Siguiente',
      back: 'Atrás',
      finish: 'Finalizar',
      // ...add more keys as needed
    },
  },
};

i18n.use(initReactI18next).init({
  resources,
  lng: 'en',
  fallbackLng: 'en',
  interpolation: { escapeValue: false },
});

export default i18n;
