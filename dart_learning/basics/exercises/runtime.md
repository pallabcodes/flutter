Here’s a list of values in Flutter (Dart) and JavaScript (JS) that are typically determined at runtime:

Flutter (Dart)
Date and Time

DateTime.now()
DateTime.parse(dynamicString)
Duration values based on user input or calculations.
Random Values

Random().nextInt(n)
Random().nextDouble()
User Input

stdin.readLineSync() (for console apps)
User interactions in Flutter widgets (e.g., TextField input).
API Calls

Results from http.get() or http.post().
Async functions like Future or Stream.
Environment Variables

Values fetched using Platform.environment.
File System

File contents read using File.readAsString().
Directory listings using Directory.
Device Information

Screen size (MediaQuery).
Device orientation (MediaQuery.of(context).orientation).
Platform-specific details (Platform.isAndroid, Platform.isIOS).
Database Queries

Results from SQLite or Firebase queries.
Dynamic Collections

Lists or maps populated at runtime (e.g., List.generate() with dynamic data).
Network State

Connectivity status using connectivity_plus package.
JavaScript
Date and Time

new Date()
Date.now()
Date.parse(dynamicString)
Random Values

Math.random()
Randomized arrays or objects.
User Input

prompt() (browser-based).
Event listeners (e.g., onClick, onChange).
API Calls

Results from fetch() or axios.get().
Environment Variables

process.env (Node.js).
Browser-specific environment variables.
File System

File contents read using fs.readFileSync() (Node.js).
File uploads in the browser.
DOM State

Element properties like document.getElementById('id').value.
Dynamic styles or attributes.
Device Information

Screen size (window.innerWidth, window.innerHeight).
User agent (navigator.userAgent).
Dynamic Collections

Arrays or objects populated at runtime (e.g., Array.from() with dynamic data).
Network State

Online/offline status (navigator.onLine).
Network speed or latency checks.
Key Observations
Both Dart and JS share many runtime-determined values, especially for date/time, randomness, user input, and API calls.
Dart has more structured APIs for device and platform-specific data (e.g., Platform, MediaQuery).
JS relies heavily on browser or Node.js-specific APIs for runtime values.