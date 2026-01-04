const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

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
