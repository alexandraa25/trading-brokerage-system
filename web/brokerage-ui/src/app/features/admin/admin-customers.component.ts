import { Component, computed, input, output, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AdminCustomer } from '../../core/models';

@Component({
  selector: 'app-admin-customers',
  imports: [FormsModule],
  styleUrl: './admin-customers.component.scss',
  templateUrl: './admin-customers.component.html',
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
  createOpen = signal(false);
  readonly size = 10;
  filtered = () => {
    const q = this.query.trim().toLowerCase();
    return this.customers().filter(
      (c) =>
        (this.status === 'ALL' || c.customerStatus === this.status) &&
        (!q || `${c.firstName} ${c.lastName} ${c.email}`.toLowerCase().includes(q)),
    );
  };
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
    this.createOpen.set(false);
  }
  resetFilters() { this.query = ''; this.status = 'ALL'; this.page.set(0); }
}
