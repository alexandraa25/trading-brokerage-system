import { Component, input } from '@angular/core';
import { DatePipe } from '@angular/common';
import { AdminOverview } from '../../core/models';

@Component({
  selector: 'app-admin-overview',
  imports: [DatePipe],
  styleUrl: './admin-overview.component.scss',
  templateUrl: './admin-overview.component.html',
})
export class AdminOverviewComponent {
  readonly data = input<AdminOverview | null>(null);
}
