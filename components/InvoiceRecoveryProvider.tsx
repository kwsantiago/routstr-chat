'use client';

import React, { useEffect, useRef } from 'react';
import { useInvoiceChecker } from '@/hooks/useInvoiceChecker';
import { useInvoiceSync } from '@/hooks/useInvoiceSync';
import { toast } from 'sonner';
import { MintQuoteState, MeltQuoteState } from '@cashu/cashu-ts';

interface InvoiceRecoveryProviderProps {
  children: React.ReactNode;
}

export const InvoiceRecoveryProvider: React.FC<InvoiceRecoveryProviderProps> = ({ children }) => {
  const { invoices, getPendingInvoices } = useInvoiceSync();
  const { triggerCheck } = useInvoiceChecker();
  const hasCheckedOnMount = useRef(false);
  const hasShownRecoveryToast = useRef(false);

  useEffect(() => {
    // Only run once on mount
    if (hasCheckedOnMount.current) return;
    hasCheckedOnMount.current = true;

    // Small delay to let the app initialize
    const checkTimer = setTimeout(() => {
      const pending = getPendingInvoices();
      
      if (pending.length > 0 && !hasShownRecoveryToast.current) {
        hasShownRecoveryToast.current = true;
        
        // Show recovery toast
        toast.info(
          `Found ${pending.length} pending invoice${pending.length > 1 ? 's' : ''} from previous session. Checking status...`,
          { duration: 5000 }
        );
        
        // Trigger check
        triggerCheck();
      }
    }, 2000);

    return () => clearTimeout(checkTimer);
  }, [getPendingInvoices, triggerCheck]);

  // Check for recently paid invoices on visibility change
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (!document.hidden) {
        // Check if any invoices were recently paid
        const recentlyPaid = invoices.filter(inv => {
          const isPaid = (inv.state as string) === 'PAID';
          const wasRecentlyPaid = inv.paidAt && (Date.now() - inv.paidAt) < 60000; // Within last minute
          return isPaid && wasRecentlyPaid;
        });

        if (recentlyPaid.length > 0) {
          recentlyPaid.forEach(inv => {
            const type = inv.type === 'mint' ? 'received' : 'sent';
            toast.success(`Invoice ${type} successfully (${inv.amount} sats)`);
          });
        }
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    return () => document.removeEventListener('visibilitychange', handleVisibilityChange);
  }, [invoices]);

  return <>{children}</>;
};