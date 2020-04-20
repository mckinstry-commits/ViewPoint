CREATE TABLE [dbo].[vWFProcessDetailStep]
(
[ProcessDetailID] [bigint] NOT NULL,
[Step] [int] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


 
/*********************************************/
CREATE trigger [dbo].[vtWFProcessDetailStepd] on [dbo].[vWFProcessDetailStep] for DELETE as
/*----------------------------------------------------------
* Created By:	GP 5/24/2012
* Modified By:	GP 6/12/2012 - TK-15656 Removed Status column
*
*/---------------------------------------------------------
declare @numrows int

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return


INSERT dbo.vWFProcessDetailStepHistory([Action], [DateTime], ProcessDetailID, Step, KeyID)
SELECT 'DELETE', GETDATE(), ProcessDetailID, Step, KeyID
FROM DELETED



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE trigger [dbo].[vtWFProcessDetailStepi] on [dbo].[vWFProcessDetailStep] for INSERT as
/*-----------------------------------------------------------------
* Created By:	GP 5/24/2012
* Modified By:	GP 6/12/2012 - TK-15656 Removed Status column
*				
* This trigger audits insertion in vWFProcessDetail
*/----------------------------------------------------------------
declare @numrows int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


INSERT dbo.vWFProcessDetailStepHistory([Action], [DateTime], ProcessDetailID, Step, KeyID)
SELECT 'INSERT', GETDATE(), ProcessDetailID, Step, KeyID
FROM INSERTED



GO
ALTER TABLE [dbo].[vWFProcessDetailStep] ADD CONSTRAINT [PK_vWFProcessDetailStep] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vWFProcessDetailStep_Step] ON [dbo].[vWFProcessDetailStep] ([ProcessDetailID], [Step]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWFProcessDetailStep] WITH NOCHECK ADD CONSTRAINT [FK_vWFProcessDetailStep_vWFProcessDetail] FOREIGN KEY ([ProcessDetailID]) REFERENCES [dbo].[vWFProcessDetail] ([KeyID])
GO
ALTER TABLE [dbo].[vWFProcessDetailStep] NOCHECK CONSTRAINT [FK_vWFProcessDetailStep_vWFProcessDetail]
GO
