import { Component, input, output, signal } from '@angular/core';
import { KycAuditEntry, OrderAuditEntry } from '../../core/models/admin.models';
import { AdminAuditComponent } from './admin-audit.component';
import { AdminOrderAuditComponent } from './admin-order-audit.component';

@Component({
  selector: 'app-admin-audit-workspace',
  imports: [AdminAuditComponent, AdminOrderAuditComponent],
  templateUrl: './admin-audit-workspace.component.html',
  styleUrl: './admin-audit-workspace.component.scss',
})
export class AdminAuditWorkspaceComponent {
  kycEntries = input<KycAuditEntry[]>([]);
  orderEntries = input<OrderAuditEntry[]>([]);
  tab = signal<'kyc' | 'orders'>('kyc');
  exportRequested = output<'kyc' | 'orders'>();
}
