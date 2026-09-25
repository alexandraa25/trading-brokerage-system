import { Component, output, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../core/api.service';
@Component({
  selector: 'app-login',
  imports: [FormsModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss',
})
export class LoginComponent {
  authenticated = output<void>();
  email = 'customer.demo@brokerage.local';
  password = 'DemoCustomer!2026';
  loading = signal(false);
  error = signal('');
  success = signal('');
  registering = signal(false);
  registration = {
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    documentType: 'Carte de identitate',
  };
  constructor(private api: ApiService) {}
  login() {
    this.loading.set(true);
    this.api.login(this.email, this.password).subscribe({
      next: (r) => {
        localStorage.setItem('brokerage_token', r.token);
        localStorage.setItem('brokerage_role', r.role);
        this.authenticated.emit();
      },
      error: () => {
        this.error.set('Date invalide sau API-ul nu rulează.');
        this.loading.set(false);
      },
    });
  }
  register() {
    this.loading.set(true);
    this.error.set('');
    this.success.set('');
    this.api
      .register({ ...this.registration, documentType: this.registration.documentType || null })
      .subscribe({
        next: () => {
          this.email = this.registration.email;
          this.password = this.registration.password;
          this.registering.set(false);
          this.success.set('Contul a fost creat. Autentifică-te pentru a vedea starea KYC.');
          this.loading.set(false);
        },
        error: (error) => {
          this.error.set(error.error?.detail ?? 'Contul nu a putut fi creat.');
          this.loading.set(false);
        },
      });
  }
}
