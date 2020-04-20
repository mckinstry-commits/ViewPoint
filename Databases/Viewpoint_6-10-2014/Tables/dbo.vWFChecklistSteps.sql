CREATE TABLE [dbo].[vWFChecklistSteps]
(
[KeyID] [int] NOT NULL IDENTITY(2, 2),
[Step] [int] NOT NULL,
[Task] [int] NOT NULL,
[Checklist] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Company] [dbo].[bCompany] NULL,
[Summary] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[IsStepRequired] [dbo].[bYN] NOT NULL,
[UseEmail] [dbo].[bYN] NOT NULL,
[Status] [int] NOT NULL,
[Description] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[StepType] [smallint] NOT NULL,
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
* Created: Charles Courchaine 1/21/2008
* Modified: CC 7/24/2008 - Issue #129139 - Corrected join criteria
*
*	This trigger re-orders steps when they're deleted
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFChecklistStepsd] 
   ON  [dbo].[vWFChecklistSteps] 
   AFTER DELETE
AS 
BEGIN
SET NOCOUNT ON;

DECLARE @OldList TABLE(KeyID int IDENTITY,
			    	   Names VARCHAR(150)
					   )
DECLARE  @NewList TABLE	(KeyID int IDENTITY,
		    			 Names VARCHAR(150)
						)

INSERT INTO @OldList SELECT t.Step FROM WFChecklistSteps t INNER JOIN deleted d ON t.Company = d.Company AND t.Checklist = d.Checklist AND t.Task = d.Task AND t.Step <> d.Step
INSERT INTO @NewList SELECT t.Step FROM WFChecklistSteps t INNER JOIN deleted d ON t.Company = d.Company AND t.Checklist = d.Checklist AND t.Task = d.Task AND t.Step <> d.Step

	BEGIN TRY
		UPDATE @NewList SET Names = KeyID;
		BEGIN TRANSACTION

			UPDATE WFChecklistSteps SET Step = CAST(n.Names AS int)
			FROM WFChecklistSteps s
				INNER JOIN deleted d ON s.Company = d.Company AND s.Checklist = d.Checklist AND s.Task = d.Task
				INNER JOIN @OldList o ON s.Step = o.Names 
				INNER JOIN @NewList n ON n.KeyID = o.KeyID			
			WHERE s.Step NOT IN (SELECT Step FROM deleted) 

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
* Created: Charles Courchaine 12/20/2007
* Modified: 
*
*	This trigger updates the AddedBy, AddedOn, ChangedBy, and ChangedOn fields for audit information.
*	Enforces various business rules, task/step status concurency, checklist statuses, and task/step requirement concurency
*
************************************************************************/


CREATE TRIGGER [dbo].[vtWFChecklistStepsi] 
   ON  [dbo].[vWFChecklistSteps] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
update vWFChecklistSteps set AddedBy = suser_sname(), AddedOn = GetDate(), ChangedBy = suser_sname(), ChangedOn = GetDate()
	from vWFChecklistSteps s
	inner join inserted i 
	on s.Step = i.Step 
		and s.Task = i.Task 
		and s.Checklist = i.Checklist 
		and s.Company = i.Company 

--a task may not be in a new state if a step is in an in progress or final state
if exists(select top 1 1 from WFStatusCodes where StatusType = 0 and StatusID in 
	(select t.[Status] from vWFChecklistTasks t inner join inserted i on t.Company = i.Company and t.Checklist = i.Checklist and t.Task = i.Task))
	if exists(select top 1 1 from WFStatusCodes where StatusType >= 1 and StatusID in (select inserted.[Status] from inserted))
		update vWFChecklistTasks set [Status] = isnull((select min(StatusID) from WFStatusCodes where StatusType = 1 and IsDefaultStatus = 'Y'),(select min(StatusID) from WFStatusCodes where StatusType = 1))
		from vWFChecklistTasks t
		inner join inserted i
		on t.Company = i.Company and t.Checklist = i.Checklist and t.Task = i.Task

--a step cannot be in a non-final state if the task is in a final state
if exists(select top 1 1 from WFStatusCodes where StatusType <> 2 and StatusID in (select inserted.[Status] from inserted))
	if exists(select top 1 1 from WFStatusCodes where StatusType = 2 and StatusID in 
		(select t.[Status] from vWFChecklistTasks t inner join inserted i on t.Company = i.Company and t.Checklist = i.Checklist and t.Task = i.Task))
			update vWFChecklistSteps set vWFChecklistSteps.[Status] = (select t.[Status] from vWFChecklistTasks t inner join inserted i on t.Company = i.Company and t.Checklist = i.Checklist and t.Task = i.Task)
			from vWFChecklistSteps s
			inner join inserted i
			on s.Company = i.Company and s.Checklist = i.Checklist and s.Task = i.Task and s.Step = i.Step

