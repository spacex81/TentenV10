import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { v4 as uuidv4 } from 'uuid'; // Import UUID generator
import * as path from 'path';

// __dirname == '/lib'
const serviceAccountPath = path.join(__dirname, '../tentenv9-322ab475b341.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccountPath),
    projectId: 'tentenv9',
});

const firestore = admin.firestore();

export const generateFirebaseToken = functions.region('asia-northeast3')
    .https.onRequest(async (req, res) => {
        const { socialLoginId, socialLoginType } = req.body;

        if (!socialLoginId || !socialLoginType) {
            res.status(400).send('Both socialLoginId and socialLoginType are required');
            return;
        }

        try {
            // Step 1: Query Firestore for a document with matching socialLoginId and socialLoginType
            const userQuery = await firestore.collection('users')
                .where('socialLoginId', '==', socialLoginId)
                .where('socialLoginType', '==', socialLoginType)
                .limit(1) // Limit to one result
                .get();

            let uid: string;

            if (!userQuery.empty) {
                // Step 2: User exists, retrieve the UID from the document
                const userDoc = userQuery.docs[0];
                uid = userDoc.id; // Use the document ID as the UID
            } else {
                // Step 3: User does not exist, generate a new UID
                uid = uuidv4();
            }

            // Step 4: Generate the custom token with the consistent UID
            const customToken = await admin.auth().createCustomToken(uid);

            res.status(200).json({
                firebaseToken: customToken
            });
        } catch (error) {
            console.error('Error creating custom token:', error);
            res.status(500).send('Error creating custom token');
        }
    });
