SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[WFTasklist] as
    /***********************************************************
    * CREATED BY:	CC 2/1/08 - Provides consolidated list of tasks/steps that can be started
    * MODIFIED By:  CC 6/5/08 - Issue #128562 - Corrected logic error
	*				CC 6/13/08 - Issue #128655 - Re-wrote for maintainability and correct logic errors
    *				
    *
    *****************************************************/
WITH AvailableTasks_CTE (Task, Checklist, Company) AS
(
	--(A) A required task may be started if all preceeding required tasks are completed (enforce order enabled)
	SELECT DISTINCT (MIN(WFChecklistTasks.Task) OVER (PARTITION BY WFChecklistTasks.Checklist, WFChecklistTasks.Company)) AS Task, WFChecklistTasks.Checklist, WFChecklistTasks.Company
		FROM WFChecklistTasks
		INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
		INNER JOIN WFChecklists ON WFChecklistTasks.Checklist = WFChecklists.Checklist AND WFChecklistTasks.Company = WFChecklists.Company
		WHERE WFChecklists.EnforceOrder = 'Y' AND WFStatusCodes.StatusType <> 2 
			AND (
					(WFChecklistTasks.IsTaskRequired = 'N' AND NOT EXISTS (SELECT TOP 1 1 FROM WFChecklistTasks WHERE WFChecklistTasks.Checklist = WFChecklists.Checklist AND WFChecklistTasks.IsTaskRequired = 'Y'))
					OR 
					(WFChecklistTasks.IsTaskRequired = 'Y')
				)
	UNION ALL
	--(B) An optional task may be started at any time (where there exist required tasks and enforce order is enabled)
	SELECT WFChecklistTasks.Task, WFChecklistTasks.Checklist, WFChecklistTasks.Company
		FROM WFChecklistTasks
		INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
		INNER JOIN WFChecklists ON WFChecklistTasks.Checklist = WFChecklists.Checklist AND WFChecklistTasks.Company = WFChecklists.Company	
		WHERE WFChecklists.EnforceOrder = 'Y' AND WFStatusCodes.StatusType <> 2 
			AND (WFChecklistTasks.IsTaskRequired = 'N' AND EXISTS (SELECT TOP 1 1 FROM WFChecklistTasks WHERE WFChecklistTasks.Checklist = WFChecklists.Checklist AND WFChecklistTasks.IsTaskRequired = 'Y'))
)

(
SELECT WFChecklistTasks.Company, 'Task' as [Type], WFChecklistTasks.KeyID, WFChecklistTasks.Task, WFChecklistTasks.Checklist, '' as [Step], WFChecklistTasks.Summary, WFChecklistTasks.IsTaskRequired as [Required], WFChecklistTasks.UseEmail, WFChecklistTasks.[Status], WFChecklistTasks.[Description], WFChecklistTasks.TaskType as [ItemType], WFChecklistTasks.VPName, WFChecklistTasks.AssignedTo, WFChecklistTasks.AssignedOn, WFChecklistTasks.DueDate, WFChecklistTasks.CompletedBy, WFChecklistTasks.CompletedOn, WFChecklistTasks.AddedBy, WFChecklistTasks.AddedOn, WFChecklistTasks.ChangedBy, WFChecklistTasks.ChangedOn, WFChecklistTasks.Notes, WFChecklistTasks.ReportID, WFChecklistTasks.UniqueAttchID 
	FROM WFChecklistTasks
	INNER JOIN AvailableTasks_CTE ON WFChecklistTasks.Checklist = AvailableTasks_CTE.Checklist AND WFChecklistTasks.Task = AvailableTasks_CTE.Task AND WFChecklistTasks.Company = AvailableTasks_CTE.Company
)

UNION ALL

