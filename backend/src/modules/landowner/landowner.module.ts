import { Module } from '@nestjs/common';
import { LandownerService } from './landowner.service';
import { LandownerController } from './landowner.controller';

@Module({
  providers: [LandownerService],
  controllers: [LandownerController],
  exports: [LandownerService],
})
export class LandownerModule {}
