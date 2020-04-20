CREATE TABLE [dbo].[vWFChecklistTasks]
(
[KeyID] [int] NOT NULL IDENTITY(1, 2),
[Task] [int] NOT NULL,
[Checklist] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Company] [dbo].[bCompany] NULL,
[Summary] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[IsTaskRequired] [dbo].[bYN] NOT NULL,
[UseEmail] [dbo].[bYN] NOT NULL,
[Status] [int] NOT NULL,
[Description] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[TaskType] [smallint] NOT NULL,
[VPName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[AssignedTo] [dbo].[bVPUserName] NULL,
[AssignedOn] [datetime] NULL,
[DueDate] [datetime] NULL,
[CompletedBy] [dbo].[bVPUserName] NULL,
[CompletedOn] [datetime] NULL,
[AddedBy] [dbo].[bVPUserName] NULL,
[AddedOn] [datetime] NULL,
[ChangedBy] [dbo].[bVPUserName] NULL,
[ChangedOn] [datetime] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ReportID] [int] NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 1/16/2008
* Modified: CC 6/5/08 128554 - Enforce referential integrity, delete any checklist steps associated with the task.
*
*	This trigger reorders tasks when they're deleted
*
************************************************************************/

CREATE TRIGGER [dbo].[vtWFChecklistTasksd] 
   ON  [dbo].[vWFChecklistTasks] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	SET NOCOUNT ON;


DELETE FROM WFChecklistSteps FROM WFChecklistSteps
	INNER JOIN deleted ON WFChecklistSteps.Company = deleted.Company AND WFChecklistSteps.Checklist = deleted.Checklist AND WFChecklistSteps.Task = deleted.Task;

DECLARE @OldList TABLE(KeyID int IDENTITY,
			    	   Names VARCHAR(150)
					   )
DECLARE  @NewList TABLE	(KeyID int IDENTITY,
		    			 Names VARCHAR(150)
						)

INSERT INTO @OldList SELECT t.Task FROM WFChecklistTasks t INNER JOIN deleted d ON t.Company = d.Company AND t.Checklist = d.Checklist AND t.Task <> d.Task
INSERT INTO @NewList SELECT t.Task FROM WFChecklistTasks t INNER JOIN deleted d ON t.Company = d.Company AND t.Checklist = d.Checklist AND t.Task <> d.Task

	BEGIN TRY
		UPDATE @NewList SET Names = KeyID;
		BEGIN TRANSACTION

			UPDATE WFChecklistSteps SET Task = CAST(n.Names AS int)
			FROM WFChecklistSteps s
				INNER JOIN deleted d ON s.Company = d.Company AND s.Checklist = d.Checklist 
				INNER JOIN @OldList o ON s.Task = o.Names 
				INNER JOIN @NewList n ON n.KeyID = o.KeyID			
			WHERE s.Task NOT IN (SELECT Task FROM deleted) 

			UPDATE WFChecklistTasks SET Task = CAST(n.Names AS int)
			FROM WFChecklistTasks t
				INNER JOIN deleted d ON t.Company = d.Company AND t.Checklist = d.Checklist
				INNER JOIN @OldList o ON t.Task = o.Names 
				INNER JOIN @NewList n ON n.KeyID = o.KeyID 			
			WHERE t.Task NOT IN (SELECT Task FROM deleted) 

	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
	END CATCH

	IF @@TRANCOUNT > 0
		    COMMIT TRANSACTION;
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 12/20/2007
* Modified: 
*
*	This trigger updates the AddedBy, AddedOn, ChangedBy, and ChangedOn fields for audit information.
*	If necessary, updates checklist status based on inserted task status
*	Enforces various business rules, task/step status concurency, checklist statuses, and task/step requirement concurency
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFChecklistTasksi] 
   ON  [dbo].[vWFChecklistTasks] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
update vWFChecklistTasks set AddedBy = suser_sname(), AddedOn = GetDate(), ChangedBy = suser_sname(), ChangedOn = GetDate()
	from vWFChecklistTasks t
	inner join inserted i on t.Task = i.Task and t.Checklist = i.Checklist and t.Company = i.Company
	

--for checklists

