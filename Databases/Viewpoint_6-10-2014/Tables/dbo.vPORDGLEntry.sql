CREATE TABLE [dbo].[vPORDGLEntry]
(
[GLEntryID] [bigint] NOT NULL,
[GLTransactionForPOItemLineAccount] [int] NOT NULL,
[APTLGLID] [bigint] NULL,
[PORDGLID] [bigint] NULL
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
CREATE TRIGGER [dbo].[vtPORDGLEntryd]
   ON  [dbo].[vPORDGLEntry]
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
ALTER TABLE [dbo].[vPORDGLEntry] ADD CONSTRAINT [PK_vPORDGLEntry] PRIMARY KEY CLUSTERED  ([GLEntryID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPORDGLEntry] WITH NOCHECK ADD CONSTRAINT [FK_vPORDGLEntry_vAPTLGL] FOREIGN KEY ([APTLGLID]) REFERENCES [dbo].[vAPTLGL] ([APTLGLID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPORDGLEntry] WITH NOCHECK ADD CONSTRAINT [FK_vPORDGLEntry_vGLEntry] FOREIGN KEY ([GLEntryID]) REFERENCES [dbo].[vGLEntry] ([GLEntryID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPORDGLEntry] WITH NOCHECK ADD CONSTRAINT [FK_vPORDGLEntry_vGLEntryTransaction] FOREIGN KEY ([GLEntryID], [GLTransactionForPOItemLineAccount]) REFERENCES [dbo].[vGLEntryTransaction] ([GLEntryID], [GLTransaction])
GO
ALTER TABLE [dbo].[vPORDGLEntry] WITH NOCHECK ADD CONSTRAINT [FK_vPORDGLEntry_vPORDGL] FOREIGN KEY ([PORDGLID]) REFERENCES [dbo].[vPORDGL] ([PORDGLID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPORDGLEntry] NOCHECK CONSTRAINT [FK_vPORDGLEntry_vAPTLGL]
GO
ALTER TABLE [dbo].[vPORDGLEntry] NOCHECK CONSTRAINT [FK_vPORDGLEntry_vGLEntry]
GO
ALTER TABLE [dbo].[vPORDGLEntry] NOCHECK CONSTRAINT [FK_vPORDGLEntry_vGLEntryTransaction]
GO
ALTER TABLE [dbo].[vPORDGLEntry] NOCHECK CONSTRAINT [FK_vPORDGLEntry_vPORDGL]
GO
