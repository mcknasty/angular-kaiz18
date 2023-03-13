import { Component, OnInit } from '@angular/core';
import { GenericObject } from './GenericObject';
import { UserDetailService } from './user.service';

@Component({
  selector: 'user-list',
  templateUrl: './user.list.template.html',
  providers: [UserDetailService],
})
export class UserListComponent implements OnInit {
  userMap: GenericObject[];

  constructor(private Service: UserDetailService) {}

  ngOnInit() {
    this.Service.getUserList().subscribe((users) => {
      this.userMap = users;
      console.log(this.userMap);
    });
  }
}