--All required tasks and all required steps are in a final state or there are no required tasks and all tasks and steps are in a final state
IF (NOT EXISTS(SELECT TOP 1 1 
				FROM WFChecklistTasks 
				INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist 
				INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
				WHERE WFChecklistTasks.IsTaskRequired = 'Y' and WFStatusCodes.StatusType <> 2) 
	AND EXISTS (SELECT TOP 1 1 
					FROM WFChecklistTasks 
					INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist 
					WHERE WFChecklistTasks.IsTaskRequired = 'Y')
	)
	OR
	(NOT EXISTS(SELECT TOP 1 1 
					FROM WFChecklistTasks 
					INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist 
					INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
					WHERE WFStatusCodes.StatusType <> 2) 
	AND NOT EXISTS (SELECT TOP 1 1 
						FROM WFChecklistTasks 
						INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist 
						WHERE WFChecklistTasks.IsTaskRequired = 'Y')
	 )--end or clause
	BEGIN
		UPDATE WFChecklists SET WFChecklists.Status = COALESCE((SELECT MIN(WFStatusCodes.StatusID) 
														 FROM WFStatusCodes 
														 WHERE StatusType = 2 AND IsChecklistStatus = 'Y' AND IsDefaultStatus = 'Y')
														,(SELECT MIN(WFStatusCodes.StatusID) 
														  FROM WFStatusCodes 
														  WHERE StatusType = 2 AND IsChecklistStatus = 'Y'))
		FROM WFChecklists 
		INNER JOIN inserted ON WFChecklists.Company = inserted.Company AND WFChecklists.Checklist = inserted.Checklist

		UPDATE WFChecklists SET WFChecklists.DateCompleted = CAST(CONVERT(VARCHAR(10), GETDATE(),101) AS DATETIME)
		FROM WFChecklists 
		INNER JOIN inserted ON WFChecklists.Company = inserted.Company AND WFChecklists.Checklist = inserted.Checklist
		WHERE ISNULL(WFChecklists.DateCompleted,'') = ''

		RETURN
	END

--When any (but not all) task or step enters an 'In Progress' or 'Final' status the checklist is 'In Progress'
IF (EXISTS (SELECT TOP 1 1 
				FROM WFChecklistTasks 
				INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist 
				INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
				WHERE WFStatusCodes.StatusType <> 0
			))
	BEGIN
		UPDATE WFChecklists SET WFChecklists.[Status] = COALESCE((SELECT MIN(WFStatusCodes.StatusID) 
														 FROM WFStatusCodes 
														 WHERE StatusType = 1 AND IsChecklistStatus = 'Y' AND IsDefaultStatus = 'Y')
														,(SELECT MIN(WFStatusCodes.StatusID) 
														  FROM WFStatusCodes 
														  WHERE StatusType = 1 AND IsChecklistStatus = 'Y'))
		FROM WFChecklists 
		INNER JOIN inserted ON WFChecklists.Company = inserted.Company AND WFChecklists.Checklist = inserted.Checklist

		RETURN
	END

--Check for all tasks to be in a new state
IF NOT EXISTS (SELECT TOP 1 1 
				FROM WFChecklistTasks
				INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
				INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist
				WHERE WFStatusCodes.StatusType <> 0) 
	BEGIN
		UPDATE WFChecklists SET WFChecklists.Status = COALESCE((SELECT MIN(WFStatusCodes.StatusID) 
														 FROM WFStatusCodes 
														 WHERE StatusType = 0 AND IsChecklistStatus = 'Y' AND IsDefaultStatus = 'Y')
														,(SELECT MIN(WFStatusCodes.StatusID) 
														  FROM WFStatusCodes 
														  WHERE StatusType = 0 AND IsChecklistStatus = 'Y'))
		FROM WFChecklists 
		INNER JOIN inserted ON WFChecklists.Company = inserted.Company AND WFChecklists.Checklist = inserted.Checklist

		RETURN
	END
RETURN
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 12/20/2007
* Modified: CC 6/17/2008 - Issue #128685 - Corrected logic error in status validation
*			CC 7/8/2008  - Issue #128817 - Removed auto-completion of Steps associated with task.
*			CC 8/26/2008 - Issue #129564 - Changed email subject & body
*
*	This trigger updates the AddedBy, AddedOn, ChangedBy, and ChangedOn fields for audit information.
*	Enforces various business rules, task/step status concurency, checklist statuses, and task/step requirement concurency
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFChecklistTasksu] 
   ON  [dbo].[vWFChecklistTasks] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
UPDATE WFChecklistTasks SET ChangedBy = SUSER_SNAME(), ChangedOn = GETDATE() 
	FROM WFChecklistTasks
	INNER JOIN inserted on
		WFChecklistTasks.Task = inserted.Task 
		and WFChecklistTasks.Checklist = inserted.Checklist 
		and WFChecklistTasks.Company = inserted.Company 

