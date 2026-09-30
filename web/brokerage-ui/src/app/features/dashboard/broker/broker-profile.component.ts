import { Component, output, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
@Component({
  selector: 'app-broker-profile',
  imports: [FormsModule],
  templateUrl: './broker-profile.component.html',
  styleUrl: './broker-profile.component.scss',
})
export class BrokerProfileComponent {
  passwordChange = output<{ currentPassword: string; newPassword: string }>();
  currentPassword = '';
  newPassword = '';
  confirmPassword = '';
  error = signal('');
  submit() {
    this.error.set('');
    if (this.newPassword.length < 8)
      this.error.set('Parola nouă trebuie să aibă cel puțin 8 caractere.');
    else if (this.newPassword !== this.confirmPassword)
      this.error.set('Confirmarea parolei nu corespunde.');
    else if (this.currentPassword === this.newPassword)
      this.error.set('Noua parolă trebuie să fie diferită.');
    else {
      this.passwordChange.emit({
        currentPassword: this.currentPassword,
        newPassword: this.newPassword,
      });
      this.currentPassword = '';
      this.newPassword = '';
      this.confirmPassword = '';
    }
  }
}
