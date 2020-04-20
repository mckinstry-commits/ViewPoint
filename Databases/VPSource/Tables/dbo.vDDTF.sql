CREATE TABLE [dbo].[vDDTF]
(
[FolderTemplate] [smallint] NOT NULL,
[Title] [dbo].[bDesc] NOT NULL,
[Mod] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE TRIGGER [dbo].[vtdvDDTF] on [dbo].[vDDTF] FOR DELETE AS
-- =============================================
-- Created: Dave C 05/26/2009
--
-- Processes deletions to vDDTF, performing cascading deletes to vDDTD.
--
-- =============================================

set nocount on

		DELETE vDDTD
		WHERE FolderTemplate IN (SELECT d.FolderTemplate FROM deleted d WHERE d.FolderTemplate < 10000)


GO
CREATE UNIQUE CLUSTERED INDEX [viDDTF] ON [dbo].[vDDTF] ([FolderTemplate]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
