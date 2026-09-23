import { Component, input } from '@angular/core';
import { DatePipe } from '@angular/common';
import { CustomerProfile } from '../../../core/models';

@Component({
  selector: 'app-profile-kyc',
  imports: [DatePipe],
  styleUrl: './profile-kyc.component.scss',
  template: `@if (profile()) {
      <section class="profile-card">
        <div class="identity">
          <div class="avatar">{{ profile()!.firstName[0] }}{{ profile()!.lastName[0] }}</div>
          <div>
            <p>PROFIL CLIENT</p>
            <h2>{{ profile()!.firstName }} {{ profile()!.lastName }}</h2>
            <span>{{ profile()!.email }}</span>
          </div>
        </div>
        <div
          class="status-card"
          [class.approved]="profile()!.kycStatus === 'Approved'"
          [class.pending]="profile()!.kycStatus === 'Pending'"
          [class.rejected]="profile()!.kycStatus === 'Rejected'"
        >
          <span class="status-icon">{{
            profile()!.kycStatus === 'Approved'
              ? '✓'
              : profile()!.kycStatus === 'Rejected'
                ? '!'
                : '…'
          }}</span>
          <div>
            <b>{{ statusLabel(profile()!.kycStatus) }}</b
            ><small>{{ statusDescription(profile()!.kycStatus) }}</small>
          </div>
        </div>
      </section>
      <section class="details-card">
        <h2>Date verificare</h2>
        <div class="details">
          <article>
            <span>Stare client</span><b>{{ profile()!.customerStatus }}</b>
          </article>
          <article>
            <span>Document</span><b>{{ profile()!.documentType || 'Necompletat' }}</b>
          </article>
          <article>
            <span>Dosar creat</span
            ><b>{{
              profile()!.kycCreatedAt ? (profile()!.kycCreatedAt | date: 'dd.MM.yyyy') : '—'
            }}</b>
          </article>
          <article>
            <span>Verificat la</span
            ><b>{{
              profile()!.verifiedAt ? (profile()!.verifiedAt | date: 'dd.MM.yyyy') : 'În așteptare'
            }}</b>
          </article>
        </div>
        @if (profile()!.rejectionReason) {
          <div class="rejection">
            <b>Motivul respingerii</b><span>{{ profile()!.rejectionReason }}</span>
          </div>
        }
      </section>
    } @else {
      <section class="details-card empty"><b>Profilul nu a putut fi încărcat.</b></section>
    }`,
})
export class ProfileKycComponent {
  profile = input<CustomerProfile | null>(null);
  statusLabel(status: string) {
    return (
      (
        {
          Approved: 'Verificare aprobată',
          Pending: 'Verificare în așteptare',
          Rejected: 'Verificare respinsă',
          Missing: 'Verificare necesară',
        } as Record<string, string>
      )[status] ?? status
    );
  }
  statusDescription(status: string) {
    return status === 'Approved'
      ? 'Poți depune numerar și plasa ordine.'
      : status === 'Rejected'
        ? 'Verifică motivul și actualizează dosarul.'
        : 'Operațiunile sunt disponibile după aprobarea KYC.';
  }
}
