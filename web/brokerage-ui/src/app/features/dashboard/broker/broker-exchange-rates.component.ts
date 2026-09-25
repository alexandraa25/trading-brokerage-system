import { Component, input } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { DisplayExchangeRate } from '../../../core/models';

@Component({
  selector: 'app-broker-exchange-rates',
  imports: [DatePipe, DecimalPipe],
  styleUrl: './broker-exchange-rates.component.scss',
  templateUrl: './broker-exchange-rates.component.html',
})
export class BrokerExchangeRatesComponent {
  readonly rates = input<DisplayExchangeRate[]>([]);
}
