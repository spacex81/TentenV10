// import * as functions from 'firebase-functions';
// import * as admin from 'firebase-admin';
// import * as path from 'path';

// // Initialize Firebase Admin SDK with the service account key
// const serviceAccountPath = path.join(__dirname, '../tentenv9-322ab475b341.json');

// // admin.initializeApp({
// //     credential: admin.credential.cert(serviceAccountPath),
// //     projectId: 'tentenv9',
// // });

// // Set region for the function
// export const deleteUserByUID = functions
// .region('asia-northeast3')
// .https.onRequest(async (req, res) => {
//     const { uid } = req.body;

//     if (!uid) {
//         res.status(400).send('UID is required');
//         return; // Ensure the function exits here
//     }

//     try {
//         // Delete the user from Firebase Authentication
//         await admin.auth().deleteUser(uid);
//         console.log(`Successfully deleted user with UID: ${uid}`);
//         res.status(200).json({ message: `Successfully deleted user with UID: ${uid}` });
//     } catch (error) {
//         // Handle the 'unknown' type error by casting it to Error
//         if (error instanceof Error) {
//             console.error(`Error deleting user: ${error.message}`);
//             res.status(500).json({ error: `Error deleting user: ${error.message}` });
//         } else {
//             // Handle cases where the error is not an instance of Error
//             console.error('Unknown error occurred while deleting user');
//             res.status(500).json({ error: 'Unknown error occurred' });
//         }
//     }
// });

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as path from 'path';

// Initialize Firebase Admin SDK with the service account key
const serviceAccountPath = path.join(__dirname, '../tentenv9-322ab475b341.json');

// Uncomment this if the admin SDK has not been initialized elsewhere
// admin.initializeApp({
//     credential: admin.credential.cert(serviceAccountPath),
//     projectId: 'tentenv9',
// });

// Set region for the function
export const deleteUserByUID = functions
    .region('asia-northeast3')
    .https.onRequest(async (req, res) => {
        const { uid } = req.body;

        if (!uid) {
            res.status(400).send('UID is required');
            return; // Ensure the function exits here
        }

        try {
            // Step 1: Fetch the user's friends from Firestore
            const userDoc = await admin.firestore().collection('users').doc(uid).get();
            if (!userDoc.exists) {
                res.status(404).json({ error: `User with UID: ${uid} not found in Firestore` });
                return;
            }

            const userData = userDoc.data();
            const friends = userData?.friends || [];

            // Step 2: Remove the user from each friend's 'friends' field
            const batch = admin.firestore().batch(); // Batch write for performance

            for (const friendId of friends) {
                const friendRef = admin.firestore().collection('users').doc(friendId);
                batch.update(friendRef, {
                    friends: admin.firestore.FieldValue.arrayRemove(uid)
                });
            }

            // Commit the batch
            await batch.commit();

            // Step 3: Delete the user from Firebase Authentication
            await admin.auth().deleteUser(uid);
            console.log(`Successfully deleted user with UID: ${uid}`);

            res.status(200).json({ message: `Successfully deleted user with UID: ${uid} and cleaned up friends' lists` });
        } catch (error) {
            // Handle the 'unknown' type error by casting it to Error
            if (error instanceof Error) {
                console.error(`Error deleting user: ${error.message}`);
                res.status(500).json({ error: `Error deleting user: ${error.message}` });
            } else {
                // Handle cases where the error is not an instance of Error
                console.error('Unknown error occurred while deleting user');
                res.status(500).json({ error: 'Unknown error occurred' });
            }
        }
    });
