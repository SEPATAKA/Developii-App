import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  CreateBucketCommand,
  HeadBucketCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { randomUUID } from 'crypto';

@Injectable()
export class DocumentsService {
  private client: S3Client;
  private bucket: string;
  private ready = false;

  constructor(private config: ConfigService) {
    this.bucket = config.get('S3_BUCKET', 'developify-documents');
    this.client = new S3Client({
      region: config.get('S3_REGION', 'us-east-1'),
      endpoint: config.get('S3_ENDPOINT') || undefined,
      forcePathStyle: config.get('S3_FORCE_PATH_STYLE') === 'true',
      credentials: {
        accessKeyId: config.get('S3_ACCESS_KEY', 'developify'),
        secretAccessKey: config.get('S3_SECRET_KEY', 'developifysecret'),
      },
    });
  }

  private async ensureBucket() {
    if (this.ready) return;
    try {
      await this.client.send(new HeadBucketCommand({ Bucket: this.bucket }));
    } catch {
      try {
        await this.client.send(
          new CreateBucketCommand({ Bucket: this.bucket }),
        );
      } catch {
        // MinIO may race; ignore if already exists
      }
    }
    this.ready = true;
  }

  async createUploadUrl(params: {
    mimeType: string;
    name: string;
    prefix: string;
  }) {
    await this.ensureBucket();
    const storageKey = `${params.prefix}/${randomUUID()}-${params.name.replace(/[^a-zA-Z0-9._-]/g, '_')}`;
    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: storageKey,
      ContentType: params.mimeType,
    });
    const uploadUrl = await getSignedUrl(this.client, command, {
      expiresIn: 900,
    });
    return { storageKey, uploadUrl };
  }
}
