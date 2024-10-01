import * as functions from 'firebase-functions';
import * as fs from 'fs';
import * as http2 from 'http2';
import * as jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';

// Configuration
const TEAM_ID = "GHJU9V8GHS";
const AUTH_KEY_ID = "96YT8389V6";
const TOPIC = "tech.komaki.TentenV10";
const APNS_HOST_NAME = "api.sandbox.push.apple.com";
const TOKEN_KEY_FILE_NAME = "./AuthKey_96YT8389V6.p8";


// Define the notification types
type NotificationType = 'connect' | 'disconnect' | 'poke';

// Notification configuration based on type
const NOTIFICATION_CONFIG: Record<NotificationType, { title: string; body: string }> = {
    connect: {
        title: 'Username',
        body: '📢 말하고 있어요',
    },
    disconnect: {
        title: 'Username',
        body: '✌️ 끝!',
    },
    poke: {
        title: 'Username',
        body: '👋 안녕!',
    },
    // Add more types here in the future
};

export const handleRegularNotification = functions
.region('asia-northeast3')
.https.onRequest(async (req, res) => {
    const channelUUID = uuidv4();
    console.log(channelUUID);

    // Ensure the receiverToken is provided in the request body
    // const { receiverToken, notificationType, username } = req.body;
    const { receiverToken, notificationType, senderId } = req.body;

    if (!receiverToken) {
        res.status(400).send('receiverToken is required');
    }

    if (!notificationType) {
        res.status(400).send('notificationType is required');
    }


    if (!senderId) {
        res.status(400).send('senderId is required');
    }

    // Safely typecast notificationType to the correct type
    var config = NOTIFICATION_CONFIG[notificationType as NotificationType];

    const PAYLOAD = JSON.stringify({
        aps: {
            "mutable-content": 1,
            alert: {
                title: config.title,
                body: config.body,
            },
            "showWhenLocked": true,
            category: "INSendMessageIntent",
            "thread-id": "unique-conversation-id",
            badge: 0,
            sound: 'default',
        },
        customData: {
            channelUUID: channelUUID,
            notificationType: notificationType,
            senderId: senderId
        },
    });

    
    try {
        // Read the private key from the file system
        const privateKey = fs.readFileSync(TOKEN_KEY_FILE_NAME, 'utf8');

        // Generate the JWT
        const issueTime = Math.floor(Date.now() / 1000);

        const token = jwt.sign(
            {
                iss: TEAM_ID,
                iat: issueTime
            },
            privateKey,
            {
                algorithm: 'ES256',
                header: {
                    alg: 'ES256',
                    kid: AUTH_KEY_ID
                }
            }
        );

        // Create HTTP/2 client session
        const client = http2.connect(`https://${APNS_HOST_NAME}`);

        client.on('error', (err) => {
            console.error('HTTP/2 client error:', err);
            res.status(500).send('Failed to connect to APNs');
        });

        // Create the request
        const reqAPNS = client.request({
            ':method': 'POST',
            ':path': `/3/device/${receiverToken}`,
            'apns-topic': TOPIC,
            'authorization': `bearer ${token}`,
            'content-type': 'application/json',
        });

        reqAPNS.setEncoding('utf8');

        let data = '';

        reqAPNS.on('response', (headers, flags) => {
            for (const name in headers) {
                console.log(`${name}: ${headers[name]}`);
            }
        });

        reqAPNS.on('data', (chunk) => {
            data += chunk;
        });

        reqAPNS.on('end', () => {
            console.log('Response:', data);
            res.status(200).send('Push notification sent successfully');
            client.close();
        });

        reqAPNS.on('error', (err) => {
            console.error('Request error:', err);
            res.status(500).send('Request error');
        });

        // Send the payload
        reqAPNS.write(PAYLOAD);
        reqAPNS.end();
    } catch (error) {
        console.error('Error:', error);
        res.status(500).send('Error sending notification');
    }
});
