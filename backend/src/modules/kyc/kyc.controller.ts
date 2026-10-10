import { Body, Controller, Get, Param, Post, Put } from '@nestjs/common';
import { EntityType } from '@prisma/client';
import { KycService } from './kyc.service';
import { AuthUser, CurrentUser, Roles } from '../common/auth.decorators';

@Controller('kyc')
export class KycController {
  constructor(private kyc: KycService) {}

  @Get(':entity')
  load(@CurrentUser() user: AuthUser, @Param('entity') entity: EntityType) {
    return this.kyc.load(user.id, entity);
  }

  @Put(':entity')
  save(
    @CurrentUser() user: AuthUser,
    @Param('entity') entity: EntityType,
    @Body() body: { fields: Record<string, unknown> },
  ) {
    return this.kyc.save(user.id, entity, body.fields ?? {});
  }

  @Post(':entity/documents')
  upload(
    @CurrentUser() user: AuthUser,
    @Param('entity') entity: EntityType,
    @Body()
    body: {
      key: string;
      name: string;
      mimeType: string;
      sizeBytes: number;
      storageKey: string;
      memberId?: string;
    },
  ) {
    return this.kyc.upload(user.id, entity, body);
  }

  @Post(':entity/members')
  member(
    @CurrentUser() user: AuthUser,
    @Param('entity') entity: EntityType,
    @Body()
    body: { id?: string; role: string; fields: object; allocation?: number },
  ) {
    return this.kyc.saveMember(user.id, entity, body);
  }

  @Post(':entity/invites')
  invite(
    @CurrentUser() user: AuthUser,
    @Param('entity') entity: EntityType,
    @Body() body: { email: string; role: string },
  ) {
    return this.kyc.invite(user.id, entity, body);
  }

  @Post(':entity/submit')
  submit(@CurrentUser() user: AuthUser, @Param('entity') entity: EntityType) {
    return this.kyc.submit(user.id, entity);
  }
}

@Controller('admin/kyc')
export class AdminKycController {
  constructor(private kyc: KycService) {}

  @Roles('admin', 'compliance', 'ops')
  @Get('queue')
  queue() {
    return this.kyc.adminQueue();
  }

  @Roles('admin', 'compliance', 'ops')
  @Post(':draftId/decide')
  decide(
    @CurrentUser() admin: AuthUser,
    @Param('draftId') draftId: string,
    @Body()
    body: {
      decision: 'verified' | 'correctionRequired' | 'incomplete';
      note?: string;
    },
  ) {
    return this.kyc.adminDecide(admin.id, draftId, body.decision, body.note);
  }
}
