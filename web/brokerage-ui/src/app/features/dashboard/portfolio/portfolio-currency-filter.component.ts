import { Component, input, output } from '@angular/core';

@Component({
  selector: 'app-portfolio-currency-filter',
  styleUrl: './portfolio-currency-filter.component.scss',
  template: `<section class="filter-card">
    <div>
      <p>FILTRU PORTOFOLIU</p>
      <h2>Active în moneda reală</h2>
      <span>Alege o monedă pentru a vedea doar pozițiile și numerarul denominate în aceasta.</span>
    </div>
    <label
      >Monedă<select [value]="selected()" (change)="changed.emit($any($event.target).value)">
        <option value="ALL">Toate monedele</option>
        @for (currency of currencies(); track currency) {
          <option [value]="currency">{{ currency }}</option>
        }
      </select></label
    >
  </section>`,
})
export class PortfolioCurrencyFilterComponent {
  currencies = input<string[]>([]);
  selected = input('ALL');
  changed = output<string>();
}
