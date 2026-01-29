import React from "react";

const NotFound: React.FC = () => (
  <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50">
    <h1 className="text-6xl font-bold text-blue-600 mb-4">404</h1>
    <h2 className="text-2xl font-semibold mb-2">Page Not Found</h2>
    <p className="text-gray-600 mb-6">Sorry, the page you are looking for does not exist.</p>
    <a href="/" className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Go Home</a>
  </div>
);

export default NotFound;
