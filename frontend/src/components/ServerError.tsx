import React from "react";

const ServerError: React.FC = () => (
  <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50">
    <h1 className="text-6xl font-bold text-red-600 mb-4">500</h1>
    <h2 className="text-2xl font-semibold mb-2">Internal Server Error</h2>
    <p className="text-gray-600 mb-6">Oops! Something went wrong on our end.</p>
    <a href="/" className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Go Home</a>
  </div>
);

export default ServerError;
