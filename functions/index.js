const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * One-time migration function to add shortId to existing reels
 * Visit: https://us-central1-skill-connect-9d6b3.cloudfunctions.net/migrateReels
 */
exports.migrateReels = onRequest(async (req, res) => {
    try {
        console.log('Starting reel migration...');
        
        // Get all reels without shortId
        const snapshot = await admin.firestore()
            .collection('reels')
            .get();

        const batch = admin.firestore().batch();
        let migratedCount = 0;
        let skippedCount = 0;

        snapshot.docs.forEach(doc => {
            const data = doc.data();
            
            // Skip if already has shortId
            if (data.shortId) {
                skippedCount++;
                return;
            }

            const videoUrl = data.videoUrl;
            if (!videoUrl) {
                console.log('Skipping reel without videoUrl:', doc.id);
                skippedCount++;
                return;
            }

            try {
                // Extract shortId from URL
                const url = new URL(videoUrl);
                const filename = url.pathname.split('/').pop();
                const uuid = filename.replace('.mp4', '').replace('.mov', '');
                const shortId = uuid.split('-')[0];

                console.log(`Migrating reel ${doc.id}: shortId = ${shortId}`);
                batch.update(doc.ref, { shortId });
                migratedCount++;
            } catch (error) {
                console.error(`Error processing reel ${doc.id}:`, error);
                skippedCount++;
            }
        });

        await batch.commit();
        
        const result = {
            success: true,
            migrated: migratedCount,
            skipped: skippedCount,
            total: snapshot.docs.length
        };
        
        console.log('Migration complete:', result);
        
        res.send(`
            <!DOCTYPE html>
            <html>
            <head>
                <title>Migration Complete</title>
                <style>
                    body { font-family: Arial, sans-serif; padding: 50px; }
                    .success { color: #4caf50; }
                    .info { color: #2196f3; }
                </style>
            </head>
            <body>
                <h1 class="success">✅ Migration Complete!</h1>
                <p class="info">Migrated: ${migratedCount} reels</p>
                <p class="info">Skipped: ${skippedCount} reels</p>
                <p class="info">Total: ${snapshot.docs.length} reels</p>
                <p>All reels now have shortId fields!</p>
            </body>
            </html>
        `);
    } catch (error) {
        console.error('Migration error:', error);
        res.status(500).send(`
            <!DOCTYPE html>
            <html>
            <head>
                <title>Migration Failed</title>
                <style>
                    body { font-family: Arial, sans-serif; padding: 50px; }
                    .error { color: #f44336; }
                </style>
            </head>
            <body>
                <h1 class="error">❌ Migration Failed</h1>
                <p>Error: ${error.message}</p>
            </body>
            </html>
        `);
    }
});

/**
 * Cloud Function that redirects short reel URLs to actual GCS video URLs
 * For browser requests, serves an HTML page with app install prompt
 * For app requests, redirects to the video URL
 * Example: /reels/abc123 -> https://storage.googleapis.com/skillconnect-storage/vendor_reels/abc123-....mp4
 */
