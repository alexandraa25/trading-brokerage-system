import { Component, input, output, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AdminAiResponse } from '../../core/models/admin.models';

@Component({
  selector: 'app-admin-ai-assistant',
  imports: [FormsModule],
  templateUrl: './admin-ai-assistant.component.html',
  styleUrl: './admin-ai-assistant.component.scss',
})
export class AdminAiAssistantComponent {
  readonly loading = input(false);
  readonly response = input<AdminAiResponse | null>(null);
  readonly error = input('');
  readonly asked = output<string>();
  readonly question = signal('');
  readonly suggestions = [
    'Care sunt cele mai importante aspecte operaționale de urmărit astăzi?',
    'Rezuma starea ordinelor și a dosarelor KYC.',
    'Ce arată indicatorii despre activitatea platformei?',
  ];

  submit(): void {
    const value = this.question().trim();
    if (value.length >= 5 && !this.loading()) this.asked.emit(value);
  }

  useSuggestion(question: string): void {
    this.question.set(question);
  }
}
