import { GenericObject } from './GenericObject';

export class UserRecord {
  id: string = '';
  name: string = '';
  age: number = 0;

  constructor(rec?: GenericObject | null) {
    if (rec !== null) {
      const { id, name, age } = rec;
      this.id = id;
      this.name = name;
      this.age = age;
    }
  }
}
