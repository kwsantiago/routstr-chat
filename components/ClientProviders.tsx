'use client';

import { ReactNode, useEffect } from 'react';
// import { NostrProvider } from '@/context/NostrContext';
import NostrProvider from '@/components/NostrProvider'
import dynamic from 'next/dynamic';
import { migrateStorageItems } from '@/utils/storageUtils';
import { InvoiceRecoveryProvider } from '@/components/InvoiceRecoveryProvider';

const DynamicNostrLoginProvider = dynamic(
  () => import('@nostrify/react/login').then((mod) => mod.NostrLoginProvider),
  { ssr: false }
);

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
const defaultRelays = [
    'wss://relay.chorus.community',
    'wss://relay.damus.io',
   'wss://relay.nostr.band',
    'wss://nos.lol'
  ];
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      staleTime: 60000, // 1 minute
      gcTime: Infinity,
    },
  },
});


export default function ClientProviders({ children }: { children: ReactNode }) {
  // Run storage migration on app startup
  useEffect(() => {
    migrateStorageItems();
  }, []);

  return (
    <DynamicNostrLoginProvider storageKey='nostr:login'>
      <NostrProvider relays={defaultRelays}>
        <QueryClientProvider client={queryClient}>
          <InvoiceRecoveryProvider>
            {children}
          </InvoiceRecoveryProvider>
        </QueryClientProvider>
      </NostrProvider>
    </DynamicNostrLoginProvider>
  );
}