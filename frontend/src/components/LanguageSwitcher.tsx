import React from 'react';
import { useTranslation } from 'react-i18next';

const LanguageSwitcher: React.FC = () => {
  const { i18n } = useTranslation();
  return (
    <div className="flex gap-2 items-center">
      <span className="text-sm text-gray-500">Language:</span>
      <button
        className={`px-2 py-1 rounded ${i18n.language === 'en' ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}
        onClick={() => i18n.changeLanguage('en')}
      >
        EN
      </button>
      <button
        className={`px-2 py-1 rounded ${i18n.language === 'es' ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}
        onClick={() => i18n.changeLanguage('es')}
      >
        ES
      </button>
    </div>
  );
};

export default LanguageSwitcher;
