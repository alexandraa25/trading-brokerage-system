import { Component, input, output, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CustomerProfile } from '../../../core/models';

@Component({
  selector: 'app-profile-kyc',
  imports: [DatePipe, FormsModule],
  styleUrl: './profile-kyc.component.scss',
  templateUrl: './profile-kyc.component.html',
})
export class ProfileKycComponent {
  profile = input<CustomerProfile | null>(null);
  passwordChange = output<{currentPassword:string;newPassword:string}>();
  currentPassword=''; newPassword=''; confirmPassword=''; localError=signal('');
  submit(){this.localError.set(''); if(this.newPassword.length<8){this.localError.set('Parola nouă trebuie să aibă cel puțin 8 caractere.');return;}if(this.newPassword!==this.confirmPassword){this.localError.set('Confirmarea parolei nu corespunde.');return;}if(this.currentPassword===this.newPassword){this.localError.set('Noua parolă trebuie să fie diferită.');return;}this.passwordChange.emit({currentPassword:this.currentPassword,newPassword:this.newPassword});this.currentPassword='';this.newPassword='';this.confirmPassword='';}
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
