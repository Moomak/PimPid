/**
 * Preload script for Onboarding BrowserWindow
 * Bridges renderer ↔ main process via contextBridge (contextIsolation: true)
 */

import { contextBridge, ipcRenderer } from "electron";

export interface OnboardingAPI {
  completeOnboarding: () => Promise<void>;
  getLang: () => Promise<string>;
}

contextBridge.exposeInMainWorld("onboardingAPI", {
  completeOnboarding: (): Promise<void> =>
    ipcRenderer.invoke("onboarding:complete"),

  getLang: (): Promise<string> =>
    ipcRenderer.invoke("onboarding:getLang"),
} satisfies OnboardingAPI);
