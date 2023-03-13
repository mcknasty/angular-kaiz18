import { Component, Input, OnInit } from '@angular/core';
import { UserDetailService } from './user.service';

import { UserRecord } from './UserRecord';

@Component({
  selector: 'user',
  templateUrl: './user.template.html',
  providers: [UserDetailService],
})
export class UserComponent implements OnInit {
  @Input('id') id: string;
  public user!: UserRecord;

  constructor(private Service: UserDetailService) {}

  ngOnInit() {
    const user = this.Service.getUser(this.id);
    console.log(user, this.id);
    this.user = new UserRecord(user);
  }
}
