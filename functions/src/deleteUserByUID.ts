import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as path from 'path';

// Initialize Firebase Admin SDK with the service account key
const serviceAccountPath = path.join(__dirname, '../tentenv9-322ab475b341.json');

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
        // Delete the user from Firebase Authentication
        await admin.auth().deleteUser(uid);
        console.log(`Successfully deleted user with UID: ${uid}`);
        res.status(200).json({ message: `Successfully deleted user with UID: ${uid}` });
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
