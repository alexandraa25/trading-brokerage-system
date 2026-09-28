import { DatePipe } from '@angular/common';
import { Component, input, output, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AdminSession, AdminUser } from '../../core/models';

@Component({
  selector: 'app-admin-users',
  imports: [DatePipe, FormsModule],
  styleUrl: './admin-users.component.scss',
  templateUrl: './admin-users.component.html',
})
export class AdminUsersComponent {
  users = input<AdminUser[]>([]);
  sessions = input<AdminSession[]>([]);
  statusChange = output<{ id: string; isActive: boolean }>();
  passwordReset = output<{ id: string; password: string }>();
  signOutAll = output<string>();
  create = output<{ email: string; password: string; role: string }>();
  newUser = { email: '', password: '', role: 'Broker' };
  resetId = '';
  newPassword = '';
  createOpen = signal(false);
  query = '';
  role = 'ALL';
  active = 'ALL';
  page = signal(0);
  readonly size = 10;
  filtered = () => {
    const q = this.query.toLowerCase().trim();
    return this.users().filter(
      (x) =>
        (!q || x.email.toLowerCase().includes(q)) &&
        (this.role === 'ALL' || x.role === this.role) &&
        (this.active === 'ALL' || (this.active === 'ACTIVE') === x.isActive),
    );
  };
  pages() {
    return Math.max(1, Math.ceil(this.filtered().length / this.size));
  }
  paged() {
    return this.filtered().slice(this.page() * this.size, (this.page() + 1) * this.size);
  }
  resetFilters() {
    this.query = '';
    this.role = 'ALL';
    this.active = 'ALL';
    this.page.set(0);
  }
  selectForReset(id: string) {
    this.resetId = id;
    this.newPassword = '';
  }
  savePassword() {
    this.passwordReset.emit({ id: this.resetId, password: this.newPassword });
    this.resetId = '';
  }
  submitCreate() {
    this.create.emit({ ...this.newUser });
    this.newUser = { email: '', password: '', role: 'Broker' };
    this.createOpen.set(false);
  }
  deviceLabel(deviceInfo: string | null) {
    if (!deviceInfo) return 'Dispozitiv necunoscut';
    if (deviceInfo.includes('Edg/')) return 'Microsoft Edge pe Windows';
    if (deviceInfo.includes('Chrome/')) return 'Google Chrome pe Windows';
    if (deviceInfo.includes('Firefox/')) return 'Mozilla Firefox';
    if (deviceInfo.includes('Safari/')) return 'Safari';
    return 'Browser web';
  }
}
