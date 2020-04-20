CREATE TABLE [dbo].[vAPTLGLEntry]
(
[GLEntryID] [bigint] NOT NULL,
[GLTransactionForAPTransactionLineAccount] [int] NOT NULL,
[APTLGLID] [bigint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/31/11
-- Description:	Cascade deletes the connected GLEntry
-- =============================================
CREATE TRIGGER [dbo].[vtAPTLGLEntryd]
   ON  [dbo].[vAPTLGLEntry]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   DELETE dbo.vGLEntry
   WHERE GLEntryID IN (SELECT GLEntryID FROM DELETED)

END

GO
ALTER TABLE [dbo].[vAPTLGLEntry] ADD CONSTRAINT [PK_vAPTLGLEntry] PRIMARY KEY CLUSTERED  ([GLEntryID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vAPTLGLEntry] WITH NOCHECK ADD CONSTRAINT [FK_vAPTLGLEntry_vAPTLGL] FOREIGN KEY ([APTLGLID]) REFERENCES [dbo].[vAPTLGL] ([APTLGLID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vAPTLGLEntry] WITH NOCHECK ADD CONSTRAINT [FK_vAPTLGLEntry_vGLEntry] FOREIGN KEY ([GLEntryID]) REFERENCES [dbo].[vGLEntry] ([GLEntryID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vAPTLGLEntry] WITH NOCHECK ADD CONSTRAINT [FK_vAPTLGLEntry_vGLEntryTransaction] FOREIGN KEY ([GLEntryID], [GLTransactionForAPTransactionLineAccount]) REFERENCES [dbo].[vGLEntryTransaction] ([GLEntryID], [GLTransaction])
GO
ALTER TABLE [dbo].[vAPTLGLEntry] NOCHECK CONSTRAINT [FK_vAPTLGLEntry_vAPTLGL]
GO
ALTER TABLE [dbo].[vAPTLGLEntry] NOCHECK CONSTRAINT [FK_vAPTLGLEntry_vGLEntry]
GO
ALTER TABLE [dbo].[vAPTLGLEntry] NOCHECK CONSTRAINT [FK_vAPTLGLEntry_vGLEntryTransaction]
GO
