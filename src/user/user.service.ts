import { Injectable } from '@angular/core';

import { Observable, of } from 'rxjs';

import { GenericObject } from './GenericObject';
import { UserRecord } from './UserRecord';

import { Users } from './users.data';

@Injectable()
export class UserDetailService {
  users: GenericObject;
  constructor() {
    const path = 'users.data.json';
    this.users = Users;
  }

  // Returns a clone which caller may modify safely
  getUser(id: string): UserRecord {
    const idFound: boolean = Object.keys(this.users).includes(id);
    if (typeof id === 'string' && idFound) {
      return this.users[id];
    }
    return null;
  }

  getUserList(): Observable<GenericObject[]> {
    const userMap: GenericObject[] = [];
    Object.keys(this.users).forEach((value) => {
      userMap.push({ name: this.users[value].name, id: value });
    });
    return of(userMap) as Observable<GenericObject[]>;
  }
}
