// plan fetch + approve / apply-suggestion / request-changes mutations
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { Plan } from "@hawa/contracts";
import { api, ApiError } from "@/lib/api";

export const planKey = (id: string) => ["plan", id] as const;

export const usePlans = () => useQuery({ queryKey: ["plans"], queryFn: api.plans.list });

export const usePlan = (id: string) => useQuery({ queryKey: planKey(id), queryFn: () => api.plans.get(id), enabled: Boolean(id), retry: (n, e) => !(e instanceof ApiError && e.status === 404) && n < 2 });

export const usePlanComparison = (id: string) =>
  useQuery({ queryKey: [...planKey(id), "compare"], queryFn: () => api.plans.compare(id), enabled: Boolean(id) });

export function useDraftPlan(onDone: (p: Plan) => void) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (ward: string) => api.plans.draft({ ward }),
    onSuccess: (p) => {
      qc.setQueryData(planKey(p.id), p);
      qc.invalidateQueries({ queryKey: ["plans"] });
      onDone(p);
    },
  });
}

export function usePlanActions(id: string) {
  const qc = useQueryClient();
  const onSuccess = (p: Plan) => {
    qc.setQueryData(planKey(id), p);
    qc.invalidateQueries({ queryKey: ["plans"] });
  };
  return {
    applySuggestion: useMutation({ mutationFn: (commentId: string) => api.plans.applySuggestion(id, commentId), onSuccess }),
    approve: useMutation({ mutationFn: () => api.plans.approve(id), onSuccess }),
    requestChanges: useMutation({ mutationFn: (note: string) => api.plans.requestChanges(id, note), onSuccess }),
  };
}
