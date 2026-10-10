import { Body, Controller, Post, Query } from '@nestjs/common';
import { InvestmentsService } from './investments.service';
import { AuthUser, CurrentUser } from '../common/auth.decorators';

@Controller('investments')
export class InvestmentsController {
  constructor(private investments: InvestmentsService) {}

  @Post('quotes')
  quote(
    @CurrentUser() user: AuthUser,
    @Body() body: { projectId: string; amountCents: number; entity?: string },
  ) {
    return this.investments.createQuote(
      user.id,
      body.projectId,
      body.amountCents,
      body.entity,
    );
  }

  @Post()
  invest(
    @CurrentUser() user: AuthUser,
    @Body()
    body: {
      projectId: string;
      amountCents: number;
      operationId: string;
      pin: string;
      quoteId?: string;
      entity?: string;
    },
  ) {
    return this.investments.invest({
      userId: user.id,
      projectId: body.projectId,
      amountCents: body.amountCents,
      operationId: body.operationId,
      pin: body.pin,
      quoteId: body.quoteId,
      entityType: body.entity,
    });
  }
}