/*Check for changes in the required status of the task.*/
DECLARE @errmsg VARCHAR(255)
IF UPDATE(IsTaskRequired)
	IF EXISTS (SELECT TOP 1 1 FROM deleted 
							  INNER JOIN inserted on 
									deleted.KeyID = inserted.KeyID AND deleted.IsTaskRequired <> inserted.IsTaskRequired 
							  WHERE inserted.IsTaskRequired = 'N')
		BEGIN
			UPDATE WFChecklistSteps SET IsStepRequired = 'N'
				FROM WFChecklistSteps
				INNER JOIN inserted on
					WFChecklistSteps.Company = inserted.Company
					AND WFChecklistSteps.Checklist = inserted.Checklist
					AND WFChecklistSteps.Task = inserted.Task 
					AND inserted.IsTaskRequired = 'N'
			
		END
/*Check for status updates to the task */

IF UPDATE([Status])
	BEGIN

		UPDATE WFChecklistTasks SET CompletedOn = CAST(CONVERT(VARCHAR(10), GETDATE(),101) AS DATETIME)
		FROM WFChecklistTasks
		INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist AND WFChecklistTasks.Task = inserted.Task
		INNER JOIN WFStatusCodes ON inserted.Status = WFStatusCodes.StatusID
		WHERE ISNULL(WFChecklistTasks.CompletedOn,'')='' AND WFStatusCodes.StatusType = 2


		UPDATE WFChecklistTasks SET CompletedBy = SUSER_SNAME()
		FROM WFChecklistTasks
		INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist AND WFChecklistTasks.Task = inserted.Task
		INNER JOIN WFStatusCodes ON inserted.Status = WFStatusCodes.StatusID
		WHERE ISNULL(WFChecklistTasks.CompletedBy,'')='' AND WFStatusCodes.StatusType = 2

		IF EXISTS (SELECT TOP 1 1 
					FROM inserted 
					WHERE IsTaskRequired = ALL (Select 'N')) 
							AND EXISTS (SELECT TOP 1 1 
											FROM WFChecklistTasks 
											INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist 
											WHERE WFChecklistTasks.IsTaskRequired = 'Y')
				GOTO StatusUpdates

		IF EXISTS (SELECT TOP 1 1 
						FROM inserted
						INNER JOIN WFStatusCodes ON inserted.Status = WFStatusCodes.StatusID
						WHERE WFStatusCodes.StatusType = 0 AND WFStatusCodes.IsChecklistStatus = 'N')
				GOTO StatusUpdates

		IF NOT EXISTS(
					SELECT DISTINCT (MIN(WFChecklistTasks.Task) OVER (PARTITION BY WFChecklistTasks.Checklist, WFChecklistTasks.Company)) AS Task, WFChecklistTasks.Checklist, WFChecklistTasks.Company
							FROM WFChecklistTasks
							INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
							INNER JOIN WFChecklists ON WFChecklistTasks.Checklist = WFChecklists.Checklist AND WFChecklistTasks.Company = WFChecklists.Company
							INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist AND WFChecklistTasks.Task < inserted.Task
							WHERE WFChecklists.EnforceOrder = 'Y' AND WFStatusCodes.StatusType <> 2 
								AND (
										(WFChecklistTasks.IsTaskRequired = 'N' AND NOT EXISTS (SELECT TOP 1 1 FROM WFChecklistTasks WHERE WFChecklistTasks.Checklist = WFChecklists.Checklist AND WFChecklistTasks.IsTaskRequired = 'Y'))
										OR 
										(WFChecklistTasks.IsTaskRequired = 'Y')
									)
					) 
				GOTO StatusUpdates
		ELSE
			BEGIN
				SET @errmsg = 'There are uncompleted tasks preceeding this task.  Please complete any preceeding required tasks.'
				GOTO error
			END

		StatusUpdates:
		IF EXISTS (SELECT TOP 1 1 
					FROM WFStatusCodes 
					INNER JOIN inserted ON WFStatusCodes.StatusID = inserted.Status AND WFStatusCodes.StatusType = 2)
			BEGIN
