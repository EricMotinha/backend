@Global()
@Module({
  imports: [
    LoggerModule.forRoot({
      pinoHttp: process.env.NODE_ENV === 'production'
        ? { level: process.env.LOG_LEVEL ?? 'info' }
        : { level: 'debug', transport: { target: 'pino-pretty', options: { colorize: true } } },
    }),
    ThrottlerModule.forRoot({
      ttl: 60,
      limit: 120,
      ignoreUserAgents: [/ELB-HealthChecker/i],
    }),
  ],
  providers: [
    DbService,
    {
      provide: 'PG_POOL',
      useFactory: () => {
        const cs = process.env.DATABASE_URL;
        if (!cs) throw new Error('DATABASE_URL not set');
        return new Pool({
          connectionString: cs,
          ssl: { rejectUnauthorized: false },
          max: 10,
          idleTimeoutMillis: 30000,
        });
      },
    },
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
  // não precisa exportar LoggerModule aqui
  exports: [DbService, 'PG_POOL'],
})
export class AppModule {}
