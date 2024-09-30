import * as functions from 'firebase-functions';
import { AccessToken } from 'livekit-server-sdk';
import { v4 as uuidv4 } from 'uuid';


const livekitApiKey = 'API4vY5fJ6zxS6e';
const livekitApiSecret = 'GGqV7dBkfi4mtBwK1UD1EvJCLRQCouB7YcDSwyR07MR';
const livekitHost = 'wss://tentwenty-bp8gb2jg.livekit.cloud';

export const handleLivekitToken = functions
.region('asia-northeast3')
.https.onRequest(async (req, res) => {

    // const roomName = 'room_name'; 
    const { roomName } = req.body;

    if (!roomName) {
        res.status(400).send('roomName is required');
        return;
    }

    console.log(`Room name received: ${roomName}`);

    const identity = uuidv4(); 

    const accessToken = new AccessToken(livekitApiKey, livekitApiSecret, {
        identity: identity,
    });
    accessToken.addGrant({ roomJoin: true, room: roomName });

    const livekitToken = await accessToken.toJwt();

    res.status(200).json({
        livekitToken: livekitToken
    }) 
})