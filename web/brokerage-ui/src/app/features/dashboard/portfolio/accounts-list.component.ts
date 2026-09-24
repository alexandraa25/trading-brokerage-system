import { Component, input } from '@angular/core';
import { Account } from '../../../core/models';
@Component({
  selector: 'app-accounts-list',
  template: `<section class="card">
    <div class="head">
      <div>
        <p>CONTURI</p>
        <h2>Conturile mele</h2>
      </div>
      <span>{{ accounts().length }} conturi</span>
    </div>
    <div class="grid">
      @for (a of accounts(); track a.accountId) {
        <article>
          <div class="icon">€</div>
          <div>
            <b>{{ a.accountNumber }}</b>
            <p>{{ a.currency }} · {{ a.status }}</p>
          </div>
          <span class="status">{{ a.status }}</span>
        </article>
      } @empty {
        <p>Nu există conturi disponibile.</p>
      }
    </div>
  </section>`,
  styleUrl: './accounts-list.component.scss',
})
export class AccountsListComponent {
  accounts = input<Account[]>([]);
}
