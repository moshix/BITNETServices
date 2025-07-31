TECHNICAL DOCUMENTATION: TSU (Forum3270) CHAT SYSTEM ARCHITECTURE
========================================================

(c) Moshix 2025 
v1.12 - July 2025

This docmuent provides a comprhensive technical overview of the TSU chat system implementation, 
covering its multi-user architecture, threading model, synchronization mechanisms, and key 
code components.

## 1. SYSTEM OVERVIEW

The TSU (forum3270) chat system is a real-time, multi-user messaging system designed for 3270 terminals. 
It supports multiple concurrent users in a global chat room with live message 
distribution, user presence tracking, and realtime screen updates.

It uses of goroutines, channels, and careful synchronization to provide a robust and scalable chat system, 
indepentely on the connection client, ie 3270 or ssh (which is also supported!). 

Key architectural strengths:
- Clear separation between data layer (models/chat.go) and presentation (chat.go)
- Robust error handling and resource cleanup
- Scalable publisher-subscriber pattern
- Adaptive UI layout support
- Thread-safe operations through-out

### Key Features:
- Realtime message broadcasting to all connected users
- Thread-safe connection management
- Background message polling and distribution
- Live user list updates
- Support for both 24x80 and 43x80 terminal layouts
- Automatic cleanup of disconnected users
- Message persistence in SQLite database

## 2. CORE ARCHITECTURE COMPONENTS

### 2.1 LiveChat Manager (models/chat.go)

The LiveChat structure is the central coordinator for all chat operations:

     type LiveChat struct {
         activeUsers   map[int64]*ChatUser      // Currently active users
         subscribers   map[int64][]chan ChatMessage  // User subscription channels
         mu            sync.RWMutex             // Reader-writer mutex for thread safety
         stopPoller    chan struct{}            // Signal channel to stop polling
         isPolling     bool                     // Polling state flag
         pollerMu      sync.Mutex              // Mutex for polling state
         lastMessageID int64                   // Last processed message ID
     }

This structure manages:
- **Active Users**: Maps user IDs to ChatUser structs containing user information
- **Subscribers**: Maps user IDs to arrays of channels for message distribution
- **Thread Safety**: Uses RWMutex to allow concurrent reads while protecting writes
- **Message Polling**: Tracks the last processed message ID for efficient polling

### 2.2 Connection Management (chat.go)

The system uses a thread-safe connection wrapper to prevent race codnitions:

     type safeConn struct {
         conn net.Conn
         mu   sync.Mutex
     }

     func (sc *safeConn) Write(b []byte) (n int, err error) {
         sc.mu.Lock()
         defer sc.mu.Unlock()
         return sc.conn.Write(b)
     }

A global connection map tracks all active chat connections:

     type chatConnectionMap struct {
         connections map[int64]net.Conn
         mu          sync.RWMutex
     }

     var globalChatConnections = &chatConnectionMap{
         connections: make(map[int64]net.Conn),
     }

### 2.3 Message Structure

Mesages use a standardized format for both database storage and in-memory handling:

     type ChatMessage struct {
         ID        int64
         UserID    int64
         Username  string
         Content   string
         Timestamp time.Time
         RoomID    string
     }

## 3. MULTI-USER COORDINATION

### 3.1 User Registration and Management

When a user enters chat, the system performs several registration steps:

     func (s *session) chat(conn net.Conn, dev go3270.DevInfo, data any) (go3270.Tx, any, error) {
         // Wrap connection for thread safety
         safeConnection := &safeConn{conn: conn}
         
         // Register user in chat manager
         s.global.chatManager.JoinChat(s.user.ID, s.user.Username)
         globalChatConnections.addUser(s.user.ID, conn)
         
         // Subscribe to message updates
         updateChan := s.global.chatManager.Subscribe(s.user.ID)
         
         defer func() {
             s.global.chatManager.LeaveChat(s.user.ID)
             globalChatConnections.removeUser(s.user.ID)
             s.global.chatManager.Unsubscribe(s.user.ID, updateChan)
         }()
     }

### 3.2 Message Broadcasting Mechanism

The system uses a publisher/subscriber pattern for message distriution:

     func (lc *LiveChat) Subscribe(userID int64) chan ChatMessage {
         lc.mu.Lock()
         defer lc.mu.Unlock()
         
         ch := make(chan ChatMessage, 10) // Buffered channel prevents blocking
         lc.subscribers[userID] = append(lc.subscribers[userID], ch)
         return ch
     }

     func (lc *LiveChat) Broadcast(message ChatMessage) {
         lc.mu.RLock()
         defer lc.mu.RUnlock()
         
         for _, subs := range lc.subscribers {
             for _, ch := range subs {
                 select {
                 case ch <- message:
                     // Message sent successfully
                 default:
                     // Channel full, skip to prevent blocking entire broadcast
                 }
             }
         }
     }

