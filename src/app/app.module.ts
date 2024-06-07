import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import {} from '@angular/common/http';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { AppComponent } from './app.component';
import { RoutingModule } from '../route/routes.module';
import { UserModule } from '../user/user.module';
import { UserDetailService } from '../user/user.service';

const imports = [
  BrowserModule,
  RoutingModule,
  HttpClientModule,
  BrowserAnimationsModule,
  CommonModule,
  UserModule,
];

@NgModule({
  declarations: [AppComponent],
  imports: [...imports],
  providers: [UserDetailService],
  bootstrap: [AppComponent],
})
export class AppModule {}
