import { Component, input, output } from '@angular/core';
import { DatePipe } from '@angular/common';
import { BrokerNotification, CustomerNotification } from '../../../core/models';

@Component({
  selector: 'app-notification-panel',
  imports: [DatePipe],
  styleUrl: './notification-panel.component.scss',
  template: `<div class="notification-area">
    <button class="bell" (click)="toggle.emit()" aria-label="Notificări">
      <span>♢</span>
      @if (unreadCount()) {
        <b>{{ unreadCount() > 9 ? '9+' : unreadCount() }}</b>
      }
    </button>
    @if (open()) {
      <section class="panel">
        <header>
          <div>
            <p>NOTIFICĂRI</p>
            <h2>Activitate recentă</h2>
          </div>
          @if (unreadCount()) {
            <button class="read-all" (click)="markAll.emit()">Marchează toate citite</button>
          }
        </header>
        @if (notifications().length) {
          <div class="items">
            @for (item of notifications(); track notificationId(item)) {
              <button
                class="item"
                [class.unread]="!item.isRead"
                (click)="markRead.emit(notificationId(item))"
              >
                <span class="icon">{{ icon(item.notificationType) }}</span
                ><span
                  ><b>{{ item.title }}</b
                  ><small>{{ item.message }}</small
                  ><time>{{ item.createdAt | date: 'dd.MM, HH:mm' }}</time></span
                >
              </button>
            }
          </div>
        } @else {
          <div class="empty">
            <b>Nu ai notificări.</b
            ><span>Mesajele despre activitatea portofoliului vor apărea aici.</span>
          </div>
        }
      </section>
    }
  </div>`,
})
export class NotificationPanelComponent {
  notifications = input<Array<CustomerNotification | BrokerNotification>>([]);
  open = input(false);
  unreadCount = input(0);
  toggle = output<void>();
  markRead = output<number>();
  markAll = output<void>();
  notificationId(item: CustomerNotification | BrokerNotification) {
    return 'customerNotificationId' in item
      ? item.customerNotificationId
      : item.brokerNotificationId;
  }
  icon(type: string) {
    return (
      (
        {
          Deposit: '↓',
          Withdrawal: '↑',
          Kyc: '✓',
          Execution: '↗',
          CurrencyExchange: '⇄',
          OrderRejected: '!',
          NewOrder: '+',
          ExecutionBlocked: '!',
        } as Record<string, string>
      )[type] ?? '•'
    );
  }
}
