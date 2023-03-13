import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { UserPageComponent } from './user.page.component';
import { UserListComponent } from './user.list.component';
import { UserComponent } from './user.component';
import { UserDetailService } from './user.service';

@NgModule({
  declarations: [UserPageComponent, UserListComponent, UserComponent],
  providers: [UserDetailService],
  imports: [CommonModule],
})
export class UserModule {}
