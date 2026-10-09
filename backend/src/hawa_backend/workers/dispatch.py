"""Dispatch saga choreography and HawaTag spray matching."""
from datetime import datetime, timezone
from typing import Dict, List, Optional, Tuple
from hawa_contracts import SprayPacket, uuid7
from hawa_contracts.enums import TaskStatus
from hawa_contracts.events.task import TaskDispatched, TaskDone
from hawa_contracts.events.commands import CmdVerifyRun


class DispatchSagaManager:
    """Orchestrates plan release, task notifications, and automatic spray completion."""

    def __init__(self):
        # In-memory task tracker: task_id -> task dict
        self._active_tasks: Dict[str, Dict] = {}

    def release_plan_tasks(self, plan_id: str, tasks: List[Dict]) -> List[TaskDispatched]:
        """Release approved tasks to driver phones and alert queue."""
        dispatched_events = []
        for t in tasks:
            task_id = t["id"]
            self._active_tasks[task_id] = {
                "task_id": task_id,
                "plan_id": plan_id,
                "asset_id": t["asset_id"],
                "status": TaskStatus.DISPATCHED,
                "place": t["place"],
            }
            dispatched_events.append(
                TaskDispatched(
                    task_id=task_id,
                    plan_id=plan_id,
                    asset_id=t["asset_id"],
                    place=t["place"],
                    target_time=t.get("time", "06:30"),
                    scheduled_start=t.get("scheduled_start", "06:00"),
                    scheduled_end=t.get("scheduled_end", "08:00"),
                    status=TaskStatus.DISPATCHED,
                )
            )
        return dispatched_events

    def match_spray_event(self, spray: SprayPacket) -> Optional[Tuple[TaskDone, CmdVerifyRun]]:
        """Match incoming HawaTag spray telemetry to active task for that asset."""
        matching_task = None
        for task in self._active_tasks.values():
            if task["asset_id"] == spray.asset and task["status"] in (TaskStatus.DISPATCHED, TaskStatus.IN_PROGRESS):
                matching_task = task
                break

        if not matching_task:
            return None

        task_id = matching_task["task_id"]

        if spray.action == "start":
            matching_task["status"] = TaskStatus.IN_PROGRESS
            return None
        elif spray.action == "stop":
            matching_task["status"] = TaskStatus.DONE
            intervention_id = uuid7()
            
            task_done = TaskDone(
                task_id=task_id,
                plan_id=matching_task["plan_id"],
                asset_id=spray.asset,
                completed_at=spray.ts,
                intervention_id=intervention_id,
                source="hawa_tag",
            )
            
            verify_cmd = CmdVerifyRun(
                intervention_id=intervention_id,
                as_of=spray.ts,
            )
            return task_done, verify_cmd

        return None
