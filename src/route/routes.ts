import { Routes } from '@angular/router';

import { UserPageComponent } from '../user/user.page.component';
import { UserListComponent } from '../user/user.list.component';

export const routes: Routes = [
  {
    path: 'user/list',
    component: UserListComponent,
    runGuardsAndResolvers: 'always',
  },
  {
    path: 'user/:id',
    component: UserPageComponent,
    runGuardsAndResolvers: 'always',
  },
  {
    path: '',
    redirectTo: 'user/list',
    pathMatch: 'full',
  },
];