This design ensures that:
- Each user gets their own buffered channel (10 message capacity)
- Slow consumers don't block the entire system
- Messages are distributed to all active subscribers simultaneously

## 4. THREADING MODEL

The chat system employs a sophisticated multi-threaded architecture:

### 4.1 Main Chat Thread

Each user's chat session runs in the main thread, handling:
- User input processing
- Screen rendering with user input
- Message composition and sending
- Function key handling (F3=Exit, etc.)

### 4.2 Background Update Thread

Each user also has a dedicated backgound thread (`chatUpdateThread`) that handles:

     func (s *session) chatUpdateThread(conn *safeConn, done chan struct{}, 
         backgroundComplete chan struct{}, updateChan chan models.ChatMessage, 
         initialMessages []ChatMessage, layout chatScreenLayout, dev go3270.DevInfo) {
         
         defer close(backgroundComplete)
         
         // Multiple tickers for different update frequencies
         userListTicker := time.NewTicker(1 * time.Second)
         clockTicker := time.NewTicker(1 * time.Second)
         defer userListTicker.Stop()
         defer clockTicker.Stop()
         
         for {
             select {
             case <-done:
                 return // User exiting chat
                 
             case <-clockTicker.C:
                 // Update clock display
                 
             case <-userListTicker.C:
                 // Update user list if changed
                 
             case msg := <-updateChan:
                 // Process new incoming message
                 // Update message history
                 // Redraw chat area without clearing screen
             }
         }
     }

### 4.3 Global Message Polling Thread

A single system-wide thread polls the database for new messages:

     func (lc *LiveChat) pollForNewMessages(interval time.Duration) {
         ticker := time.NewTicker(interval)
         defer ticker.Stop()
         
         for {
             select {
             case <-lc.stopPoller:
                 return
             case <-ticker.C:
                 lc.checkForNewMessages()
             }
         }
     }

This thread:
- Queries teh  database every 2 seconds (configurable)
- Checks for messages with ID > lastMessageID
- Broadcasts new messages to all subscribers
- Updates the lastMessageID tracker

## 5. SYNCHRONIZATION MECHANISMS

### 5.1 Reader-Writer Locks

The system uses `sync.RWMutex` for    the LiveChat manager to allow:
- Multiple concurrent readers (checking user lists, broadcasting messages)
- Exclusive writers (adding/removing users, modifying subscriptions)

     func (lc *LiveChat) GetActiveChatUsers(hasActiveConnection func(int64) bool) []ChatUser {
         lc.mu.RLock()  // Multiple readers allowed
         defer lc.mu.RUnlock()
         // ... read operations
     }

     func (lc *LiveChat) JoinChat(userID int64, username string) {
         lc.mu.Lock()   // Exclusive write access
         defer lc.mu.Unlock()
         // ... modify activeUsers map
     }

### 5.2 Channel-Based Communication

Channels provide thread-safe communication between components:
- **updateChan**: Delivers new messages from poller to user threads
- **done**: Signals background threads to terminate
- **backgroundComplete**: Confirms background thread cleanup

### 5.3 Connection Validation

The system periodically validates connections to detect disconnected users:

     func (ccm *chatConnectionMap) hasValidConnection(userID int64) bool {
         conn, exists := ccm.connections[userID]
         if !exists {
             return false
         }
         
         // Test connection with zero-byte write and short timeout
         conn.SetWriteDeadline(time.Now().Add(100 * time.Millisecond))
         defer conn.SetWriteDeadline(time.Time{})
         
         _, err := conn.Write([]byte{})
         return err == nil
     }

## 6. MESSAGE FLOW ARCHITECTURE

### 6.1 Sending Messages

When a user sends a message:

1. **Input Processing**: Main thread captures user input
2. **Database Storage**: Message stored via `PostChatMessage()`
3. **Polling Detection**: Global poller detects new message in database
4. **Broadcasting**: Message broadcast to all user channels
5. **Screen Updates**: Each user's background thread updates their display

     // User sends message (main thread)
     _, err := models.PostChatMessage(s.user.ID, msg)

     // Global poller detects and broadcasts (polling thread)
     func (lc *LiveChat) checkForNewMessages() {
         // Query for messages with ID > lastMessageID
         // For each new message: lc.Broadcast(msg)
     }

     // User receives message (background thread)
     case msg := <-updateChan:
         // Add to message history
         // Redraw chat area

