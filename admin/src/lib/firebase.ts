import { getApp, getApps, initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';

const app = getApps().length
  ? getApp()
  : initializeApp({
      apiKey:
        process.env.NEXT_PUBLIC_FIREBASE_API_KEY ??
        'AIzaSyAg_XRQ6yjm_Br1Z_hL_itJ_cgqD1X8u10',
      appId:
        process.env.NEXT_PUBLIC_FIREBASE_APP_ID ??
        '1:445207943313:web:38e7355af807fc043a8730',
      authDomain:
        process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN ??
        'developify-5615a.firebaseapp.com',
      projectId:
        process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? 'developify-5615a',
      messagingSenderId:
        process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID ?? '445207943313',
      storageBucket:
        process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET ??
        'developify-5615a.firebasestorage.app',
      measurementId:
        process.env.NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID ?? 'G-5DLP9W1YC2',
    });

export const firebaseAuth = getAuth(app);
