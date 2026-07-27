# task_0002 — Project management feature

**Priority:** P1  **Depends on:** 0001  **FRs:** FR-PM-01, FR-PM-03, FR-PM-05

## Goal
Create/open/rename/delete video projects from a dashboard; scaffold the `projects` feature.

## Scope — `src/features/projects/`
```
api/fetchers.ts     # wrap services/storage.ts (create/list/rename/remove project)
api/queries.ts      # PROJECT_KEYS, useProjects, useProject(id)
api/mutations.ts    # useCreateProject, useRenameProject, useDeleteProject
schemas/project.schema.ts   # createProjectSchema: name(min1), type enum, language default 'vi'
types/project.types.ts      # Project, ProjectType='film'|'vlog'|'video', CreateProjectInput
components/project-dashboard.tsx   # list + "New project" (uses DataTable or card grid)
components/project-form.tsx        # RHF + zod create/rename (name, type, language)
components/project-card.tsx
index.ts            # barrel exports
```
- Route: `src/app/page.tsx` renders `ProjectDashboard` (project list is the app entry, SRD §2.1).
- Delete needs confirm; rename inline or via form.
- FR-PM-05 (P3): per-type default template (film/vlog/video) — seed scene defaults on create; can be stubbed with a `TODO`.

## Acceptance criteria
- Can create a project (name/type/language), see it listed, rename, delete.
- Data persists across reload (Dexie).
- Query invalidation refreshes the list after mutations.
- Uses the barrel; no deep feature imports.

## Notes
- Server data (projects) lives in TanStack Query, NOT Zustand (AGENTS.md).
