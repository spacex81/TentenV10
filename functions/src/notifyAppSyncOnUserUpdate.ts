
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

// admin.initializeApp();

// AppSync API configuration
const APPSYNC_API_URL = "https://gsrahbthhzblhedp7n7vfw7yfa.appsync-api.ap-northeast-2.amazonaws.com/graphql";
const APPSYNC_API_KEY = "da2-esmk3m6luzg3pahibjoebhtedm";

// GraphQL mutation as a string with all fields included
const mutation = `
    mutation updateUserData($id: ID!, $input: UpdateUserInput!) {
        updateUserData(id: $id, input: $input) {
            id
            email
            username
            hasIncomingCallRequest
            profileImagePath
            deviceToken
            friends
            roomName
            isBusy
            socialLoginId
            socialLoginType
            imageOffset
            receivedInvitations
            sentInvitations
            refusedPushNotification
            status
            lastActive
        }
    }
`;

export const notifyAppSyncOnUserUpdate = functions
    .region('asia-northeast3')
    .firestore.document('users/{userId}')
    .onUpdate(async (change, context) => {
        const newUserData = change.after.data();
        const userId = context.params.userId;

        // Variables for the mutation, keeping the structure simple
        const variables = {
            id: userId,
            input: {
                email: newUserData.email,
                username: newUserData.username,
                hasIncomingCallRequest: newUserData.hasIncomingCallRequest,
                profileImagePath: newUserData.profileImagePath,
                deviceToken: newUserData.deviceToken,
                friends: newUserData.friends,
                roomName: newUserData.roomName,
                isBusy: newUserData.isBusy,
                socialLoginId: newUserData.socialLoginId,
                socialLoginType: newUserData.socialLoginType,
                imageOffset: newUserData.imageOffset,
                receivedInvitations: newUserData.receivedInvitations,
                sentInvitations: newUserData.sentInvitations,
                refusedPushNotification: newUserData.refusedPushNotification,
                status: newUserData.status,
                lastActive: newUserData.lastActive instanceof admin.firestore.Timestamp 
                            ? newUserData.lastActive.toDate().toISOString() 
                            : newUserData.lastActive,
            },
        };


        try {
            // Send the mutation request to AppSync
            const response = await axios.post(
                APPSYNC_API_URL,
                {
                    query: mutation,
                    variables: variables,
                },
                {
                    headers: {
                        'Content-Type': 'application/json',
                        'x-api-key': APPSYNC_API_KEY,
                    },
                }
            );

            console.log('AppSync response:', response.data);
        } catch (error) {
            // Handle the error, checking for Axios errors specifically
            if (axios.isAxiosError(error)) {
                console.error('Axios error notifying AppSync:', error.response ? error.response.data : error.message);
            } else {
                console.error('Unknown error notifying AppSync:', error);
            }
        }
    });