### 6.2 Real-Time Updates

The background update thread handles three types of real-time updates:

1. **Clock Updates**: Every second, updates time display
2. **User List Updates**: Every second, checks for user list changes
3. **Message Updates**: Immediately when new messages arrive via channel

All updates use `go3270.ShowScreenOpts` with `NoClear: true` and `NoResponse: true`
to update specific screen areas without disrupting user input.

## 7. SCREEN LAYOUT MANAGEMENT

The system supports adaptive layouts based on terminal capabilities:

     func getScreenLayout(dev go3270.DevInfo) chatScreenLayout {
         rows, cols := dev.AltDimensions()
         
         if rows >= 43 && cols >= 80 {
             return chatScreenLayout{
                 firstRow:   2,
                 chatLines:  37,  // More message lines on large screens
                 inputRow:   40,
                 errorRow:   41,
                 legendRow:  42,
             }
         }
         
         // Standard 24x80 layout
         return chatScreenLayout{
             firstRow:   2,
             chatLines:  18,
             inputRow:   21,
             errorRow:   22,
             legendRow:  23,
         }
     }

## 8. GO3270 SCREEN PRESERVATION TECHNIQUES

The chat system employs a sophisticated screen update mechanisms using the go3270 library to 
ensure that user input is never lost during real-time updates. This is achieved through 
careful use of the `ShowScreenOpts` function with specific options that control screen 
behavior.

### 8.1 Dual Screen Update Modes

The system uses two distinct screen update approaches:

#### Full Screen Updates (Main Thread)
When waiting for user input or initially displaying the screen:

     resp, err = go3270.ShowScreenOpts(currentScreen, prePopulatedValues, safeConnection,
         go3270.ScreenOpts{
             CursorRow:  cursorRow,
             CursorCol:  cursorCol,
             NoResponse: false, // Wait for user input
             NoClear:    false, // Allow full screen clearing/redraw
             AltScreen:  dev,   // Support for large screens
         })

#### Partial Screen Updates (Background Thread)
When updating specific screen areas (clock, user list, messages):

     screenOpts := go3270.ScreenOpts{
         NoResponse: true,  // Don't wait for input
         NoClear:    true,  // Don't clear existing screen content
     }
     if layout.screenRows > 24 {
         screenOpts.AltScreen = dev  // Large screen support
     }
     _, err := go3270.ShowScreenOpts(messageScreen, nil, conn, screenOpts)

### 8.2 Key go3270 Options for Input Preservation

#### NoResponse Flag
- **true**: Screen update is send-only, doesn't wait for user input
- **false**: Screen update waits for user response (Enter, function keys, etc.)

The background update thread uses `NoResponse: true` to send updates without interrupting 
the user's typing or waiting for input.

#### NoClear Flag  
- **true**: Preserves existing screen content, only updates specified fields
- **false**: Clears the entire screen before rendering new content

The background thread uses `NoClear: true` to update only the message area, user list, 
and clock while preserving the input field where the user may be typing.

#### AltScreen Support
For terminals supporting larger than 24x80 dimensions:

     if layout.screenRows > 24 {
         screenOpts.AltScreen = dev
     }

This ensures proper screen handling on larger terminals while maintaining the same 
input preservation behavior.

### 8.3 Targeted Screen Updates

Background updates target specific screen areas without affecting the input field:

     // Clock update - only updates time display
     clockScreen := go3270.Screen{
         {Row: 0, Col: 55, Content: time.Now().In(userTZ).Format("15:04:05"), 
          Color: go3270.Turquoise},
     }

     // Message update - updates message area and user list
     messageScreen := go3270.Screen{
         {Row: 0, Col: 35, Intense: true, Content: "Live Chat"},
         {Row: 0, Col: 55, Content: timeString, Color: go3270.Turquoise},
         {Row: 1, Col: 0, Content: userListLine, Color: go3270.Green},
         // ... message fields for rows 2-19 or 2-38
     }

These updates specifically avoid touching the input row (21 for 24x80, 40 for 43x80) 
where the user's current message is displayed.

### 8.4 Input Field State Management

The main thread preserves user input across screen refreshes using pre-populated values:

     var prePopulatedValues map[string]string
     if spellCheckState.Active && currentMessage != "" {
         prePopulatedValues = map[string]string{
             chatInputField: currentMessage,
         }
     }

