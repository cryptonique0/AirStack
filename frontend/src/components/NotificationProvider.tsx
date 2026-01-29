import React, { useEffect, useState } from 'react';
import { io, Socket } from 'socket.io-client';

const NotificationProvider: React.FC<{ userId: string }> = ({ userId, children }) => {
  const [notifications, setNotifications] = useState<string[]>([]);

  useEffect(() => {
    const socket: Socket = io('/', { transports: ['websocket'] });
    socket.emit('subscribe', userId);
    socket.on('notification', (data: { message: string }) => {
      setNotifications((prev) => [data.message, ...prev]);
    });
    return () => { socket.disconnect(); };
  }, [userId]);

  return (
    <div>
      {children}
      <div className="fixed top-4 right-4 z-50 space-y-2">
        {notifications.slice(0, 3).map((msg, idx) => (
          <div key={idx} className="bg-blue-600 text-white px-4 py-2 rounded shadow-lg animate-fade-in">
            {msg}
          </div>
        ))}
      </div>
    </div>
  );
};

export default NotificationProvider;
