import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { CatalogService } from './catalog.service';
import { AuthUser, CurrentUser } from '../common/auth.decorators';

@Controller('catalog')
export class CatalogController {
  constructor(private catalog: CatalogService) {}

  @Get('projects')
  list() {
    return this.catalog.listProjects();
  }

  @Get('projects/:id')
  one(@Param('id') id: string) {
    return this.catalog.getProject(id);
  }

  @Get('favourites')
  favourites(
    @CurrentUser() user: AuthUser,
    @Query('entity') entity?: string,
  ) {
    return this.catalog.favourites(user.id, entity);
  }

  @Post('favourites')
  setFavourite(
    @CurrentUser() user: AuthUser,
    @Body() body: { projectId: string; favourite: boolean; entity?: string },
  ) {
    return this.catalog.setFavourite(
      user.id,
      body.projectId,
      body.favourite,
      body.entity,
    );
  }

  @Get('searches')
  searches(@CurrentUser() user: AuthUser) {
    return this.catalog.recentSearches(user.id);
  }

  @Post('searches')
  remember(
    @CurrentUser() user: AuthUser,
    @Body() body: { query: string },
  ) {
    return this.catalog.rememberSearch(user.id, body.query);
  }
}
