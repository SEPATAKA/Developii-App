-- AlterTable
ALTER TABLE "User" ADD COLUMN "investorNumber" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "User_investorNumber_key" ON "User"("investorNumber");
