import { Server } from 'socket.io';

let io: Server | null = null;

export function initNotificationService(server: any) {
  io = new Server(server, {
    cors: { origin: '*' }
  });

  io.on('connection', (socket) => {
    // You can add authentication here
    socket.on('subscribe', (userId: string) => {
      socket.join(userId);
    });
  });
}

export function sendNotification(userId: string, message: string) {
  if (io) {
    io.to(userId).emit('notification', { message });
  }
}