--if the task is not required and a step becomes required, make the task required.
if exists (select top 1 1 from vWFChecklistTasks t inner join inserted i 
	on t.Company = i.Company and t.Checklist = i.Checklist and t.Task = i.Task where t.IsTaskRequired = 'N') 
	and 
	exists (select top 1 1 from inserted i where i.IsStepRequired = 'Y') 
		update vWFChecklistTasks set IsTaskRequired = 'Y'
		from vWFChecklistTasks t
		inner join inserted i
		on t.Company = i.Company and t.Checklist = i.Checklist and t.Task = i.Task where i.IsStepRequired = 'Y'

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 12/20/2007
* Modified: CC 06/09/2008 - Updated Enforce Order check on the Checklist.
*			CC 06/17/2008 - Issue #128685 - Update status logic
*			CC 08/26/2008 - Issue #129564 - Update subject & body of email
*
*	This trigger updates the AddedBy, AddedOn, ChangedBy, and ChangedOn fields for audit information.
*	Enforces various business rules, task/step status concurency, checklist statuses, and task/step requirement concurency
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFChecklistStepsu] 
   ON  [dbo].[vWFChecklistSteps] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
--Update last changed information
UPDATE WFChecklistSteps SET ChangedBy = SUSER_SNAME(), ChangedOn = GETDATE() 
	FROM WFChecklistSteps
	INNER JOIN inserted ON WFChecklistSteps.Step = inserted.Step AND WFChecklistSteps.Task = inserted.Task AND WFChecklistSteps.Checklist = inserted.Checklist AND WFChecklistSteps.Company = inserted.Company 

/*
Check if the update sets any steps to an in-progress state, if so check if the task
is in a new state, if it is bring it to the same in-progress state

o	A task may not be in a new state if any steps are in progress or final (step trigger)
*/
DECLARE @errmsg VARCHAR(255)
IF UPDATE([Status])
	BEGIN
		UPDATE WFChecklistSteps SET CompletedOn = CAST(CONVERT(VARCHAR(10), GETDATE(),101) AS DATETIME)
		FROM WFChecklistSteps
		INNER JOIN inserted ON WFChecklistSteps.Company = inserted.Company AND WFChecklistSteps.Checklist = inserted.Checklist AND WFChecklistSteps.Task = inserted.Task AND WFChecklistSteps.Step = inserted.Step
		INNER JOIN WFStatusCodes ON inserted.Status = WFStatusCodes.StatusID
		WHERE ISNULL(WFChecklistSteps.CompletedOn,'')='' AND WFStatusCodes.StatusType = 2


		UPDATE WFChecklistSteps SET CompletedBy = SUSER_SNAME()
		FROM WFChecklistSteps
		INNER JOIN inserted ON WFChecklistSteps.Company = inserted.Company AND WFChecklistSteps.Checklist = inserted.Checklist AND WFChecklistSteps.Task = inserted.Task AND WFChecklistSteps.Step = inserted.Step
		INNER JOIN WFStatusCodes ON inserted.Status = WFStatusCodes.StatusID
		WHERE ISNULL(WFChecklistSteps.CompletedBy,'')='' AND WFStatusCodes.StatusType = 2

		IF EXISTS (SELECT TOP 1 1 
					FROM WFChecklists
					INNER JOIN inserted ON WFChecklists.Company = inserted.Company AND WFChecklists.Checklist = inserted.Checklist
					WHERE WFChecklists.EnforceOrder  = 'Y')
			
			BEGIN
				IF NOT EXISTS(SELECT TOP 1 1 
								FROM inserted 
								INNER JOIN WFStatusCodes ON inserted.Status = WFStatusCodes.StatusID
								WHERE WFStatusCodes.StatusType <> 0 AND WFStatusCodes.IsChecklistStatus = 'N')
					GOTO StatusUpdates
				DECLARE @PreviousTasksComplete bYN, @PreviousStepsComplete bYN

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
						SET @PreviousTasksComplete = 'Y'
				ELSE 
						SET @PreviousTasksComplete = 'N'

			IF NOT EXISTS(
				SELECT DISTINCT (MIN(WFChecklistSteps.Step) OVER (PARTITION BY WFChecklistSteps.Checklist, WFChecklistSteps.Company)) AS Step, WFChecklistSteps.Task, WFChecklistSteps.Checklist, WFChecklistSteps.Company
					FROM WFChecklistSteps 
					INNER JOIN WFStatusCodes ON WFChecklistSteps.Status = WFStatusCodes.StatusID
					INNER JOIN 
					(
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
					) AS RequiredTasks ON WFChecklistSteps.Checklist = RequiredTasks.Checklist AND WFChecklistSteps.Task = RequiredTasks.Task
					WHERE WFChecklistSteps.IsStepRequired = 'Y' AND WFStatusCodes.StatusType <> 2
				)			

				SET @PreviousStepsComplete = 'Y'
			ELSE
				SET @PreviousStepsComplete = 'N'
					
				IF @PreviousTasksComplete = 'Y' and @PreviousStepsComplete = 'Y'
						GOTO StatusUpdates
				ELSE
					BEGIN
						SET @errmsg = 'There are uncompleted tasks/steps preceeding this step.  Please complete any preceeding required tasks/steps.'
						GOTO error
					END

			END
		StatusUpdates:
	IF EXISTS(SELECT TOP 1 1 
				FROM WFStatusCodes 
				INNER JOIN inserted ON inserted.Status = WFStatusCodes.StatusID 
				WHERE WFStatusCodes.StatusType = 2 )
		BEGIN
			--send notification here
				DECLARE @emailFrom VARCHAR(55)
				SELECT @emailFrom = COALESCE([Value], 'viewpointcs') FROM WDSettings WHERE Setting = 'FromAddress'
					
				INSERT INTO vMailQueue ([To], CC, BCC, [From], [Subject], Body, Source)
				SELECT COALESCE(DDUP.EMail,''), '', '', @emailFrom AS [From],
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
							(WFTasklist.Required = 'N' AND NOT EXISTS (SELECT TOP 1 1 FROM WFChecklistTasks WHERE WFChecklistTasks.Checklist = WFChecklists.Checklist AND WFChecklistTasks.IsTaskRequired = 'Y'))
							OR 
							(WFTasklist.Required = 'Y')
						)
		END	
