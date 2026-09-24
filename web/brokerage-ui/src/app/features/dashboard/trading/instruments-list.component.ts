import { Component, computed, input, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { Instrument } from '../../../core/models';

@Component({
  selector: 'app-instruments-list',
  imports: [DatePipe, DecimalPipe],
  styleUrl: './instruments-list.component.scss',
  template: `<section class="card">
    <div class="heading">
      <div>
        <p>PIAȚĂ</p>
        <h2>Instrumente disponibile</h2>
        <span>Active financiare care pot fi cumpărate sau vândute prin ordine.</span>
      </div>
      <strong>{{ filtered().length }} instrumente</strong>
    </div>
    <div class="filters">
      <input
        placeholder="Caută simbol sau nume"
        [value]="query()"
        (input)="setQuery($any($event.target).value)"
      /><select [value]="typeFilter()" (change)="setType($any($event.target).value)">
        <option value="ALL">Toate tipurile</option>
        <option value="Stock">Acțiuni</option>
        <option value="ETF">ETF-uri</option>
        <option value="Bond">Obligațiuni</option>
      </select>
    </div>
    <div class="grid">
      @for (instrument of filtered(); track instrument.instrumentId) {
        <article>
          <div class="instrument-head">
            <div>
              <b>{{ instrument.symbol }}</b
              ><span>{{ typeLabel(instrument.instrumentType) }}</span>
            </div>
            <strong
              >{{
                instrument.marketPrice === null ? '—' : (instrument.marketPrice | number: '1.2-4')
              }}
              {{ instrument.currency }}</strong
            >
          </div>
          <h3>{{ instrument.instrumentName }}</h3>
          <dl>
            <div>
              <dt>Emitent</dt>
              <dd>{{ instrument.issuerName }}</dd>
            </div>
            <div>
              <dt>Piață</dt>
              <dd>{{ instrument.marketName }}</dd>
            </div>
            <div>
              <dt>Ultima cotație</dt>
              <dd>
                {{
                  instrument.quoteDate
                    ? (instrument.quoteDate | date: 'dd.MM.yyyy')
                    : 'Indisponibilă'
                }}
              </dd>
            </div>
          </dl>
        </article>
      } @empty {
        <p class="empty">Nu am găsit instrumente pentru filtrul selectat.</p>
      }
    </div>
    <details class="guide">
      <summary>Ce înseamnă tipurile de instrumente?</summary>
      <p>
        <b>Acțiune:</b> o parte dintr-o companie. <b>ETF:</b> un pachet de instrumente urmărit
        într-o singură poziție. <b>Obligațiune:</b> un împrumut acordat unui emitent, de regulă cu
        dobândă.
      </p>
    </details>
    <small class="source">Prețurile sunt cotații simulate zilnice, în moneda instrumentului.</small>
  </section>`,
})
export class InstrumentsListComponent {
  instruments = input<Instrument[]>([]);
  query = signal('');
  typeFilter = signal('ALL');
  filtered = computed(() => {
    const search = this.query().trim().toLowerCase();
    return this.instruments().filter(
      (item) =>
        (this.typeFilter() === 'ALL' || item.instrumentType === this.typeFilter()) &&
        (!search ||
          `${item.symbol} ${item.instrumentName} ${item.issuerName}`
            .toLowerCase()
            .includes(search)),
    );
  });
  setQuery(value: string) {
    this.query.set(value);
  }
  setType(value: string) {
    this.typeFilter.set(value);
  }
  typeLabel(type: string) {
    return (
      ({ Stock: 'Acțiune', ETF: 'ETF', Bond: 'Obligațiune' } as Record<string, string>)[type] ??
      type
    );
  }
}