--(C) A required step may be started if all preceeding required steps are completed, and the task can be started (enforce order enabled)
(
SELECT WFChecklistSteps.Company, 'Step' as [Type], WFChecklistSteps.KeyID, WFChecklistSteps.Task, WFChecklistSteps.Checklist, WFChecklistSteps.Step as [Step], WFChecklistSteps.Summary, WFChecklistSteps.IsStepRequired as [Required], WFChecklistSteps.UseEmail, WFChecklistSteps.[Status], WFChecklistSteps.[Description], WFChecklistSteps.StepType as [ItemType], WFChecklistSteps.VPName, WFChecklistSteps.AssignedTo, WFChecklistSteps.AssignedOn, WFChecklistSteps.DueDate, WFChecklistSteps.CompletedBy, WFChecklistSteps.CompletedOn, WFChecklistSteps.AddedBy, WFChecklistSteps.AddedOn, WFChecklistSteps.ChangedBy, WFChecklistSteps.ChangedOn, WFChecklistSteps.Notes, WFChecklistSteps.ReportID, WFChecklistSteps.UniqueAttchID 
	FROM WFChecklistSteps 
	INNER JOIN
		(SELECT DISTINCT (MIN(WFChecklistSteps.Step) OVER (PARTITION BY WFChecklistSteps.Checklist, WFChecklistSteps.Company)) AS Step, WFChecklistSteps.Task, WFChecklistSteps.Checklist, WFChecklistSteps.Company
			FROM WFChecklistSteps 
			INNER JOIN WFStatusCodes ON WFChecklistSteps.Status = WFStatusCodes.StatusID
			INNER JOIN WFChecklists ON WFChecklistSteps.Checklist = WFChecklists.Checklist AND WFChecklistSteps.Company = WFChecklists.Company	
			INNER JOIN AvailableTasks_CTE ON WFChecklistSteps.Checklist = AvailableTasks_CTE.Checklist AND WFChecklistSteps.Task = AvailableTasks_CTE.Task
			WHERE (
					WFChecklistSteps.IsStepRequired = 'Y'  
					OR
					(WFChecklistSteps.IsStepRequired = 'N' AND WFStatusCodes.StatusType <> 2 AND NOT EXISTS (SELECT TOP 1 1 
																													FROM WFChecklistTasks 
																													WHERE WFChecklistTasks.Checklist = WFChecklists.Checklist 
																														AND WFChecklistTasks.IsTaskRequired = 'Y'))
				  )
				AND WFStatusCodes.StatusType <> 2)
		AS WFChecklistSteps_MinimumReq ON WFChecklistSteps.Checklist = WFChecklistSteps_MinimumReq.Checklist AND WFChecklistSteps.Task = WFChecklistSteps_MinimumReq.Task AND WFChecklistSteps.Step = WFChecklistSteps_MinimumReq.Step AND WFChecklistSteps.Company = WFChecklistSteps_MinimumReq.Company
)

UNION ALL

--(D) An optional step may be started if the task can be started (enforce order enabled)
(
SELECT WFChecklistSteps.Company, 'Step' as [Type], WFChecklistSteps.KeyID, WFChecklistSteps.Task, WFChecklistSteps.Checklist, WFChecklistSteps.Step as [Step], WFChecklistSteps.Summary, WFChecklistSteps.IsStepRequired as [Required], WFChecklistSteps.UseEmail, WFChecklistSteps.[Status], WFChecklistSteps.[Description], WFChecklistSteps.StepType as [ItemType], WFChecklistSteps.VPName, WFChecklistSteps.AssignedTo, WFChecklistSteps.AssignedOn, WFChecklistSteps.DueDate, WFChecklistSteps.CompletedBy, WFChecklistSteps.CompletedOn, WFChecklistSteps.AddedBy, WFChecklistSteps.AddedOn, WFChecklistSteps.ChangedBy, WFChecklistSteps.ChangedOn, WFChecklistSteps.Notes, WFChecklistSteps.ReportID, WFChecklistSteps.UniqueAttchID 
	FROM WFChecklistSteps 
	INNER JOIN AvailableTasks_CTE ON WFChecklistSteps.Company = AvailableTasks_CTE.Company  AND WFChecklistSteps.Checklist = AvailableTasks_CTE.Checklist AND WFChecklistSteps.Task = AvailableTasks_CTE.Task
	INNER JOIN WFStatusCodes ON WFChecklistSteps.Status = WFStatusCodes.StatusID
	INNER JOIN WFChecklists ON WFChecklistSteps.Company = WFChecklists.Company AND WFChecklistSteps.Checklist = WFChecklists.Checklist
	WHERE WFChecklistSteps.IsStepRequired = 'N' AND WFStatusCodes.StatusType <> 2 
		AND EXISTS (SELECT TOP 1 1 
						FROM WFChecklistTasks 
						WHERE WFChecklistTasks.Checklist = WFChecklists.Checklist AND WFChecklistTasks.IsTaskRequired = 'Y')	
)