--			--Update any steps needing update to final status
--			UPDATE WFChecklistSteps SET [Status] = inserted.Status
--				FROM WFChecklistSteps
--				INNER JOIN inserted ON WFChecklistSteps.Company = inserted.Company AND WFChecklistSteps.Checklist = inserted.Checklist AND WFChecklistSteps.Task = inserted.Task
--				INNER JOIN WFStatusCodes ON WFStatusCodes.StatusID = inserted.Status
--				WHERE WFChecklistSteps.KeyID IN
--					(SELECT WFChecklistSteps.KeyID 
--						FROM WFChecklistSteps 
--						INNER JOIN WFStatusCodes ON WFChecklistSteps.Status = WFStatusCodes.StatusID 
--						WHERE WFStatusCodes.StatusType <> 2 AND WFStatusCodes.IsChecklistStatus = 'N')

			--send notification
			DECLARE @emailFrom VARCHAR(55)
			SELECT @emailFrom = COALESCE([Value], 'viewpointcs') 
				FROM WDSettings 
				WHERE Setting = 'FromAddress'

			INSERT INTO vMailQueue ([To], CC, BCC, [From], [Subject], Body, Source)
				SELECT COALESCE (DDUP.EMail,''), '', '', @emailFrom AS [From],
					CASE WFTasklist.[Type]
						WHEN 'Task' THEN 'Checklist Task: '
						WHEN 'Step' THEN 'Checklist Step: ' 
					END
					+ WFTasklist.Summary + ' can be started'  AS [Subject]
					,CASE WFTasklist.[Type]
						WHEN 'Task' THEN 'Task ' + CAST(WFTasklist.Task AS VARCHAR(5)) + WFTasklist.Summary + ' on Checklist: ' + WFTasklist.Checklist + ' is ready to start.'
						WHEN 'Step' THEN 'Step ' + CAST(WFTasklist.Task AS VARCHAR(5)) + ', step ' +  CAST(WFTasklist.Step AS VARCHAR(5)) + ' ' + WFTasklist.Summary + ' on Checklist: ' + WFTasklist.Checklist + ' is ready to start.'
					END
					+ CHAR(13) + CHAR(10) + 
					 'This ' + LOWER(WFTasklist.Type) + ' is a required activity on this checklist.  Failure to complete this activity will prevent this checklist from being completed.' 
					AS [Body]
					,'Workflow'
				FROM WFTasklist
				INNER JOIN DDUP ON WFTasklist.AssignedTo = DDUP.VPUserName
				INNER JOIN inserted ON inserted.Checklist = WFTasklist.Checklist
				INNER JOIN WFChecklists ON WFChecklists.Checklist = inserted.Checklist AND WFChecklists.Company = inserted.Company
				INNER JOIN WFStatusCodes ON WFTasklist.Status = WFStatusCodes.StatusID
				WHERE WFChecklists.EnforceOrder ='Y' AND WFTasklist.UseEmail = 'Y' AND WFChecklists.UseEmail = 'Y' AND WFStatusCodes.StatusType = 0
					AND (
							(WFTasklist.Required = 'N' AND NOT EXISTS (SELECT TOP 1 1 FROM WFChecklistTasks WHERE WFChecklistTasks.Checklist = WFChecklists.Checklist AND WFChecklistTasks.Company = WFChecklists.Company AND WFChecklistTasks.IsTaskRequired = 'Y'))
							OR 
							(WFTasklist.Required = 'Y')
						)
			END
		--A task may not be in a new state if any steps are in an in progress or final state
			--check for steps related to this task
			IF EXISTS (SELECT TOP 1 1 
						FROM WFChecklistSteps  
						INNER JOIN inserted ON WFChecklistSteps.Company = inserted.Company AND WFChecklistSteps.Checklist = inserted.Checklist AND WFChecklistSteps.Task = inserted.Task
						INNER JOIN WFStatusCodes ON WFChecklistSteps.Status = WFStatusCodes.StatusID
						WHERE WFStatusCodes.StatusType <> 0 AND WFStatusCodes.IsChecklistStatus = 'N')
				AND EXISTS 	(SELECT TOP 1 1 
						FROM WFChecklistTasks  
						INNER JOIN deleted ON WFChecklistTasks.Company = deleted.Company AND WFChecklistTasks.Checklist = deleted.Checklist AND WFChecklistTasks.Task = deleted.Task
						INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
						WHERE WFStatusCodes.StatusType = 0 AND WFStatusCodes.IsChecklistStatus = 'N')
				BEGIN
					SELECT TOP 1 @errmsg = 'This task has steps that are in progress or in a final state, this task cannot be set to "' + LEFT(WFStatusCodes.[Description],117) + '". Please select an in progress status instead.' 
						FROM WFStatusCodes 
						INNER JOIN inserted ON inserted.Status = WFStatusCodes.StatusID
					GOTO error
				END
	GOTO StatusCheck
	END

StatusCheck: --for checklists

