import { IsEmail, IsEnum, IsOptional, IsString, MinLength } from 'class-validator';
import { EntityType } from '@prisma/client';

export class SignInDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(1)
  password!: string;
}

export class LandownerRegisterDto {
  @IsString()
  @MinLength(1)
  name!: string;

  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(1)
  phone!: string;

  @IsString()
  @MinLength(8)
  password!: string;

  @IsOptional()
  @IsString()
  countryCode?: string;
}

export class InvestorBeginDto {
  @IsString()
  @MinLength(1)
  name!: string;

  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(1)
  phone!: string;

  @IsString()
  @MinLength(8)
  password!: string;

  @IsEnum(EntityType)
  entity!: EntityType;

  @IsOptional()
  nonResident?: boolean;

  @IsOptional()
  @IsString()
  countryCode?: string;
}

export class ChallengeCodeDto {
  @IsString()
  @MinLength(1)
  challengeId!: string;

  @IsString()
  @MinLength(4)
  code!: string;
}

export class ChallengeIdDto {
  @IsString()
  @MinLength(1)
  challengeId!: string;
}

export class RecoveryRequestDto {
  @IsEmail()
  email!: string;
}

export class RecoveryVerifyDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(4)
  code!: string;
}

export class ResetPasswordDto {
  @IsString()
  challengeId!: string;

  @IsString()
  @MinLength(8)
  password!: string;
}

export class RefreshDto {
  @IsString()
  refreshToken!: string;
}

export class SocialSignInDto {
  @IsString()
  provider!: string;
}
