CREATE TABLE [dbo].[vWFChecklists]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[Company] [dbo].[bCompany] NULL,
[Checklist] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Status] [int] NULL,
[Description] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[ReqCompletion] [datetime] NULL,
[DateCompleted] [datetime] NULL,
[EnforceOrder] [dbo].[bYN] NOT NULL,
[UseEmail] [dbo].[bYN] NOT NULL,
[IsPrivate] [dbo].[bYN] NOT NULL,
[AddedBy] [dbo].[bVPUserName] NULL,
[AddedOn] [datetime] NULL,
[ChangedBy] [dbo].[bVPUserName] NULL,
[ChangedOn] [datetime] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: Charles Courchaine 12/20/2007
* Modified: 
*
*	This trigger updates the AddedBy, AddedOn, ChangedBy, and ChangedOn fields for audit information
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFChecklistsi] 
   ON  [dbo].[vWFChecklists] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
update vWFChecklists set AddedBy = suser_sname(), AddedOn = GetDate(), ChangedBy = suser_sname(), ChangedOn = GetDate(), [Status] = (select min(WFStatusCodes.StatusID) from WFStatusCodes where StatusType = 0 and IsChecklistStatus = 'Y')
	from vWFChecklists c
	inner join inserted i on i.Checklist = c.Checklist and i.Company = c.Company
	
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: Charles Courchaine 12/18/2007
* Modified: 
*
*	This trigger updates the AddedBy, AddedOn, ChangedBy, and ChangedOn fields for audit information
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFChecklistsu] 
   ON  [dbo].[vWFChecklists] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
update vWFChecklists set ChangedBy = suser_sname(), ChangedOn = GetDate() 
	from vWFChecklists c
	inner join inserted i on i.Checklist = c.Checklist and i.Company = c.Company
END

GO
ALTER TABLE [dbo].[vWFChecklists] ADD CONSTRAINT [PK_vWFChecklists] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vWFChecklists_Checklist] ON [dbo].[vWFChecklists] ([Checklist], [Company]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vWFChecklists_Tasklist] ON [dbo].[vWFChecklists] ([Company], [EnforceOrder]) INCLUDE ([Checklist]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWFChecklists] WITH NOCHECK ADD CONSTRAINT [FK_vWFChecklists_vWFStatusCodes] FOREIGN KEY ([Status]) REFERENCES [dbo].[vWFStatusCodes] ([StatusID])
GO