exports.reelRedirect = onRequest(async (req, res) => {
    try {
        // Extract short ID from path
        // Path will be like: /reels/abc123 or just /abc123
        const pathParts = req.path.split('/').filter(p => p);
        const shortId = pathParts[pathParts.length - 1];

        if (!shortId) {
            return res.status(400).send('Invalid reel ID');
        }

        console.log('Looking up reel with shortId:', shortId);

        // Look up reel by shortId in Firestore
        const snapshot = await admin.firestore()
            .collection('reels')
            .where('shortId', '==', shortId)
            .limit(1)
            .get();

        if (snapshot.empty) {
            console.log('Reel not found for shortId:', shortId);
            
            // Debug: Get all reels to see what shortIds exist
            const allReels = await admin.firestore()
                .collection('reels')
                .limit(5)
                .get();
            
            const debugInfo = allReels.docs.map(doc => ({
                id: doc.id,
                shortId: doc.data().shortId,
                videoUrl: doc.data().videoUrl
            }));
            
            return res.status(404).send(`
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Reel Not Found</title>
                    <style>
                        body { font-family: Arial, sans-serif; padding: 50px; }
                        h1 { color: #667eea; }
                        .debug { background: #f5f5f5; padding: 15px; margin: 20px 0; border-radius: 5px; }
                        pre { overflow-x: auto; }
                    </style>
                </head>
                <body>
                    <h1>Reel Not Found</h1>
                    <p>Looking for shortId: <strong>${shortId}</strong></p>
                    <div class="debug">
                        <h3>Debug Info - Sample Reels:</h3>
                        <pre>${JSON.stringify(debugInfo, null, 2)}</pre>
                    </div>
                    <p>If you see reels above without shortId, run the migration:</p>
                    <a href="https://us-central1-skill-connect-9d6b3.cloudfunctions.net/migrateReels">Run Migration</a>
                </body>
                </html>
            `);
        }

        const reel = snapshot.docs[0].data();
        const videoUrl = reel.videoUrl;

        // Check if request is from a browser (has User-Agent with Mozilla)
        const userAgent = req.headers['user-agent'] || '';
        const isBrowser = userAgent.includes('Mozilla') && !userAgent.includes('SkillConnect');

        if (isBrowser) {
            // Serve HTML page with app link and install prompt
            console.log('Serving HTML page for browser request');
            return res.send(`
                <!DOCTYPE html>
                <html lang="en">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>SkillConnect - Open in App</title>
                    <style>
                        * { margin: 0; padding: 0; box-sizing: border-box; }
                        body {
                            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                            min-height: 100vh;
                            display: flex;
                            align-items: center;
                            justify-content: center;
                            padding: 20px;
                        }
                        .container {
                            background: white;
                            border-radius: 20px;
                            padding: 40px 30px;
                            max-width: 400px;
                            width: 100%;
                            text-align: center;
                            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
                        }
                        .logo {
                            width: 80px;
                            height: 80px;
                            margin: 0 auto 20px;
                            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                            border-radius: 20px;
                            display: flex;
                            align-items: center;
                            justify-content: center;
                            font-size: 40px;
                            color: white;
                            font-weight: bold;
                        }
                        h1 { font-size: 24px; color: #333; margin-bottom: 10px; }
                        p { color: #666; margin-bottom: 30px; line-height: 1.6; }
                        .btn {
                            display: block;
                            width: 100%;
                            padding: 16px;
                            border: none;
                            border-radius: 12px;
                            font-size: 16px;
                            font-weight: 600;
                            cursor: pointer;
                            text-decoration: none;
                            transition: transform 0.2s;
                            margin-bottom: 12px;
                        }
                        .btn:active { transform: scale(0.98); }
                        .btn-primary {
                            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                            color: white;
                            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
                        }
                        .btn-secondary { background: #f5f5f5; color: #333; }
                        .loading { display: none; margin: 20px 0; }
                        .spinner {
                            border: 3px solid #f3f3f3;
                            border-top: 3px solid #667eea;
                            border-radius: 50%;
                            width: 40px;
                            height: 40px;
                            animation: spin 1s linear infinite;
                            margin: 0 auto;
                        }
                        @keyframes spin {
                            0% { transform: rotate(0deg); }
                            100% { transform: rotate(360deg); }
                        }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="logo">SC</div>
                        <h1>Open in SkillConnect</h1>
                        <p id="message">View this reel in the SkillConnect app for the best experience</p>
                        
                        <div class="loading" id="loading">
                            <div class="spinner"></div>
                            <p style="margin-top: 10px; color: #666;">Opening app...</p>
                        </div>
                        
                        <button class="btn btn-primary" id="openAppBtn" onclick="openApp()">
                            Open in App
                        </button>
                        
                        <div id="installSection" style="display: none;">
                            <p style="margin: 20px 0;">Don't have the app?</p>
                            <a href="https://play.google.com/store/apps/details?id=com.example.skillconnect" class="btn btn-secondary" target="_blank">
                                Download from Play Store
                            </a>
                        </div>
                    </div>
                    
                    <script>
                        const appUrl = 'https://skill-connect-9d6b3.web.app/reels/${shortId}';
                        
                        function openApp() {
                            document.getElementById('loading').style.display = 'block';
                            document.getElementById('openAppBtn').style.display = 'none';
                            
                            window.location.href = appUrl;
                            
                            setTimeout(() => {
                                document.getElementById('loading').style.display = 'none';
                                document.getElementById('installSection').style.display = 'block';
                                document.getElementById('message').textContent = 'App not installed?';
                            }, 2000);
                        }
                        
                        window.addEventListener('load', () => {
                            setTimeout(openApp, 500);
                        });
                    </script>
                </body>
                </html>
            `);
        }

        // For app requests, redirect to video URL
        console.log('Redirecting to:', videoUrl);
        res.redirect(302, videoUrl);
    } catch (error) {
        console.error('Error in reelRedirect:', error);
        res.status(500).send(`
            <!DOCTYPE html>
            <html>
            <head>
                <title>Server Error</title>
                <style>
                    body { font-family: Arial, sans-serif; padding: 50px; }
                    h1 { color: #f44336; }
                </style>
            </head>
            <body>
                <h1>Server Error</h1>
                <p>Error: ${error.message}</p>
            </body>
            </html>
        `);
    }
});