This ensures that if the main thread needs to redraw the entire screen (such as during 
spell checking or error display), the user's partially typed message is restored.

### 8.5 Cursor Position Management

The system carefully manages cursor positioning to maintain user experience:

     cursorRow := layout.inputRow
     cursorCol := 16 // Default position at start of input field
     if spellCheckState.Active && currentMessage != "" {
         // Position cursor at the end of the current message
         cursorCol = 15 + len(currentMessage) + 1
         if cursorCol > 77 { // Prevent cursor from going beyond field boundary
             cursorCol = 77
         }
     }

This ensures that when the screen is redrawn, the cursor appears in the correct position 
within the user's message.

### 8.6 Thread Coordination Benefits

This dual-mode approach provides several key benefits:

- **Uninterrupted Typing**: Users can continue typing while receiving real-time updates
- **No Data Loss**: Partially composed messages are never lost during screen updates  
- **Responsive Interface**: Clock and message updates appear immediately without lag
- **Proper Error Handling**: Connection errors are detected without affecting input state
- **Terminal Compatibility**: Works correctly on both standard and large screen terminals

The combination of `NoResponse: true` and `NoClear: true` in background updates is the 
key technical mechanism that enables seamless real-time chat functionality while 
preserving user input integrity.

## 9. ERROR HANDLING AND CLEANUP

### 9.1 Connection Error Handling

Background threads monitor for connection errors and exit gracefully:

     _, err := go3270.ShowScreenOpts(messageScreen, nil, conn, screenOpts)
     if err != nil {
         slog.Error("error sending update screen - connection lost",
             "username", s.user.Username,
             "ip", conn.RemoteAddr(),
             "error", err)
         return // Exit background thread
     }

### 9.2 Resource Cleanup

The system ensures proper cleanup when users disconnect:

     defer func() {
         close(done)  // Signal background thread to stop
         
         select {
         case <-backgroundComplete:
             // Background thread finished cleanly
         case <-time.After(2 * time.Second):
             // Timeout - log warning but don't hang
             slog.Warn("chat background thread cleanup timeout")
         }
     }()

### 9.3 Automatic User Cleanup

The system automatically removes disconnected users:

     func (lc *LiveChat) CleanupDisconnectedUsers(hasActiveConnection func(int64) bool) {
         lc.mu.Lock()
         defer lc.mu.Unlock()
         
         for userID := range lc.activeUsers {
             if !hasActiveConnection(userID) {
                 delete(lc.activeUsers, userID)
                 
                 // Close all subscription channels for this user
                 if subs, exists := lc.subscribers[userID]; exists {
                     for _, ch := range subs {
                         close(ch)
                     }
                     delete(lc.subscribers, userID)
                 }
             }
         }
     }

## 10. DATABASE INTEGRATION

Messages are persisted in SQLite with the following schema:
- `chat.message_id`: Auto-incrementing primary key
- `chat.user_id`: Foreign key to users table
- `chat.message`: Message content
- `chat.room_id`: Room identifier ('global' for main chat)
- `chat.created_at`: Timestamp

The polling mechanism uses message_id for efficient incremental queries:

     SELECT c.message_id, c.user_id, u.username, c.message, c.created_at, c.room_id
     FROM chat c
     JOIN users u ON c.user_id = u.user_id
     WHERE (c.room_id = 'global' OR c.room_id = '' OR c.room_id IS NULL)
     AND c.message_id > ?
     ORDER BY c.created_at ASC

## 11. PERFORMANCE CHARACTERISTICS

### 11.1 Scalability Features

- **Buffered Channels**: Prevent slow consumers from blocking the system
- **Incremental Polling**: Only queries for new messages since last check
- **Non-blocking Broadcasts**: Uses select with default to skip full channels
- **Connection Validation**: Removes dead connections to prevent resource leaks

### 11.2 Resource Management

- **Connection Pooling**: Reuses database connections
- **Goroutine Cleanup**: Ensures all background threads terminate properly
- **Memory Management**: Limits message history to screen capacity
- **Timeout Handling**: Prevents hanging operations during cleanup

## 12. CONCLUSION

The TSU chat system demonstrates a robust, scalable architecture for real-time 
multi-user communication. Its use of goroutines, channels, and careful synchronization 
provides excellent performance while maintaining thread safety. The separation of 
concerns between message persistence, distribution, and presentation allows for 
maintainable and extensible code.

