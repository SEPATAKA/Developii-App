import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UsersService } from '../users/users.service';

@Injectable()
export class CatalogService {
  constructor(
    private prisma: PrismaService,
    private users: UsersService,
  ) {}

  private mapProject(p: {
    id: string;
    name: string;
    town: string;
    description: string;
    annualRateBps: number;
    termMonths: number;
    minInvestCents: bigint;
    capacityCents: bigint;
    fundedCents: bigint;
    currency: string;
    status: string;
    imageUrl: string | null;
    contentJson: unknown;
  }) {
    const remaining = p.capacityCents - p.fundedCents;
    return {
      id: p.id,
      name: p.name,
      town: p.town,
      description: p.description,
      annualRateBps: p.annualRateBps,
      termMonths: p.termMonths,
      minInvestCents: Number(p.minInvestCents),
      capacityCents: Number(p.capacityCents),
      fundedCents: Number(p.fundedCents),
      remainingCents: Number(remaining < 0n ? 0n : remaining),
      currency: p.currency,
      status: p.status,
      imageUrl: p.imageUrl,
      content: p.contentJson,
    };
  }

  async listProjects() {
    const projects = await this.prisma.project.findMany({
      where: { status: { in: ['open', 'funded'] } },
      orderBy: { publishedAt: 'desc' },
    });
    return projects.map((p) => this.mapProject(p));
  }

  async getProject(id: string) {
    const project = await this.prisma.project.findUnique({ where: { id } });
    if (!project) throw new NotFoundException('Project not found.');
    return this.mapProject(project);
  }

  async favourites(userId: string, entityType?: string) {
    const entity = await this.users.resolveEntity(userId, entityType);
    const rows = await this.prisma.favourite.findMany({
      where: { entityId: entity.id },
    });
    return rows.map((r) => r.projectId);
  }

  async setFavourite(
    userId: string,
    projectId: string,
    favourite: boolean,
    entityType?: string,
  ) {
    const entity = await this.users.resolveEntity(userId, entityType);
    await this.getProject(projectId);
    if (favourite) {
      await this.prisma.favourite.upsert({
        where: {
          entityId_projectId: { entityId: entity.id, projectId },
        },
        create: { userId, entityId: entity.id, projectId },
        update: {},
      });
    } else {
      await this.prisma.favourite.deleteMany({
        where: { entityId: entity.id, projectId },
      });
    }
    return { ok: true };
  }

  async rememberSearch(userId: string, query: string) {
    const q = query.trim();
    if (!q) return { ok: true };
    await this.prisma.searchHistory.create({
      data: { userId, query: q },
    });
    return { ok: true };
  }

  async recentSearches(userId: string) {
    const rows = await this.prisma.searchHistory.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });
    return [...new Set(rows.map((r) => r.query))];
  }
}