UNION ALL

--(E) A task may be started at any time if enforce order is disabled
(
SELECT WFChecklistTasks.Company, 'Task' as [Type], WFChecklistTasks.KeyID, WFChecklistTasks.Task, WFChecklistTasks.Checklist, '' as [Step], WFChecklistTasks.Summary, WFChecklistTasks.IsTaskRequired as [Required], WFChecklistTasks.UseEmail, WFChecklistTasks.[Status], WFChecklistTasks.[Description], WFChecklistTasks.TaskType as [ItemType], WFChecklistTasks.VPName, WFChecklistTasks.AssignedTo, WFChecklistTasks.AssignedOn, WFChecklistTasks.DueDate, WFChecklistTasks.CompletedBy, WFChecklistTasks.CompletedOn, WFChecklistTasks.AddedBy, WFChecklistTasks.AddedOn, WFChecklistTasks.ChangedBy, WFChecklistTasks.ChangedOn, WFChecklistTasks.Notes, WFChecklistTasks.ReportID, WFChecklistTasks.UniqueAttchID 
	FROM WFChecklistTasks
	INNER JOIN WFChecklists ON WFChecklistTasks.Checklist = WFChecklists.Checklist AND WFChecklistTasks.Company = WFChecklists.Company
	INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
	WHERE WFChecklists.EnforceOrder = 'N' AND WFStatusCodes.StatusType <> 2 
)

UNION ALL

--(F) A step may be started at any time if enforce order is disabled
SELECT WFChecklistSteps.Company, 'Step' as [Type], WFChecklistSteps.KeyID, WFChecklistSteps.Task, WFChecklistSteps.Checklist, WFChecklistSteps.Step as [Step], WFChecklistSteps.Summary, WFChecklistSteps.IsStepRequired as [Required], WFChecklistSteps.UseEmail, WFChecklistSteps.[Status], WFChecklistSteps.[Description], WFChecklistSteps.StepType as [ItemType], WFChecklistSteps.VPName, WFChecklistSteps.AssignedTo, WFChecklistSteps.AssignedOn, WFChecklistSteps.DueDate, WFChecklistSteps.CompletedBy, WFChecklistSteps.CompletedOn, WFChecklistSteps.AddedBy, WFChecklistSteps.AddedOn, WFChecklistSteps.ChangedBy, WFChecklistSteps.ChangedOn, WFChecklistSteps.Notes, WFChecklistSteps.ReportID, WFChecklistSteps.UniqueAttchID 
	FROM WFChecklistSteps 
	INNER JOIN
		(SELECT WFChecklistTasks.Company, WFChecklistTasks.Checklist, WFChecklistTasks.Task
			FROM WFChecklistTasks
				INNER JOIN WFChecklists ON WFChecklistTasks.Checklist = WFChecklists.Checklist AND WFChecklistTasks.Company = WFChecklists.Company
				INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
				WHERE WFChecklists.EnforceOrder = 'N' AND WFStatusCodes.StatusType <> 2 
		) AS UnorderedTasks ON WFChecklistSteps.Company = UnorderedTasks.Company AND WFChecklistSteps.Checklist = UnorderedTasks.Checklist AND WFChecklistSteps.Task = UnorderedTasks.Task
	INNER JOIN WFStatusCodes ON WFChecklistSteps.Status = WFStatusCodes.StatusID
	WHERE WFStatusCodes.StatusType <> 2

UNION ALL

