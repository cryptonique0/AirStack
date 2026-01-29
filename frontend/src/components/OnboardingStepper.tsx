import React, { useState } from "react";

const steps = [
  { title: "Connect Wallet", description: "Securely connect your wallet to get started." },
  { title: "Profile Setup", description: "Set your display name and preferences." },
  { title: "First Claim", description: "Claim your first airdrop or test token." },
  { title: "Explore Dashboard", description: "View analytics and manage your campaigns." }
];

const OnboardingStepper: React.FC = () => {
  const [activeStep, setActiveStep] = useState(0);

  const nextStep = () => setActiveStep((s) => Math.min(s + 1, steps.length - 1));
  const prevStep = () => setActiveStep((s) => Math.max(s - 1, 0));

  return (
    <div className="max-w-xl mx-auto p-6 bg-white rounded-lg shadow-md">
      <h2 className="text-2xl font-bold mb-4">Welcome to AirStack!</h2>
      <ol className="mb-6">
        {steps.map((step, idx) => (
          <li key={step.title} className={`mb-2 flex items-center ${idx === activeStep ? 'font-bold text-blue-600' : 'text-gray-500'}`}> 
            <span className={`mr-2 w-6 h-6 flex items-center justify-center rounded-full border-2 ${idx === activeStep ? 'border-blue-600 bg-blue-100' : 'border-gray-300 bg-gray-100'}`}>{idx + 1}</span>
            <span>{step.title}</span>
            <span className="ml-2 text-xs text-gray-400">{step.description}</span>
          </li>
        ))}
      </ol>
      <div className="flex justify-between">
        <button onClick={prevStep} disabled={activeStep === 0} className="px-4 py-2 bg-gray-200 rounded disabled:opacity-50">Back</button>
        {activeStep < steps.length - 1 ? (
          <button onClick={nextStep} className="px-4 py-2 bg-blue-600 text-white rounded">Next</button>
        ) : (
          <button className="px-4 py-2 bg-green-600 text-white rounded">Finish</button>
        )}
      </div>
    </div>
  );
};

export default OnboardingStepper;
