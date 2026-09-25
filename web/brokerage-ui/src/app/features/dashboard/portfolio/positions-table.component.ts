import { Component, input } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { Position } from '../../../core/models';
@Component({
  selector: 'app-positions-table',
  imports: [DecimalPipe],
  templateUrl: './positions-table.component.html',
  styleUrl: './positions-table.component.scss',
})
export class PositionsTableComponent {
  positions = input<Position[]>([]);
}
