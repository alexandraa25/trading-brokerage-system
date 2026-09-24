import { Injectable } from '@angular/core';
import { forkJoin } from 'rxjs';
import { ApiService } from '../api.service';

@Injectable({ providedIn: 'root' })
export class AdminDashboardService {
  constructor(private readonly api: ApiService) {}
  loadDashboard(days = 30) {
    return forkJoin({ kyc: this.api.adminKyc(), audit: this.api.adminKycAudit(), customers: this.api.adminCustomers(), overview: this.api.adminOverview(), analytics: this.api.adminAnalytics(days), users: this.api.adminUsers(), accounts: this.api.adminAccounts() });
  }
  updateKyc(kycId: number, status: string, rejectionReason?: string) { return this.api.updateKycStatus(kycId, status, rejectionReason); }
}