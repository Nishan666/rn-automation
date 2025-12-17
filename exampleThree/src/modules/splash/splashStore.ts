import { create } from 'zustand';
import { checkSession, Session } from './splashApi';

interface SplashState {
  session: Session | null;
  isLoading: boolean;
  error: string | null;
  checkSession: () => Promise<void>;
  clearError: () => void;
}

export const useSplashStore = create<SplashState>((set) => ({
  session: null,
  isLoading: false,
  error: null,
  checkSession: async () => {
    set({ isLoading: true, error: null });
    try {
      const session = await checkSession();
      set({ session, isLoading: false });
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to check session',
        isLoading: false,
      });
    }
  },
  clearError: () => set({ error: null }),
}));