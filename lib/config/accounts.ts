export interface accountconfig {
  name: string;
  email: string;
  environment: "prod" | "staging" | "dev" | "shared";
  helloworldmessage: string;
  memorysize: number;
  timeout: number;
}

export const accounts: Record<string, accountconfig> = {
  dev: {
    name: "development",
    email: "testawsrahardja+dev@gmail.com", // replace with your email
    environment: "dev",
    helloworldmessage: "hello from development! 💻",
    // 🇸🇬 singapore version: "hello from singapore development! 🇸🇬💻",
    memorysize: 128, // minimal for cost optimization
    timeout: 10,
  },
  staging: {
    name: "staging",
    email: "testawsrahardja+staging@gmail.com", // replace with your email
    environment: "staging",
    helloworldmessage: "hello from staging! 🧪",
    // 🇸🇬 singapore version: "hello from singapore staging! 🇸🇬🧪",
    memorysize: 256,
    timeout: 15,
  },
  shared: {
    name: "shared-services",
    email: "testawsrahardja+shared@gmail.com", // replace with your email
    environment: "shared",
    helloworldmessage: "hello from shared services! 🔧",
    // 🇸🇬 singapore version: "hello from singapore shared services! 🇸🇬🔧",
    memorysize: 256,
    timeout: 15,
  },
  prod: {
    name: "production",
    email: "testawsrahardja+prod@gmail.com", // replace with your email
    environment: "prod",
    helloworldmessage: "hello from production! 🚀",
    // 🇸🇬 singapore version: "hello from singapore production! 🇸🇬🚀",
    memorysize: 512,
    timeout: 30,
  },
};

export const core_accounts = {
  management: "testawsrahardja@gmail.com", // replace with your email
  audit: "testawsrahardja+audit@gmail.com", // replace with your email
  logarchive: "testawsrahardja+logs@gmail.com", // replace with your email
};
