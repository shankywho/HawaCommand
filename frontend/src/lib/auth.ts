// Amplify Auth config (Cognito user pool). Without pool env vars the console runs unauthenticated (demo/mock mode).
import { Amplify } from "aws-amplify";
import { fetchAuthSession, getCurrentUser, signIn, signOut } from "aws-amplify/auth";

const userPoolId = process.env.NEXT_PUBLIC_COGNITO_USER_POOL_ID;
const userPoolClientId = process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID;

export const AUTH_ENABLED = Boolean(userPoolId && userPoolClientId);

let configured = false;
export function configureAuth() {
  if (configured || !AUTH_ENABLED) return;
  Amplify.configure({ Auth: { Cognito: { userPoolId: userPoolId!, userPoolClientId: userPoolClientId! } } }, { ssr: false });
  configured = true;
}

export async function getIdToken(): Promise<string | undefined> {
  if (!AUTH_ENABLED) return undefined;
  configureAuth();
  try {
    const s = await fetchAuthSession();
    return s.tokens?.idToken?.toString();
  } catch {
    return undefined;
  }
}

export async function currentOfficer(): Promise<{ username: string } | null> {
  if (!AUTH_ENABLED) return { username: "demo-officer" };
  configureAuth();
  try {
    const u = await getCurrentUser();
    return { username: u.username };
  } catch {
    return null;
  }
}

export async function login(username: string, password: string) {
  configureAuth();
  return signIn({ username, password });
}

export async function logout() {
  if (!AUTH_ENABLED) return;
  configureAuth();
  await signOut();
}
