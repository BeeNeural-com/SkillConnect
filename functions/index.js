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
            
            return res.status(404).send(`
                <!DOCTYPE html>
                <html lang="en">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>SkillConnect - Reel Not Found</title>
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
                        p { color: #666; margin-bottom: 20px; line-height: 1.6; }
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
                            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                            color: white;
                            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
                        }
                        .btn:active { transform: scale(0.98); }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="logo">SC</div>
                        <h1>Reel Not Found</h1>
                        <p>This reel may have been removed or is no longer available.</p>
                        <a href="https://play.google.com/store/apps/details?id=com.example.skillconnect" class="btn">
                            Get SkillConnect App
                        </a>
                    </div>
                </body>
                </html>
            `);
        }

        const reel = snapshot.docs[0].data();
        const videoUrl = reel.videoUrl;
        const packageName = 'com.example.skillconnect';
        const playStoreUrl = 'https://play.google.com/store/apps/details?id=' + packageName;
        const appDeepLink = 'https://skill-connect-9d6b3.web.app/reels/' + shortId;

        // Build Android intent:// URI
        // This opens the app if installed, or falls back to Play Store
        const intentUrl = 'intent://reels/' + shortId
            + '#Intent'
            + ';scheme=https'
            + ';host=skill-connect-9d6b3.web.app'
            + ';package=' + packageName
            + ';S.browser_fallback_url=' + encodeURIComponent(playStoreUrl)
            + ';end';

        // Check if request is from a browser
        const userAgent = req.headers['user-agent'] || '';
        const isBrowser = userAgent.includes('Mozilla') && !userAgent.includes('SkillConnect');

        if (isBrowser) {
            console.log('Serving deep link page for browser request');

            const isAndroid = userAgent.includes('Android');
            const isIOS = /iPhone|iPad|iPod/i.test(userAgent);

            return res.send(`
                <!DOCTYPE html>
                <html lang="en">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>SkillConnect - Open in App</title>
                    <meta name="description" content="Watch this reel on SkillConnect">
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
                            animation: slideUp 0.4s ease-out;
                        }
                        @keyframes slideUp {
                            from { opacity: 0; transform: translateY(20px); }
                            to { opacity: 1; transform: translateY(0); }
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
                        p { color: #666; margin-bottom: 20px; line-height: 1.6; }
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
                        .status-text {
                            font-size: 14px;
                            color: #999;
                            margin-top: 8px;
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
                            <p class="status-text">Opening app...</p>
                        </div>
                        
                        <a href="${intentUrl}" class="btn btn-primary" id="openAppBtn">
                            Open in App
                        </a>
                        
                        <div id="installSection" style="display: none;">
                            <p style="margin: 10px 0;">Don't have the app yet?</p>
                            <a href="${playStoreUrl}" class="btn btn-secondary" target="_blank">
                                Download from Play Store
                            </a>
                        </div>
                    </div>
                    
                    <script>
                        var isAndroid = ${isAndroid};
                        var isIOS = ${isIOS};
                        var intentUrl = '${intentUrl}';
                        var playStoreUrl = '${playStoreUrl}';
                        
                        function openApp() {
                            document.getElementById('loading').style.display = 'block';
                            document.getElementById('openAppBtn').style.display = 'none';
                            
                            if (isAndroid) {
                                // Use intent:// scheme for Android
                                // This will open the app if installed, or redirect to Play Store
                                window.location.href = intentUrl;
                                
                                // Show install section after a delay as fallback
                                setTimeout(function() {
                                    document.getElementById('loading').style.display = 'none';
                                    document.getElementById('openAppBtn').style.display = 'block';
                                    document.getElementById('installSection').style.display = 'block';
                                }, 2500);
                            } else if (isIOS) {
                                // For iOS, show download prompt directly
                                document.getElementById('loading').style.display = 'none';
                                document.getElementById('message').textContent = 'SkillConnect is available on Android';
                                document.getElementById('openAppBtn').style.display = 'none';
                                document.getElementById('installSection').style.display = 'block';
                            } else {
                                // Desktop: show download prompt
                                document.getElementById('loading').style.display = 'none';
                                document.getElementById('message').textContent = 'Download the SkillConnect app to view this reel';
                                document.getElementById('openAppBtn').style.display = 'none';
                                document.getElementById('installSection').style.display = 'block';
                            }
                        }
                        
                        // Auto-attempt on Android devices
                        if (isAndroid) {
                            window.addEventListener('load', function() {
                                setTimeout(openApp, 300);
                            });
                        }
                    </script>
                </body>
                </html>
            `);
        }

        // For app requests (or non-browser clients), redirect to the video URL
        console.log('Redirecting to:', videoUrl);
        res.redirect(302, videoUrl);
    } catch (error) {
        console.error('Error in reelRedirect:', error);
        res.status(500).send(`
            <!DOCTYPE html>
            <html>
            <head>
                <title>Something went wrong</title>
                <style>
                    body { font-family: -apple-system, sans-serif; padding: 50px; text-align: center; }
                    h1 { color: #667eea; }
                    p { color: #666; margin-top: 10px; }
                </style>
            </head>
            <body>
                <h1>Something went wrong</h1>
                <p>Please try again later or open the SkillConnect app directly.</p>
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