--if the task is in a new state (StatusType = 0) and any of the updated step statuses are in progress or final (StatusType >= 1)
--then update the task's status with the lowest status id number for in progress statuses
	IF EXISTS(SELECT TOP 1 1 
				FROM WFChecklistTasks 
				INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist AND WFChecklistTasks.Task = inserted.Task
				INNER JOIN WFStatusCodes ON WFChecklistTasks.[Status] = WFStatusCodes.StatusID
				WHERE WFStatusCodes.StatusType = 0 )
		IF EXISTS(SELECT TOP 1 1 
					FROM WFStatusCodes 
					INNER JOIN inserted ON WFStatusCodes.StatusID = inserted.[Status] 
					WHERE StatusType >= 1)
			UPDATE WFChecklistTasks SET [Status] = COALESCE((SELECT MIN (StatusID) 
																FROM WFStatusCodes 
																WHERE StatusType = 1 AND IsDefaultStatus = 'Y'),
															(SELECT MIN (StatusID) 
																FROM WFStatusCodes WHERE StatusType = 1))
			FROM WFChecklistTasks
			INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist AND WFChecklistTasks.Task = inserted.Task

	--a step cannot be in a non-final state if the task is in a final state
	IF EXISTS (SELECT TOP 1 1 
					FROM WFStatusCodes 
					INNER JOIN inserted ON WFStatusCodes.StatusID = inserted.[Status] 
					WHERE StatusType <> 2 )
		IF EXISTS(SELECT TOP 1 1 
					FROM WFChecklistTasks
					INNER JOIN WFStatusCodes ON WFChecklistTasks.Status = WFStatusCodes.StatusID
					INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist AND WFChecklistTasks.Task = inserted.Task
					WHERE WFStatusCodes.StatusType = 2 )
				BEGIN
					SET @errmsg = 'The task is in a final state therefore the step cannot be updated. Set the task to an in progress status and try again.'
					GOTO error
				END
	END --end status updates

IF UPDATE(IsStepRequired)
	IF EXISTS (SELECT TOP 1 1 
				FROM deleted 
				INNER JOIN inserted ON deleted.KeyID = inserted.KeyID AND deleted.IsStepRequired <> inserted.IsStepRequired)
	BEGIN
		--if the task is not required and a step becomes required, make the task required.
		IF EXISTS (SELECT TOP 1 1 
					FROM WFChecklistTasks 
					INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist AND WFChecklistTasks.Task = inserted.Task 
					WHERE WFChecklistTasks.IsTaskRequired = 'N') 
			AND
			EXISTS (SELECT TOP 1 1 
						FROM inserted 
						WHERE inserted.IsStepRequired = 'Y') 

				UPDATE WFChecklistTasks SET IsTaskRequired = 'Y'
				FROM WFChecklistTasks
				INNER JOIN inserted ON WFChecklistTasks.Company = inserted.Company AND WFChecklistTasks.Checklist = inserted.Checklist AND WFChecklistTasks.Task = inserted.Task 
				WHERE inserted .IsStepRequired = 'Y'
	END	
RETURN
error:
	SELECT @errmsg = ISNULL(@errmsg,'Error updating step.')
    RAISERROR(@errmsg, 11, -1);
    ROLLBACK TRANSACTION
  
END

GO
ALTER TABLE [dbo].[vWFChecklistSteps] ADD CONSTRAINT [PK_vWFChecklistSteps] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vWFChecklistSteps_Tasklist] ON [dbo].[vWFChecklistSteps] ([IsStepRequired], [Status]) INCLUDE ([Checklist], [Company], [Step], [Task]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [IX_vWFChecklistSteps] ON [dbo].[vWFChecklistSteps] ([Step], [Task], [Checklist], [Company]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWFChecklistSteps] WITH NOCHECK ADD CONSTRAINT [FK_vWFChecklistSteps_vWFStatusCodes] FOREIGN KEY ([Status]) REFERENCES [dbo].[vWFStatusCodes] ([StatusID])
GO
ALTER TABLE [dbo].[vWFChecklistSteps] NOCHECK CONSTRAINT [FK_vWFChecklistSteps_vWFStatusCodes]
GO
