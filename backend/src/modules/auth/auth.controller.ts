import { Body, Controller, Get, Post } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import {
  ChallengeCodeDto,
  ChallengeIdDto,
  InvestorBeginDto,
  InvestorCompleteDto,
  LandownerRegisterDto,
  RecoveryRequestDto,
  RecoveryVerifyDto,
  RefreshDto,
  ResetPasswordDto,
  SignInDto,
  SocialSignInDto,
} from './auth.dto';
import { IsString, MinLength } from 'class-validator';
import { AuthUser, CurrentUser, Public } from '../common/auth.decorators';

class FirebaseIdTokenDto {
  @IsString()
  @MinLength(20)
  idToken!: string;
}

@Controller('auth')
export class AuthController {
  constructor(private auth: AuthService) {}

  @Public()
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Post('firebase/session')
  firebaseSession(@Body() body: FirebaseIdTokenDto) {
    return this.auth.firebaseUserSession(body.idToken);
  }

  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('admin/firebase-session')
  firebaseAdminSession(@Body() body: FirebaseIdTokenDto) {
    return this.auth.firebaseAdminSession(body.idToken);
  }

  @Public()
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Post('sign-in')
  signIn(@Body() body: SignInDto) {
    return this.auth.signIn(body.email, body.password);
  }

  @Public()
  @Post('social-sign-in')
  social(@Body() body: SocialSignInDto) {
    return this.auth.socialSignIn(body.provider);
  }

  @Public()
  @Post('register/landowner')
  registerLandowner(@Body() body: LandownerRegisterDto) {
    return this.auth.registerLandowner(body);
  }


  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('register/investor/begin')
  beginInvestor(@Body() body: InvestorBeginDto) {
    return this.auth.beginInvestorRegistration(body);
  }

  @Public()
  @Post('register/investor/verify')
  verifyInvestor(@Body() body: ChallengeCodeDto) {
    return this.auth.verifyInvestorRegistration(body.challengeId, body.code);
  }

  @Public()
  @Post('register/investor/complete')
  completeInvestor(@Body() body: InvestorCompleteDto) {
    return this.auth.completeInvestorRegistration(body.challengeId, body.idToken);
  }

  @Public()
  @Post('register/investor/cancel')
  cancelInvestor(@Body() body: ChallengeIdDto) {
    return this.auth.cancelInvestorRegistration(body.challengeId);
  }

  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('recovery/request')
  requestRecovery(@Body() body: RecoveryRequestDto) {
    return this.auth.requestRecovery(body.email);
  }

  @Public()
  @Post('recovery/verify')
  verifyRecovery(@Body() body: RecoveryVerifyDto) {
    return this.auth.verifyRecovery(body.email, body.code);
  }

  @Public()
  @Post('recovery/reset')
  resetPassword(@Body() body: ResetPasswordDto) {
    return this.auth.resetPassword(body.challengeId, body.password);
  }

  @Public()
  @Post('refresh')
  refresh(@Body() body: RefreshDto) {
    return this.auth.refresh(body.refreshToken);
  }

  @Post('logout')
  logout(@CurrentUser() user: AuthUser, @Body() body: RefreshDto) {
    return this.auth.logout(user.id, body.refreshToken);
  }

  @Get('me')
  me(@CurrentUser() user: AuthUser) {
    return this.auth.me(user.id);
  }

  @Public()
  @Post('admin/sign-in')
  adminSignIn(@Body() body: SignInDto) {
    return this.auth.adminSignIn(body.email, body.password);
  }
}
