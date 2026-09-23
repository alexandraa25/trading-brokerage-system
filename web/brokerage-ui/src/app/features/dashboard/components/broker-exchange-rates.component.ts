import { Component, input } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { DisplayExchangeRate } from '../../../core/models';

@Component({
  selector: 'app-broker-exchange-rates',
  imports: [DatePipe, DecimalPipe],
  styleUrl: './broker-exchange-rates.component.scss',
  template: `<section class="card">
    <p>CURSURI VALUTARE</p>
    <h2>Referințe BCE</h2>
    <span class="description"
      >Cursurile sunt folosite doar pentru afișarea valorilor din panoul brokerului. Evidența
      fiecărei execuții păstrează cursul istoric din momentul execuției.</span
    >
    <div class="rates">
      @for (rate of rates(); track rate.currency) {
        <article>
          <b>{{ rate.currency }}</b
          ><strong>1 {{ rate.currency }} = {{ rate.midRate | number: '1.4-6' }} EUR</strong
          ><small
            >Data cursului: {{ rate.rateDate | date: 'dd.MM.yyyy' }} · {{ rate.rateSource }}</small
          >
        </article>
      } @empty {
        <p>Nu există cursuri valutare disponibile.</p>
      }
    </div>
  </section>`,
})
export class BrokerExchangeRatesComponent {
  readonly rates = input<DisplayExchangeRate[]>([]);
}
