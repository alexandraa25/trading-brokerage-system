import { Component, input, output, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AdminAiResponse } from '../../../core/models/admin.models';

@Component({
  selector: 'app-customer-ai-assistant',
  imports: [FormsModule],
  templateUrl: './customer-ai-assistant.component.html',
  styleUrl: './customer-ai-assistant.component.scss',
})
export class CustomerAiAssistantComponent {
  readonly loading = input(false);
  readonly response = input<AdminAiResponse | null>(null);
  readonly error = input('');
  readonly asked = output<string>();
  readonly question = signal('');
  readonly suggestions = [
    'De ce am profit sau pierdere în portofoliu?',
    'Cum influențează cursul BCE valoarea mea afișată în EUR?',
    'Explică-mi pe scurt structura portofoliului meu.',
  ];
  submit() {
    const value = this.question().trim();
    if (value.length >= 5 && !this.loading()) this.asked.emit(value);
  }
}
