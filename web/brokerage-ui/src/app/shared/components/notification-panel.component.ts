import { Component, input, output } from '@angular/core';
import { DatePipe } from '@angular/common';
import { BrokerNotification, CustomerNotification } from '../../core/models';

@Component({
  selector: 'app-notification-panel',
  imports: [DatePipe],
  styleUrl: './notification-panel.component.scss',
  templateUrl: './notification-panel.component.html',
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
