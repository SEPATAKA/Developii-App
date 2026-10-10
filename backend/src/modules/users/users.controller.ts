import { Body, Controller, Get, Patch, Post } from '@nestjs/common';
import { UsersService } from './users.service';
import { AuthUser, CurrentUser } from '../common/auth.decorators';

@Controller('users')
export class UsersController {
  constructor(private users: UsersService) {}

  @Get('me')
  me(@CurrentUser() user: AuthUser) {
    return this.users.getProfile(user.id);
  }

  @Patch('me')
  update(@CurrentUser() user: AuthUser, @Body() body: Record<string, unknown>) {
    return this.users.updateProfile(user.id, body as never);
  }

  @Get('me/preferences')
  preferences(@CurrentUser() user: AuthUser) {
    return this.users.getPreferences(user.id);
  }

  @Patch('me/preferences')
  updatePreferences(
    @CurrentUser() user: AuthUser,
    @Body() body: Record<string, unknown>,
  ) {
    return this.users.updatePreferences(user.id, body as never);
  }

  @Get('me/payout')
  payout(@CurrentUser() user: AuthUser) {
    return this.users.getPayout(user.id);
  }

  @Patch('me/payout')
  updatePayout(
    @CurrentUser() user: AuthUser,
    @Body() body: Record<string, unknown>,
  ) {
    return this.users.updatePayout(user.id, body as never);
  }

  @Get('me/security')
  security(@CurrentUser() user: AuthUser) {
    return this.users.getSecurity(user.id);
  }

  @Post('me/security')
  updateSecurity(
    @CurrentUser() user: AuthUser,
    @Body()
    body: {
      action: string;
      pin?: string;
      password?: string;
      currentPassword?: string;
    },
  ) {
    return this.users.updateSecurity(
      user.id,
      body.action,
      body.pin,
      body.password,
      body.currentPassword,
    );
  }
}
