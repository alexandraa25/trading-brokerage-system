/**
 * În producție, Nginx redirecționează /api către containerul ASP.NET Core.
 * În dezvoltare, Angular folosește proxy.conf.json pentru aceeași adresă.
 */
export const apiConfig = {
  baseUrl: '/api',
} as const;
