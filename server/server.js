const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

const path = require('path');
// Serve the web_demo.html from the parent directory
app.get('/demo', (req, res) => {
    res.sendFile(path.join(__dirname, '../web_demo.html'));
});

const PORT = process.env.PORT || 3000;

// Track users in "Frequencies" (Rooms)
const rooms = {};

io.on('connection', (socket) => {
    console.log('User connected:', socket.id);

    socket.on('join-frequency', (frequency) => {
        socket.join(frequency);
        console.log(`User ${socket.id} joined frequency: ${frequency}`);
        
        // Notify others in the room
        socket.to(frequency).emit('user-joined', socket.id);
    });

    // WebRTC Signaling
    socket.on('signal', (data) => {
        // Relay signaling data (offer/answer/ice-candidate) to a specific target or room
        if (data.to) {
            io.to(data.to).emit('signal', {
                from: socket.id,
                signal: data.signal
            });
        } else if (data.frequency) {
            socket.to(data.frequency).emit('signal', {
                from: socket.id,
                signal: data.signal
            });
        }
    });

    // PTT State Broadcast
    socket.on('ptt-start', (frequency) => {
        console.log(`User ${socket.id} is talking on ${frequency}`);
        socket.to(frequency).emit('remote-ptt-start', { userId: socket.id });
    });

    socket.on('ptt-stop', (frequency) => {
        socket.to(frequency).emit('remote-ptt-stop', { userId: socket.id });
    });

    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
});

server.listen(PORT, () => {
    console.log(`FreqTalk Signaling Server running on port ${PORT}`);
});
