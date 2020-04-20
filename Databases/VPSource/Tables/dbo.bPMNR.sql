CREATE TABLE [dbo].[bPMNR]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bProject] NOT NULL,
[NoteSeq] [int] NOT NULL,
[Reviewer] [dbo].[bVPUserName] NOT NULL,
[AddedDate] [dbo].[bDate] NOT NULL,
[RevStatus] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[RevStatusDate] [dbo].[bDate] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bPMNR] ADD
CONSTRAINT [FK_bPMNR_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger [dbo].[btPMNRd]    Script Date: 12/13/2006 14:05:58 ******/
CREATE  trigger [dbo].[btPMNRd] on [dbo].[bPMNR] for DELETE as
/****************************************************************
 * Created By:		GF 12/13/2006 - 6.x HQMA
 * Modified By:
 *
 *
 * Delete trigger for PM Project Notes Review table.
 *
 ****************************************************************/


if @@rowcount = 0 return
set nocount on

---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMNR','PMCo: ' + isnull(convert(char(3),d.PMCo), '') + ' Project: ' + isnull(d.Project,'') +
		' NoteSeq: ' + isnull(convert(varchar(8),d.NoteSeq),'') + ' Reviewer: ' + isnull(d.Reviewer,''),
		d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d JOIN bPMCO c ON d.PMCo=c.PMCo
where c.AuditPMNR = 'Y'

RETURN 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger [dbo].[btPMNRi]    Script Date: 12/13/2006 14:09:23 ******/
CREATE  trigger [dbo].[btPMNRi] on [dbo].[bPMNR] for INSERT as 
/*--------------------------------------------------------------
 * Insert trigger for PMNR
 * Created By:	GF 12/13/2006 - 6.x HQMA
 * Updated By:	DAN SO 12/12/2008 - Issue 129484 - Send notification to Reviewer
 *				
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), 
		@ToUser bVPUserName,
		@FromUser bVPUserName,
		@CoNum varchar(10), 
		@ProjNum varchar(20),
		@AddedBy bVPUserName, 
		@AddedDate bDate,
		@ChangedBy bVPUserName, 
		@ChangedDate bDate,
		@CursorOpen tinyint,
		@msg varchar(255),
		@rcode int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


-- ********************************** --
-- CHECK TO SEE IF A CURSOR IS NEEDED --
-- ********************************** --
IF @numrows = 1
	BEGIN

		-- CURSOR CLOSE FLAG --
		SET @CursorOpen = 0

		SELECT	@CoNum = i.PMCo,
				@ProjNum = i.Project,
				@ToUser = i.Reviewer,
				@AddedBy = n.AddedBy,
				@AddedDate = n.AddedDate,
				@ChangedBy = n.ChangedBy,
				@ChangedDate = n.ChangedDate
		  FROM	Inserted i 
		  JOIN	bPMPN n WITH (NOLOCK)
			ON	i.PMCo = n.PMCo
		   AND	i.Project = n.Project
		   AND  i.NoteSeq = n.NoteSeq
	END
ELSE
	BEGIN
		-- CREATE CURSOR --
		DECLARE NotifyCursor CURSOR LOCAL FAST_FORWARD FOR
			SELECT	i.PMCo, i.Project, i.Reviewer,
					n.AddedBy, n.AddedDate, n.ChangedBy, n.ChangedDate
			  FROM	Inserted i 
			  JOIN	bPMPN n WITH (NOLOCK)
				ON	i.PMCo = n.PMCo
			   AND	i.Project = n.Project
			   AND  i.NoteSeq = n.NoteSeq

		OPEN NotifyCursor

		-- CURSOR OPEN FLAG --
		SET @CursorOpen = 1

		FETCH NEXT FROM NotifyCursor
			INTO	@CoNum,	@ProjNum, @ToUser,
					@AddedBy, @AddedDate, @ChangedBy, @ChangedDate
	END
			

-- ********************** --
-- START Notify_Reviewer: --
-- ********************** --
Notify_Reviewer:

	-- PRIME VARIABLES --
	SET @rcode = 0
	SET @msg = ''
	SET @FromUser = SUSER_SNAME()

	-- SEND EMAIL TO REVIEWER --
	EXECUTE @rcode = vspPMProjectEmail	@ToUser, @FromUser,		
										@CoNum, @ProjNum,  
										@AddedBy, @AddedDate,
										@ChangedBy, @ChangedDate,
										@msg output
	-- ***************************************************** --
	-- DISREGARD ANY ERRORS IN THE vspPMProjectEmail ROUTINE --
	-- ***************************************************** --
-- ******************** --
-- END Notify_Reviewer: --
-- ******************** --


-- ****************************** --
-- CHECK TO SEE IF CURSOR IS OPEN --
-- ****************************** --
IF @CursorOpen = 1
   	BEGIN

		-- GET NEXT RECORD FROM CURSOR --
		FETCH NEXT FROM NotifyCursor
			INTO	@CoNum,	@ProjNum, @ToUser,
					@AddedBy, @AddedDate, @ChangedBy, @ChangedDate

		
		IF @@fetch_status = 0
			BEGIN
				GOTO Notify_Reviewer
			END
		ELSE
			BEGIN
				-- CLOSE AND REMOVE CURSOR FROM MEMORY --
				CLOSE NotifyCursor
				DEALLOCATE NiotifyCursor

				-- CURSOR CLOSE FLAG --
				SET @CursorOpen = 0
			END
	END --@CursorOpen = 1


-- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMNR', 'PMCo: ' + convert(char(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') +
		' NoteSeq: ' + isnull(convert(varchar(8),i.NoteSeq),'') + ' Reviewer: ' + isnull(i.Reviewer,''),
       i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMNR = 'Y'

return


error:
	IF @CursorOpen = 1
		BEGIN
			CLOSE NotifyCursor
			DEALLOCATE NiotifyCursor
		END

	select @errmsg = isnull(@errmsg,'') + ' - cannot insert into PMNR'
	RAISERROR(@errmsg, 11, -1);
   	rollback transaction




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  trigger [dbo].[btPMNRu] on [dbo].[bPMNR] for UPDATE as
/****************************************************************
 * Created By:	GF 12/13/2006 - 6.x HQMA
 * Modified By: DAN SO 12/12/2008 - Issue 129484 - Send notification to Reviewer
 *
 *
 *
 * Update trigger for PM Project Notes Reviewer table.
 *
 ****************************************************************/
declare @errmsg varchar(255), @numrows int, @validcount int,
		@RevStatus varchar(10), 		
		@ToUser bVPUserName,
		@FromUser bVPUserName,
		@CoNum varchar(10), 
		@ProjNum varchar(20), 
		@AddedBy bVPUserName, 
--		@AddedDate varchar(10),
		@AddedDate bDate,
		@ChangedBy bVPUserName, 
--		@ChangedDate varchar(10),
		@ChangedDate bDate,
		@CursorOpen tinyint,
		@msg varchar(255),
		@rcode int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- *************************** --
-- CHECK FOR RevStatus UPDATES --
-- *************************** --
IF UPDATE(RevStatus)
	BEGIN
		SELECT @RevStatus = i.RevStatus FROM Inserted i
			
		IF UPPER(@RevStatus) = 'NEW'
			BEGIN
				-- ********************************** --
				-- CHECK TO SEE IF A CURSOR IS NEEDED --
				-- ********************************** --
				IF @numrows = 1
					BEGIN

						-- CURSOR CLOSE FLAG --
						SET @CursorOpen = 0

						SELECT	@CoNum = i.PMCo,
								@ProjNum = i.Project,
								@ToUser = i.Reviewer,
								@AddedBy = n.AddedBy,
								@AddedDate = n.AddedDate,
								@ChangedBy = n.ChangedBy,
								@ChangedDate = n.ChangedDate
						  FROM	Inserted i 
						  JOIN	bPMPN n WITH (NOLOCK)
							ON	i.PMCo = n.PMCo
						   AND	i.Project = n.Project
						   AND  i.NoteSeq = n.NoteSeq

					END --IF @numrows = 1
				ELSE
					BEGIN
						-- CREATE CURSOR --
						DECLARE NotifyCursor CURSOR LOCAL FAST_FORWARD FOR
							SELECT	i.PMCo, i.Project, i.Reviewer,
									n.AddedBy, n.AddedDate, n.ChangedBy, n.ChangedDate
							  FROM	Inserted i 
							  JOIN	bPMPN n WITH (NOLOCK)
								ON	i.PMCo = n.PMCo
							   AND	i.Project = n.Project
							   AND  i.NoteSeq = n.NoteSeq

						OPEN NotifyCursor

						-- CURSOR OPEN FLAG --
						SET @CursorOpen = 1

						FETCH NEXT FROM NotifyCursor
							INTO	@CoNum,	@ProjNum, @ToUser,
									@AddedBy, @AddedDate, @ChangedBy, @ChangedDate

					END -- DECLARE NotifyCursor


				-- ********************** --
				-- START Notify_Reviewer: --
				-- ********************** --
				Notify_Reviewer:

					-- ***************--
					-- PRIME VARIABLES --
					-- *************** --
					SET @rcode = 0
					SET @msg = ''
					SET @FromUser = SUSER_SNAME()


					-- SEND EMAIL TO REVIEWER --
					EXECUTE @rcode = vspPMProjectEmail	@ToUser, @FromUser,		
														@CoNum, @ProjNum,  
														@AddedBy, @AddedDate,
														@ChangedBy, @ChangedDate,
														@msg output
					-- ***************************************************** --
					-- DISREGARD ANY ERRORS IN THE vspPMProjectEmail ROUTINE --
					-- ***************************************************** --
				-- ******************** --
				-- END Notify_Reviewer: --
				-- ******************** --

				-- ****************************** --
				-- CHECK TO SEE IF CURSOR IS OPEN --
				-- ****************************** --
				IF @CursorOpen = 1
					BEGIN

						-- GET NEXT RECORD FROM CURSOR --
						FETCH NEXT FROM NotifyCursor
							INTO	@CoNum,	@ProjNum, @ToUser,
									@AddedBy, @AddedDate, @ChangedBy, @ChangedDate

						
						IF @@fetch_status = 0
							BEGIN
								GOTO Notify_Reviewer
							END
						ELSE
							BEGIN
								-- CLOSE AND REMOVE CURSOR FROM MEMORY --
								CLOSE NotifyCursor
								DEALLOCATE NotifyCursor

								-- CURSOR CLOSE FLAG --
								SET @CursorOpen = 0
							END
					END --@CursorOpen = 1
			END --IF UPPER(@RevStatus)
	END --IF UPDATE(RevStatus)


---- HQMA inserts
if update(RevStatus)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMNR', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') +
		' NoteSeq: ' + isnull(convert(varchar(8),i.NoteSeq),'') + ' Reviewer: ' + isnull(i.Reviewer,''),
		i.PMCo, 'C', 'RevStatus', d.RevStatus, i.RevStatus, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.NoteSeq=i.NoteSeq and d.Reviewer=i.Reviewer
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RevStatus,'') <> isnull(i.RevStatus,'') and c.AuditPMNR='Y'


return


error:
	IF @CursorOpen = 1
		BEGIN
			CLOSE NotifyCursor
			DEALLOCATE NotifyCursor
		END

	select @errmsg = isnull(@errmsg,'') + ' - cannot update PMNR'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction




GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMNR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMNR] ON [dbo].[bPMNR] ([PMCo], [Project], [NoteSeq], [Reviewer]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPMNRReviewers] ON [dbo].[bPMNR] ([Reviewer]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO

ALTER TABLE [dbo].[bPMNR] WITH NOCHECK ADD CONSTRAINT [FK_bPMNR_bPMPN] FOREIGN KEY ([PMCo], [Project], [NoteSeq]) REFERENCES [dbo].[bPMPN] ([PMCo], [Project], [NoteSeq]) ON DELETE CASCADE
GO
