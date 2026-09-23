import { Component, input, output, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AdminAccount } from '../../core/models';

@Component({
  selector: 'app-admin-accounts', imports: [FormsModule],
  template: `<section class="card"><p>GESTIONARE CONTURI</p><h2>Conturi de tranzacționare</h2><div class="table-wrap"><table><thead><tr><th>Client</th><th>Cont</th><th>Monedă</th><th>Stare</th><th>Acțiuni</th></tr></thead><tbody>@for(account of accounts();track account.accountId){<tr><td>{{account.customerName}}<br><small>{{account.email}}</small></td><td>{{account.accountNumber}}</td><td>{{account.currency}}</td><td>{{account.status}}</td><td><button (click)="openDecision(account)">{{account.status==='Active'?'Suspendă':'Reactivează'}}</button></td></tr>}</tbody></table></div></section>@if(selected()){<div class="overlay"><section class="modal"><h2>{{nextStatus()==='Suspended'?'Suspendă':'Reactivează'}} contul</h2><p>{{selected()!.accountNumber}} · {{selected()!.customerName}}</p><label>Motiv obligatoriu<textarea [(ngModel)]="reason" placeholder="Explică decizia administrativă."></textarea></label><div><button class="secondary" (click)="selected.set(null)">Anulează</button><button [disabled]="reason.trim().length<3" (click)="confirm()">Confirmă</button></div></section></div>}`,
  styles: `.card{padding:26px;border-radius:14px;background:#fff;box-shadow:0 8px 26px #14213d12}.card>p{color:#08736f;font-size:11px;font-weight:800}.table-wrap{overflow:auto}table{width:100%;min-width:650px;border-collapse:collapse}th,td{padding:13px;text-align:left;border-bottom:1px solid #e7eef2}small,p{color:#637083}button{padding:9px 12px;border:0;border-radius:7px;background:#087c86;color:#fff;font-weight:700}.overlay{position:fixed;inset:0;z-index:30;display:grid;place-items:center;background:#09284b88}.modal{display:grid;gap:14px;width:min(420px,90vw);padding:25px;border-radius:14px;background:#fff}.modal h2{margin:0}.modal label{display:grid;gap:7px;font-weight:700}.modal textarea{min-height:90px;padding:10px;border:1px solid #ccdbe4;border-radius:8px;font:inherit}.modal div{display:flex;justify-content:flex-end;gap:9px}.secondary{background:#eaf1f5;color:#365466}`
})
export class AdminAccountsComponent {
  readonly accounts = input<AdminAccount[]>([]);
  readonly changed = output<{ id: number; status: string; reason: string }>();
  readonly selected = signal<AdminAccount | null>(null);
  reason = '';
  nextStatus() { return this.selected()?.status === 'Active' ? 'Suspended' : 'Active'; }
  openDecision(account: AdminAccount) { this.selected.set(account); this.reason = ''; }
  confirm() { const account = this.selected(); if (account) { this.changed.emit({ id: account.accountId, status: this.nextStatus(), reason: this.reason.trim() }); this.selected.set(null); } }
}
