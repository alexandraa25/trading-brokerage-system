import { Component, input, output } from '@angular/core';

@Component({
  selector: 'app-portfolio-currency-filter',
  styleUrl: './portfolio-currency-filter.component.scss',
  templateUrl: './portfolio-currency-filter.component.html',
})
export class PortfolioCurrencyFilterComponent {
  currencies = input<string[]>([]);
  selected = input('ALL');
  changed = output<string>();
}