--All required tasks and all required steps are in a final state or there are no required tasks and all tasks and steps are in a final state
IF (NOT EXISTS(SELECT TOP 1 1 
				FROM WFChecklistTasks 
				INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist 
				INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
				WHERE WFChecklistTasks.IsTaskRequired = 'Y' and WFStatusCodes.StatusType <> 2) 
	AND EXISTS (SELECT TOP 1 1 
					FROM WFChecklistTasks 
					INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist 
					WHERE WFChecklistTasks.IsTaskRequired = 'Y')
	)
	OR
	(NOT EXISTS(SELECT TOP 1 1 
					FROM WFChecklistTasks 
					INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist 
					INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
					WHERE WFStatusCodes.StatusType <> 2) 
	AND NOT EXISTS (SELECT TOP 1 1 
						FROM WFChecklistTasks 
						INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist 
						WHERE WFChecklistTasks.IsTaskRequired = 'Y')
	 )--end or clause
	BEGIN
		UPDATE WFChecklists SET WFChecklists.Status = COALESCE((SELECT MIN(WFStatusCodes.StatusID) 
														 FROM WFStatusCodes 
														 WHERE StatusType = 2 AND IsChecklistStatus = 'Y' AND IsDefaultStatus = 'Y')
														,(SELECT MIN(WFStatusCodes.StatusID) 
														  FROM WFStatusCodes 
														  WHERE StatusType = 2 AND IsChecklistStatus = 'Y'))
		FROM WFChecklists 
		INNER JOIN inserted ON WFChecklists.Company = inserted.Company AND WFChecklists.Checklist = inserted.Checklist

		UPDATE WFChecklists SET WFChecklists.DateCompleted = CAST(CONVERT(VARCHAR(10), GETDATE(),101) AS DATETIME)
		FROM WFChecklists 
		INNER JOIN inserted ON WFChecklists.Company = inserted.Company AND WFChecklists.Checklist = inserted.Checklist
		WHERE ISNULL(WFChecklists.DateCompleted,'') = ''

		RETURN
	END

--When any (but not all) task or step enters an 'In Progress' or 'Final' status the checklist is 'In Progress'
IF (EXISTS (SELECT TOP 1 1 
				FROM WFChecklistTasks 
				INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist 
				INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
				WHERE WFStatusCodes.StatusType <> 0
			))
	BEGIN
		UPDATE WFChecklists SET WFChecklists.[Status] = COALESCE((SELECT MIN(WFStatusCodes.StatusID) 
														 FROM WFStatusCodes 
														 WHERE StatusType = 1 AND IsChecklistStatus = 'Y' AND IsDefaultStatus = 'Y')
														,(SELECT MIN(WFStatusCodes.StatusID) 
														  FROM WFStatusCodes 
														  WHERE StatusType = 1 AND IsChecklistStatus = 'Y'))
		FROM WFChecklists 
		INNER JOIN inserted ON WFChecklists.Company = inserted.Company AND WFChecklists.Checklist = inserted.Checklist

		RETURN
	END

--Check for all tasks to be in a new state
IF NOT EXISTS (SELECT TOP 1 1 
				FROM WFChecklistTasks
				INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
				INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist
				WHERE WFStatusCodes.StatusType <> 0) 
	BEGIN
		UPDATE WFChecklists SET WFChecklists.Status = COALESCE((SELECT MIN(WFStatusCodes.StatusID) 
														 FROM WFStatusCodes 
														 WHERE StatusType = 0 AND IsChecklistStatus = 'Y' AND IsDefaultStatus = 'Y')
														,(SELECT MIN(WFStatusCodes.StatusID) 
														  FROM WFStatusCodes 
														  WHERE StatusType = 0 AND IsChecklistStatus = 'Y'))
		FROM WFChecklists 
		INNER JOIN inserted ON WFChecklists.Company = inserted.Company AND WFChecklists.Checklist = inserted.Checklist

		RETURN
	END
RETURN

error:
	SELECT @errmsg = ISNULL(@errmsg,'Error updating task.')
    RAISERROR(@errmsg, 11, -1);
    ROLLBACK TRANSACTION
 
END

GO
ALTER TABLE [dbo].[vWFChecklistTasks] ADD CONSTRAINT [PK_vWFChecklistTasks] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [IX_vWFChecklistTasks] ON [dbo].[vWFChecklistTasks] ([Task], [Checklist], [Company]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWFChecklistTasks] WITH NOCHECK ADD CONSTRAINT [FK_vWFChecklistTasks_vWFStatusCodes] FOREIGN KEY ([Status]) REFERENCES [dbo].[vWFStatusCodes] ([StatusID])
GO
