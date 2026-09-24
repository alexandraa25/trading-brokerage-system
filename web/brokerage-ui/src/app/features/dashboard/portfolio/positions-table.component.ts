import { Component, input } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { Position } from '../../../core/models';
@Component({
  selector: 'app-positions-table',
  imports: [DecimalPipe],
  template: `<section class="card">
    <div class="title">
      <div>
        <p class="eyebrow">PORTOFOLIU</p>
        <h2>Pozițiile mele</h2>
      </div>
      <span>{{ positions().length }} active</span>
    </div>
    @if (positions().length) {
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Instrument</th>
              <th>Monedă</th>
              <th>Cantitate</th>
              <th>Preț mediu</th>
            </tr>
          </thead>
          <tbody>
            @for (p of positions(); track p.symbol) {
              <tr>
                <td>
                  <b>{{ p.symbol }}</b
                  ><br /><small>{{ p.instrumentName }}</small>
                </td>
                <td>{{ p.currency }}</td>
                <td>{{ p.quantity }}</td>
                <td>{{ p.averagePrice | number: '1.2-2' }}</td>
              </tr>
            }
          </tbody>
        </table>
      </div>
    } @else {
      <p class="empty">Nu există poziții deschise.</p>
    }
  </section>`,
  styleUrl: './positions-table.component.scss',
})
export class PositionsTableComponent {
  positions = input<Position[]>([]);
}
