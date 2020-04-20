CREATE TABLE [dbo].[vWFProcessDetail]
(
[HeaderID] [bigint] NOT NULL,
[ProcessID] [bigint] NOT NULL,
[SourceView] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[SourceKeyID] [bigint] NOT NULL,
[CurrentStepID] [bigint] NULL,
[InitiatedBy] [dbo].[bVPUserName] NOT NULL CONSTRAINT [DF_vWFProcessDetail_InitiatedBy] DEFAULT (suser_name()),
[CreatedOn] [dbo].[bDate] NOT NULL CONSTRAINT [DF_vWFProcessDetail_CreatedOn] DEFAULT (getdate()),
[SourceDescription] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*********************************************/
CREATE trigger [dbo].[vtWFProcessDetaild] on [dbo].[vWFProcessDetail] for DELETE as
/*----------------------------------------------------------
* Created By:	GP 5/24/2012
* Modified By:
*
*/---------------------------------------------------------
declare @numrows int

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return


INSERT dbo.vWFProcessDetailHistory([Action], [DateTime], HeaderID, ProcessID, SourceView, SourceKeyID, CurrentStepID,
	InitiatedBy, CreatedOn, SourceDescription, KeyID)
SELECT 'DELETE', GETDATE(), HeaderID, ProcessID, SourceView, SourceKeyID, CurrentStepID,
	InitiatedBy, CreatedOn, SourceDescription, KeyID
FROM DELETED


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[vtWFProcessDetaili] on [dbo].[vWFProcessDetail] for INSERT as
/*-----------------------------------------------------------------
* Created By:	GP 5/24/2012
* Modified By:
*				
*
*
* This trigger audits insertion in vWFProcessDetail
*/----------------------------------------------------------------
declare @numrows int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


INSERT dbo.vWFProcessDetailHistory([Action], [DateTime], HeaderID, ProcessID, SourceView, SourceKeyID, CurrentStepID,
	InitiatedBy, CreatedOn, SourceDescription, KeyID)
SELECT 'INSERT', GETDATE(), HeaderID, ProcessID, SourceView, SourceKeyID, CurrentStepID,
	InitiatedBy, CreatedOn, SourceDescription, KeyID
FROM INSERTED


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**************************************/
CREATE trigger [dbo].[vtWFProcessDetailu] on [dbo].[vWFProcessDetail] for UPDATE as
/*-----------------------------------------------------------------
* Created By:	GP 5/24/2012
* Modified By:	
*
* No current error checks for update.	
*/----------------------------------------------------------------
declare @numrows int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


IF UPDATE(CurrentStepID)
BEGIN
	INSERT dbo.vWFProcessDetailHistory([Action], [DateTime], HeaderID, ProcessID, SourceView, SourceKeyID, CurrentStepID,
		InitiatedBy, CreatedOn, SourceDescription, FieldName, KeyID)
	SELECT 'UPDATE', GETDATE(), HeaderID, ProcessID, SourceView, SourceKeyID, CurrentStepID,
		InitiatedBy, CreatedOn, SourceDescription, 'CurrentStepID', KeyID
	FROM INSERTED
END


GO
ALTER TABLE [dbo].[vWFProcessDetail] ADD CONSTRAINT [PK_vWFDetail] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vWFProcessDetail_SourceKeyID] ON [dbo].[vWFProcessDetail] ([ProcessID], [SourceView], [SourceKeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWFProcessDetail] WITH NOCHECK ADD CONSTRAINT [FK_vWFProcessDetail_vWFProcessHeader] FOREIGN KEY ([HeaderID]) REFERENCES [dbo].[vWFProcessHeader] ([KeyID])
GO
