import { Component, computed, input, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { Instrument, InstrumentQuotePoint } from '../../../core/models';
import { ApiService } from '../../../core/api.service';
import { InstrumentPriceChartComponent } from './instrument-price-chart.component';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-instruments-list',
  imports: [DatePipe, DecimalPipe, FormsModule, InstrumentPriceChartComponent],
  styleUrl: './instruments-list.component.scss',
  templateUrl: './instruments-list.component.html',
})
export class InstrumentsListComponent {
  constructor(private readonly api: ApiService) {}
  instruments = input<Instrument[]>([]);
  selected = signal<Instrument | null>(null);
  quotes = signal<InstrumentQuotePoint[]>([]);
  favorites=signal<number[]>([]); priceAlerts=signal<{customerPriceAlertId:number;symbol:string;direction:string;targetPrice:number;isActive:boolean;triggeredAt:string|null}[]>([]); alertInstrument=signal<Instrument|null>(null); alertDirection='Above'; alertPrice:number|null=null;
  ngOnInit(){this.api.watchlist().subscribe({next:items=>this.favorites.set(items)});this.loadAlerts();}
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
  openHistory(instrument: Instrument) { this.selected.set(instrument); this.loadQuotes(30); }
  loadQuotes(days: number) { const instrument = this.selected(); if (instrument) this.api.instrumentQuotes(instrument.instrumentId, days).subscribe({ next: points => this.quotes.set(points), error: () => this.quotes.set([]) }); }
  isFavorite(id:number){return this.favorites().includes(id);} toggleFavorite(id:number){const exists=this.isFavorite(id);(exists?this.api.removeWatchlist(id):this.api.addWatchlist(id)).subscribe({next:()=>this.favorites.update(items=>exists?items.filter(x=>x!==id):[...items,id])});}
  openAlert(instrument:Instrument){this.alertInstrument.set(instrument);this.alertPrice=instrument.marketPrice;}
  saveAlert(){const instrument=this.alertInstrument();if(instrument&&this.alertPrice&&this.alertPrice>0)this.api.createPriceAlert(instrument.instrumentId,this.alertDirection,this.alertPrice).subscribe({next:()=>{this.alertInstrument.set(null);this.loadAlerts();}});}
  favoriteInstruments(){return this.instruments().filter(x=>this.isFavorite(x.instrumentId));} loadAlerts(){this.api.priceAlerts().subscribe({next:items=>this.priceAlerts.set(items)});} removeAlert(id:number){this.api.deletePriceAlert(id).subscribe({next:()=>this.loadAlerts()});}
  typeLabel(type: string) {
    return (
      ({ Stock: 'Acțiune', ETF: 'ETF', Bond: 'Obligațiune' } as Record<string, string>)[type] ??
      type
    );
  }
}
