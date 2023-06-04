export {};

declare global {
  namespace NodeJS {
    interface ProcessEnv {
        ETHERNAL_EMAIL: string;
        ETHERNAL_PASSWORD: string;
        INFURA_SEPOLIA_URL: string;
        INFURA_SEPOLIA_PRIVATE_KEY: string;
        LOCALHOST_URL: string;
        LOCALHOST_CHAIN_ID: string;
    }
  }
}