/**
 * Cloud Function that triggers when a notification document is written
 * Sends an FCM push notification to the target user's device
 * Only sends once by checking the 'sent' field
 */
exports.sendNotificationOnCreate = onDocumentWritten(
    "notifications/{notificationId}",
    async (event) => {
        try {
            // Get the notification data AFTER the change
            const notificationAfter = event.data.after.data();

            // If document was deleted or doesn't exist, skip
            if (!notificationAfter) {
                console.log("Document deleted, skipping");
                return null;
            }

            const notificationId = event.params.notificationId;
            const userId = notificationAfter.userId;

            // CRITICAL: Check if notification was already sent to prevent duplicates
            if (notificationAfter.sent === true) {
                console.log("Notification already sent, skipping:", notificationId);
                return null;
            }

            // Get the BEFORE data to check if this is truly a new notification
            const notificationBefore = event.data.before.data();

            // If 'sent' field existed before and was true, skip
            if (notificationBefore && notificationBefore.sent === true) {
                console.log("Already processed, skipping:", notificationId);
                return null;
            }

            console.log("Processing NEW notification for user:", userId);

            // Get the user's FCM token from Firestore
            const userDoc = await admin.firestore()
                .collection("users")
                .doc(userId)
                .get();

            if (!userDoc.exists) {
                console.error("User not found:", userId);
                // Mark as sent anyway to prevent retries
                await admin.firestore()
                    .collection("notifications")
                    .doc(notificationId)
                    .update({ sent: true });
                return null;
            }

            const fcmToken = userDoc.data().fcmToken;

            if (!fcmToken) {
                console.error("No FCM token found for user:", userId);
                // Mark as sent anyway to prevent retries
                await admin.firestore()
                    .collection("notifications")
                    .doc(notificationId)
                    .update({ sent: true });
                return null;
            }

            // Prepare the FCM message
            const message = {
                token: fcmToken,
                notification: {
                    title: notificationAfter.title,
                    body: notificationAfter.body,
                },
                data: {
                    notificationId: notificationId,
                    type: notificationAfter.type || "general",
                    ...(notificationAfter.data || {}),
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "skillconnect_notifications",
                        sound: "default",
                        priority: "high",
                    },
                },
            };

            // Send the notification
            const response = await admin.messaging().send(message);
            console.log("Successfully sent notification:", response);

            // Mark notification as sent to prevent re-sending
            // This will trigger the function again, but it will be skipped due to sent=true check
            await admin.firestore()
                .collection("notifications")
                .doc(notificationId)
                .update({ sent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });

            return response;
        } catch (error) {
            console.error("Error sending notification:", error);

            // Try to mark as sent even on error to prevent infinite retries
            try {
                await admin.firestore()
                    .collection("notifications")
                    .doc(event.params.notificationId)
                    .update({ sent: true, error: error.message });
            } catch (updateError) {
                console.error("Failed to mark notification as sent:", updateError);
            }

            return null;
        }
    }
);