--(G) All completed Tasks and Steps should be visible as well
SELECT WFChecklistSteps.Company, 'Step' as [Type], WFChecklistSteps.KeyID, WFChecklistSteps.Task, WFChecklistSteps.Checklist, WFChecklistSteps.Step as [Step], WFChecklistSteps.Summary, WFChecklistSteps.IsStepRequired as [Required], WFChecklistSteps.UseEmail, WFChecklistSteps.[Status], WFChecklistSteps.[Description], WFChecklistSteps.StepType as [ItemType], WFChecklistSteps.VPName, WFChecklistSteps.AssignedTo, WFChecklistSteps.AssignedOn, WFChecklistSteps.DueDate, WFChecklistSteps.CompletedBy, WFChecklistSteps.CompletedOn, WFChecklistSteps.AddedBy, WFChecklistSteps.AddedOn, WFChecklistSteps.ChangedBy, WFChecklistSteps.ChangedOn, WFChecklistSteps.Notes, WFChecklistSteps.ReportID, WFChecklistSteps.UniqueAttchID 
	FROM WFChecklistSteps 
	INNER JOIN WFStatusCodes ON WFChecklistSteps.Status = WFStatusCodes.StatusID
	WHERE WFStatusCodes.StatusType = 2

UNION ALL

SELECT WFChecklistTasks.Company, 'Task' as [Type], WFChecklistTasks.KeyID, WFChecklistTasks.Task, WFChecklistTasks.Checklist, '' as [Step], WFChecklistTasks.Summary, WFChecklistTasks.IsTaskRequired as [Required], WFChecklistTasks.UseEmail, WFChecklistTasks.[Status], WFChecklistTasks.[Description], WFChecklistTasks.TaskType as [ItemType], WFChecklistTasks.VPName, WFChecklistTasks.AssignedTo, WFChecklistTasks.AssignedOn, WFChecklistTasks.DueDate, WFChecklistTasks.CompletedBy, WFChecklistTasks.CompletedOn, WFChecklistTasks.AddedBy, WFChecklistTasks.AddedOn, WFChecklistTasks.ChangedBy, WFChecklistTasks.ChangedOn, WFChecklistTasks.Notes, WFChecklistTasks.ReportID, WFChecklistTasks.UniqueAttchID 
	FROM WFChecklistTasks
	INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
	WHERE WFStatusCodes.StatusType = 2 
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 1/21/2008
* Modified: CC 5/8/2008 - Issue #127925 - Update UniqueAttchID for the underlying tables
*			CC 6/17/2008 - Issue #128698 - Update Notes for the underlying tables
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFTasklistu] 
   ON  [dbo].[WFTasklist] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

UPDATE WFChecklistTasks SET
	[Status] = inserted.[Status],
	CompletedBy = inserted.CompletedBy,
	CompletedOn = inserted.CompletedOn,
	Notes = inserted.Notes,
	UniqueAttchID = inserted.UniqueAttchID
FROM WFChecklistTasks 
INNER JOIN inserted ON inserted.KeyID = WFChecklistTasks.KeyID
WHERE inserted.Type = 'Task'

UPDATE WFChecklistSteps SET
	[Status] = inserted.[Status],
	CompletedBy = inserted.CompletedBy,
	CompletedOn = inserted.CompletedOn,
	Notes = inserted.Notes,
	UniqueAttchID = inserted.UniqueAttchID
FROM WFChecklistSteps
INNER JOIN inserted ON inserted.KeyID = WFChecklistSteps.KeyID
WHERE inserted.Type = 'Step'
	
END

GO
GRANT SELECT ON  [dbo].[WFTasklist] TO [public]
GRANT INSERT ON  [dbo].[WFTasklist] TO [public]
GRANT DELETE ON  [dbo].[WFTasklist] TO [public]
GRANT UPDATE ON  [dbo].[WFTasklist] TO [public]
GRANT SELECT ON  [dbo].[WFTasklist] TO [Viewpoint]
GRANT INSERT ON  [dbo].[WFTasklist] TO [Viewpoint]
GRANT DELETE ON  [dbo].[WFTasklist] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[WFTasklist] TO [Viewpoint]
GO
