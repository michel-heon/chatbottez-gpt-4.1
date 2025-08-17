export interface LogLevel {
  ERROR: 'error';
  WARN: 'warn';
  INFO: 'info';
  DEBUG: 'debug';
}

export interface LogEntry {
  timestamp: string;
  level: string;
  message: string;
  meta?: any;
}

class Logger {
  private logLevel: string;

  constructor() {
    this.logLevel = process.env.LOG_LEVEL || 'info';
  }

  private shouldLog(level: string): boolean {
    const levels = ['error', 'warn', 'info', 'debug'];
    const currentLevelIndex = levels.indexOf(this.logLevel);
    const messageLevel = levels.indexOf(level);
    
    return messageLevel <= currentLevelIndex;
  }

  private formatMessage(level: string, message: string, meta?: any): LogEntry {
    return {
      timestamp: new Date().toISOString(),
      level,
      message,
      ...(meta && { meta })
    };
  }

  private writeLog(logEntry: LogEntry): void {
    // In production, you might want to use Application Insights or another service
    if (process.env.NODE_ENV === 'production') {
      // Send to Application Insights or external logging service
      console.log(JSON.stringify(logEntry));
    } else {
      // Development logging with color coding
      const colorMap = {
        error: '\x1b[31m', // Red
        warn: '\x1b[33m',  // Yellow
        info: '\x1b[36m',  // Cyan
        debug: '\x1b[35m'  // Magenta
      };
      
      const resetColor = '\x1b[0m';
      const color = colorMap[logEntry.level as keyof typeof colorMap] || '';
      
      console.log(
        `${color}[${logEntry.timestamp}] ${logEntry.level.toUpperCase()}: ${logEntry.message}${resetColor}`,
        logEntry.meta ? logEntry.meta : ''
      );
    }
  }

  error(message: string, meta?: any): void {
    if (this.shouldLog('error')) {
      this.writeLog(this.formatMessage('error', message, meta));
    }
  }

  warn(message: string, meta?: any): void {
    if (this.shouldLog('warn')) {
      this.writeLog(this.formatMessage('warn', message, meta));
    }
  }

  info(message: string, meta?: any): void {
    if (this.shouldLog('info')) {
      this.writeLog(this.formatMessage('info', message, meta));
    }
  }

  debug(message: string, meta?: any): void {
    if (this.shouldLog('debug')) {
      this.writeLog(this.formatMessage('debug', message, meta));
    }
  }
}

export const logger = new Logger();
