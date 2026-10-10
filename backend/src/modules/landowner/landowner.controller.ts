import { Body, Controller, Get, Param, Post, Put } from '@nestjs/common';
import { PropertyStatus } from '@prisma/client';
import { LandownerService } from './landowner.service';
import { AuthUser, CurrentUser, Roles } from '../common/auth.decorators';

@Controller('landowner')
export class LandownerController {
  constructor(private landowner: LandownerService) {}

  @Get('overview')
  overview(@CurrentUser() user: AuthUser) {
    return this.landowner.overview(user.id);
  }

  @Get('properties')
  properties(@CurrentUser() user: AuthUser) {
    return this.landowner.properties(user.id);
  }

  @Get('properties/:id')
  property(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.landowner.property(user.id, id);
  }

  @Get('earnings')
  earnings(@CurrentUser() user: AuthUser) {
    return this.landowner.earnings(user.id);
  }

  @Get('drafts/:draftKey')
  readDraft(@CurrentUser() user: AuthUser, @Param('draftKey') draftKey: string) {
    return this.landowner.readDraft(user.id, draftKey);
  }

  @Put('drafts/:draftKey')
  saveDraft(
    @CurrentUser() user: AuthUser,
    @Param('draftKey') draftKey: string,
    @Body() body: { step: number; payload: object },
  ) {
    return this.landowner.saveDraft(
      user.id,
      draftKey,
      body.step ?? 1,
      body.payload ?? {},
    );
  }

  @Post('submit')
  submit(
    @CurrentUser() user: AuthUser,
    @Body() body: { draftKey: string },
  ) {
    return this.landowner.submit(user.id, body.draftKey || 'default');
  }

  @Roles('admin', 'ops')
  @Get('admin/properties')
  adminList() {
    return this.landowner.adminList();
  }

  @Roles('admin', 'ops')
  @Post('admin/properties/:id/status')
  setStatus(
    @CurrentUser() admin: AuthUser,
    @Param('id') id: string,
    @Body() body: { status: PropertyStatus },
  ) {
    return this.landowner.adminSetStatus(admin.id, id, body.status);
  }
}
