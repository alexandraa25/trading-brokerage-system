import { Component, computed, input, output, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AdminCustomer } from '../../core/models';

@Component({
  selector: 'app-admin-customers',
  imports: [FormsModule],
  styleUrl: './admin-customers.component.scss',
  template: `<section class="create-card">
      <b>CLIENT NOU</b>
      <form (ngSubmit)="submitCustomer()">
        <input
          name="firstName"
          [(ngModel)]="newCustomer.firstName"
          placeholder="Prenume"
          required
        /><input
          name="lastName"
          [(ngModel)]="newCustomer.lastName"
          placeholder="Nume"
          required
        /><input
          name="email"
          [(ngModel)]="newCustomer.email"
          placeholder="Email"
          type="email"
          required
        /><input
          name="password"
          [(ngModel)]="newCustomer.password"
          placeholder="Parolă inițială"
          type="password"
          minlength="8"
          required
        /><button>Adaugă client</button>
      </form>
    </section>
    <section class="card">
      <div class="heading">
        <div>
          <p>ADMINISTRARE</p>
          <h2>Clienți</h2>
          <span>Gestionează accesul și verifică situația fiecărui client.</span>
        </div>
        <strong>{{ filtered().length }} clienți</strong>
      </div>
      <div class="filters">
        <input
          [(ngModel)]="query"
          (ngModelChange)="page.set(0)"
          placeholder="Caută nume sau email"
        /><select [(ngModel)]="status" (ngModelChange)="page.set(0)">
          <option value="ALL">Toate stările</option>
          <option value="Active">Activi</option>
          <option value="Inactive">Inactivi</option>
          <option value="Blocked">Blocați</option>
        </select>
      </div>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Client</th>
              <th>KYC</th>
              <th>Conturi</th>
              <th>Stare profil</th>
              <th>Acțiuni</th>
            </tr>
          </thead>
          <tbody>
            @for (customer of paged(); track customer.customerId) {
              <tr>
                <td>
                  <b>{{ customer.firstName }} {{ customer.lastName }}</b
                  ><br /><small>{{ customer.email }}</small>
                </td>
                <td>
                  <span class="badge">{{ kycLabel(customer.kycStatus) }}</span>
                </td>
                <td>{{ customer.accountsCount }} · {{ customer.accountStatus ?? '—' }}</td>
                <td>
                  <span class="badge" [class.blocked]="customer.customerStatus === 'Blocked'">{{
                    customer.customerStatus
                  }}</span>
                </td>
                <td>
                  <select
                    [ngModel]="customer.customerStatus"
                    (ngModelChange)="
                      statusChange.emit({ customerId: customer.customerId, status: $event })
                    "
                  >
                    <option value="Active">Activează</option>
                    <option value="Inactive">Dezactivează</option>
                    <option value="Blocked">Blochează</option></select
                  ><button
                    type="button"
                    class="details"
                    (click)="details.emit(customer.customerId)"
                  >
                    Detalii
                  </button>
                </td>
              </tr>
            }
          </tbody>
        </table>
      </div>
      @if (!filtered().length) {
        <p class="empty">Nu există clienți pentru filtrele alese.</p>
      }
      @if (pages() > 1) {
        <div class="pagination">
          <button [disabled]="page() === 0" (click)="page.set(page() - 1)">Anterior</button
          ><span>Pagina {{ page() + 1 }} din {{ pages() }}</span
          ><button [disabled]="page() + 1 >= pages()" (click)="page.set(page() + 1)">
            Următor
          </button>
        </div>
      }
    </section>`,
})
export class AdminCustomersComponent {
  readonly customers = input<AdminCustomer[]>([]);
  readonly statusChange = output<{ customerId: number; status: string }>();
  readonly createCustomer = output<{
    firstName: string;
    lastName: string;
    email: string;
    password: string;
    documentType: string;
  }>();
  readonly details = output<number>();
  newCustomer = {
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    documentType: 'Carte de identitate',
  };
  query = '';
  status = 'ALL';
  page = signal(0);
  readonly size = 10;
  filtered = computed(() => {
    const q = this.query.trim().toLowerCase();
    return this.customers().filter(
      (c) =>
        (this.status === 'ALL' || c.customerStatus === this.status) &&
        (!q || `${c.firstName} ${c.lastName} ${c.email}`.toLowerCase().includes(q)),
    );
  });
  pages() {
    return Math.max(1, Math.ceil(this.filtered().length / this.size));
  }
  paged() {
    return this.filtered().slice(this.page() * this.size, (this.page() + 1) * this.size);
  }
  kycLabel(v: string) {
    return (
      (
        { Pending: 'În așteptare', Approved: 'Aprobat', Rejected: 'Respins' } as Record<
          string,
          string
        >
      )[v] ?? v
    );
  }
  submitCustomer() {
    this.createCustomer.emit(this.newCustomer);
    this.newCustomer = {
      firstName: '',
      lastName: '',
      email: '',
      password: '',
      documentType: 'Carte de identitate',
    };
  }
}
