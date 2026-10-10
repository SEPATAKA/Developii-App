import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private transporter: nodemailer.Transporter;

  constructor(private config: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: config.get('SMTP_HOST', 'localhost'),
      port: Number(config.get('SMTP_PORT', 1025)),
      secure: false,
      auth:
        config.get('SMTP_USER') && config.get('SMTP_PASS')
          ? {
              user: config.get<string>('SMTP_USER'),
              pass: config.get<string>('SMTP_PASS'),
            }
          : undefined,
    });
  }

  async sendOtp(email: string, code: string, purpose: string) {
    const from = this.config.get('SMTP_FROM', 'noreply@developify.co.za');
    await this.transporter.sendMail({
      from,
      to: email,
      subject: `Developify verification code`,
      text: `Your Developify ${purpose} code is ${code}. It expires shortly. If you did not request this, ignore this email.`,
      html: `<p>Your Developify <strong>${purpose}</strong> code is <strong>${code}</strong>.</p><p>It expires shortly. If you did not request this, ignore this email.</p>`,
    });
  }
}
