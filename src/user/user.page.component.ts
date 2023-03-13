import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { GenericObject } from './GenericObject';

@Component({
  selector: 'user-page',
  templateUrl: './user.page.template.html',
})
export class UserPageComponent implements OnInit {
  id: string;
  userMap: GenericObject;
  constructor(private route: ActivatedRoute) {}

  ngOnInit() {
    this.route.params.subscribe((params) => {
      this.id = params.id;
    });
  }
}
