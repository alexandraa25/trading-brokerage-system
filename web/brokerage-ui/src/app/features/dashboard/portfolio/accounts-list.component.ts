import { Component, input } from '@angular/core';
import { Account } from '../../../core/models';
@Component({
  selector: 'app-accounts-list',
  templateUrl: './accounts-list.component.html',
  styleUrl: './accounts-list.component.scss',
})
export class AccountsListComponent {
  accounts = input<Account[]>([]);
}
