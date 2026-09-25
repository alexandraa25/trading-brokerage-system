import { Component, input } from '@angular/core';
import { DecimalPipe } from '@angular/common';
@Component({
  selector: 'app-portfolio-summary',
  imports: [DecimalPipe],
  templateUrl: './portfolio-summary.component.html',
  styleUrl: './portfolio-summary.component.scss',
})
export class PortfolioSummaryComponent {
  accounts = input(0);
  positions = input(0);
  total = input(0);
  invested = input(0);
  profit = input(0);
  percent = input(0);
  currency = input('EUR');
}
