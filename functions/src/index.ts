// import {onRequest} from "firebase-functions/v2/https";
// import * as logger from "firebase-functions/logger";
import { setGlobalOptions } from 'firebase-functions/v2'
import * as path from 'path';
import { handleRegularNotification } from './handleRegularNotification';
import { handleLivekitToken } from './handleLivekitToken';
import { generateFirebaseToken } from './generateFirebaseToken';
import { generateFirebaseTokenForTest } from './generateFirebaseTokenForTest';
import { deleteUserByUID } from './deleteUserByUID';
import { notifyAppSyncOnUserUpdate } from './notifyAppSyncOnUserUpdate';

import * as admin from 'firebase-admin';

// // __dirname == '/lib'
// const serviceAccountPath = path.join(__dirname, '../tentenv9-322ab475b341.json');

// admin.initializeApp({
//     credential: admin.credential.cert(serviceAccountPath),
//     projectId: 'tentenv9',
// });

setGlobalOptions({ region: 'asia-northeast3' })

exports.handleLivekitToken = handleLivekitToken;
exports.handleRegularNotification = handleRegularNotification;
exports.generateFirebaseToken = generateFirebaseToken;
exports.generateFirebaseTokenForTest = generateFirebaseTokenForTest
exports.deleteUserByUID = deleteUserByUID;
exports.notifyAppSyncOnUserUpdate = notifyAppSyncOnUserUpdate;