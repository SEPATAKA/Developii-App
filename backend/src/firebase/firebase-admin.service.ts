import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  applicationDefault,
  cert,
  getApps,
  initializeApp,
  type App,
  type ServiceAccount,
} from 'firebase-admin/app';
import { getAuth, type Auth } from 'firebase-admin/auth';
import {
  getFirestore,
  type DocumentData,
  type Firestore,
  type QueryDocumentSnapshot,
} from 'firebase-admin/firestore';
import type { User } from '@prisma/client';

@Injectable()
export class FirebaseAdminService {
  private appInstance?: App;

  constructor(private readonly config: ConfigService) {}

  get auth(): Auth {
    return getAuth(this.app);
  }

  get firestore(): Firestore {
    return getFirestore(this.app);
  }

  async findProfileByEmail(collection: 'users' | 'adminUsers', email: string) {
    const result = await this.firestore
      .collection(collection)
      .where('email', '==', email)
      .limit(1)
      .get();
    return result.empty ? null : result.docs[0];
  }

  async findUserSessionProfile(
    email: string,
  ): Promise<
    | (DocumentData & {
        id: string;
        memberships: DocumentData[];
        entities: DocumentData[];
      })
    | null
  > {
    const profile = await this.findProfileByEmail('users', email);
    if (!profile) return null;
    const userId = profile.id;
    const [memberships, entities] = await Promise.all([
      this.firestore.collection('memberships').where('userId', '==', userId).get(),
      this.firestore.collection('investorEntities').where('userId', '==', userId).get(),
    ]);
    return {
      id: userId,
      ...profile.data(),
      memberships: memberships.docs.map((doc) => doc.data()),
      entities: entities.docs.map((doc) => doc.data()),
    };
  }

  async saveRegisteredUserProfile(
    user: User & {
      memberships: {
        id: string;
        userId: string;
        experience: string;
        createdAt: Date;
      }[];
      entities: {
        id: string;
        userId: string;
        entityType: string;
        nonResident: boolean;
        verificationStatus: string;
        createdAt: Date;
        updatedAt: Date;
      }[];
    },
    uid: string,
  ) {
    const existing = await this.findProfileByEmail('users', user.email);
    if (existing && existing.id !== user.id) return false;

    const batch = this.firestore.batch();
    batch.set(
      this.firestore.collection('users').doc(user.id),
      {
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        address: user.address,
        countryCode: user.countryCode,
        hasProfilePhoto: user.hasProfilePhoto,
        nonResident: user.nonResident,
        investorNumber: user.investorNumber,
        locked: user.locked,
        firebaseUid: uid,
        authProvider: 'firebase',
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      },
      { merge: true },
    );
    for (const membership of user.memberships) {
      batch.set(
        this.firestore.collection('memberships').doc(membership.id),
        membership,
      );
    }
    for (const entity of user.entities) {
      batch.set(
        this.firestore.collection('investorEntities').doc(entity.id),
        entity,
      );
    }
    await batch.commit();
    return true;
  }

  async linkProfile(
    profile: QueryDocumentSnapshot,
    uid: string,
    email: string,
  ) {
    const linkedUid = profile.get('firebaseUid');
    if (typeof linkedUid === 'string' && linkedUid !== uid) {
      return false;
    }
    if (linkedUid !== uid) {
      await profile.ref.set(
        { firebaseUid: uid, authProvider: 'firebase', email },
        { merge: true },
      );
    }
    return true;
  }

  async linkProfileByEmail(
    collection: 'users' | 'adminUsers',
    email: string,
    uid: string,
  ) {
    const profile = await this.findProfileByEmail(collection, email);
    return profile ? this.linkProfile(profile, uid, email) : false;
  }

  verifyIdToken(token: string) {
    return this.auth.verifyIdToken(token, true);
  }

  private get app(): App {
    if (this.appInstance) return this.appInstance;

    const projectId =
      this.config.get<string>('FIREBASE_PROJECT_ID') ??
      this.config.get<string>('GOOGLE_CLOUD_PROJECT');
    if (!projectId) {
      throw new Error('FIREBASE_PROJECT_ID is required for Firebase Admin.');
    }

    const existing = getApps().find((app) => app.name === 'developify');
    if (existing) {
      this.appInstance = existing;
      return existing;
    }

    const serviceAccountJson = this.config.get<string>(
      'FIREBASE_SERVICE_ACCOUNT_JSON',
    );
    const credential = serviceAccountJson
      ? cert(this.parseServiceAccount(serviceAccountJson, projectId))
      : applicationDefault();

    this.appInstance = initializeApp(
      { credential, projectId },
      'developify',
    );
    return this.appInstance;
  }

  private parseServiceAccount(
    json: string,
    projectId: string,
  ): ServiceAccount {
    let value: unknown;
    try {
      value = JSON.parse(json);
    } catch {
      throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON must contain valid JSON.');
    }

    if (
      typeof value !== 'object' ||
      value === null ||
      !('project_id' in value) ||
      !('client_email' in value) ||
      !('private_key' in value) ||
      value.project_id !== projectId ||
      typeof value.client_email !== 'string' ||
      typeof value.private_key !== 'string'
    ) {
      throw new Error(
        'FIREBASE_SERVICE_ACCOUNT_JSON must be a service account for FIREBASE_PROJECT_ID.',
      );
    }

    return {
      projectId: value.project_id,
      clientEmail: value.client_email,
      privateKey: value.private_key,
    };
  }
}
