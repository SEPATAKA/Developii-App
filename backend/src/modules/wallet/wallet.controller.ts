import { Body, Controller, Delete, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { WalletService } from './wallet.service';
import { AuthUser, CurrentUser, Roles } from '../common/auth.decorators';

@Controller()
export class WalletController {
  constructor(private wallet: WalletService) {}

  @Get('wallet/snapshot')
  snapshot(@CurrentUser() user: AuthUser, @Query('entity') entity?: string) {
    return this.wallet.snapshot(user.id, entity);
  }

  @Get('wallet/transactions/:id')
  transaction(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Query('entity') entity?: string,
  ) {
    return this.wallet.getTransaction(user.id, id, entity);
  }

  @Get('wallet/investments/:id')
  investment(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Query('entity') entity?: string,
  ) {
    return this.wallet.getInvestment(user.id, id, entity);
  }

  @Post('wallet/add-money')
  addMoney(
    @CurrentUser() user: AuthUser,
    @Body()
    body: {
      amountCents: number;
      methodId: string;
      operationId: string;
      pin: string;
      entity?: string;
    },
  ) {
    return this.wallet.addMoney({
      userId: user.id,
      amountCents: body.amountCents,
      methodId: body.methodId,
      operationId: body.operationId,
      pin: body.pin,
      entityType: body.entity,
    });
  }

  @Post('wallet/withdraw')
  withdraw(
    @CurrentUser() user: AuthUser,
    @Body()
    body: {
      amountCents: number;
      methodId: string;
      operationId: string;
      pin: string;
      entity?: string;
    },
  ) {
    return this.wallet.withdraw({
      userId: user.id,
      amountCents: body.amountCents,
      methodId: body.methodId,
      operationId: body.operationId,
      pin: body.pin,
      entityType: body.entity,
    });
  }

  @Post('wallet/payment-methods/bank')
  addBank(
    @CurrentUser() user: AuthUser,
    @Body() body: Record<string, string>,
  ) {
    return this.wallet.addBankAccount(user.id, body as never);
  }

  @Post('wallet/payment-methods/card')
  addCard() {
    return this.wallet.addCard();
  }

  @Delete('wallet/payment-methods/:id')
  removeMethod(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Query('entity') entity?: string,
  ) {
    return this.wallet.removePaymentMethod(user.id, id, entity);
  }

  @Patch('wallet/payment-methods/:id/default')
  setDefault(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() body: { isDefault: boolean; entity?: string },
  ) {
    return this.wallet.setDefaultPaymentMethod(
      user.id,
      id,
      body.isDefault,
      body.entity,
    );
  }

  @Post('wallet/notifications/read')
  markRead(
    @CurrentUser() user: AuthUser,
    @Body() body: { id?: string },
  ) {
    return this.wallet.markNotificationsRead(user.id, body.id);
  }

  @Roles('admin', 'ops')
  @Post('admin/wallet/deposits/:id/confirm')
  confirmDeposit(@CurrentUser() admin: AuthUser, @Param('id') id: string) {
    return this.wallet.confirmDeposit(admin.id, id);
  }

  @Roles('admin', 'ops')
  @Post('admin/wallet/withdrawals/:id/approve')
  approveWithdrawal(@CurrentUser() admin: AuthUser, @Param('id') id: string) {
    return this.wallet.approveWithdrawal(admin.id, id);
  }
}
