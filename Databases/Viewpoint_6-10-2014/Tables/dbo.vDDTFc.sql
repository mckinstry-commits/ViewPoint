CREATE TABLE [dbo].[vDDTFc]
(
[FolderTemplate] [smallint] NOT NULL,
[Title] [dbo].[bDesc] NOT NULL,
[Mod] [char] (2) COLLATE Latin1_General_BIN NULL,
[Active] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDTFc_Active] DEFAULT ('Y')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE TRIGGER [dbo].[vtdvDDTFc] on [dbo].[vDDTFc] FOR DELETE AS
-- =============================================
-- Created: Dave C 05/20/2009
--
-- Processes deletions to vDDTFc, performing cascading deletes to vDDTDc.
--
-- =============================================

set nocount on

		DELETE vDDTDc
		WHERE FolderTemplate IN (SELECT d.FolderTemplate FROM deleted d WHERE d.FolderTemplate > 9999)


GO
CREATE UNIQUE CLUSTERED INDEX [viDDTFc] ON [dbo].[vDDTFc] ([FolderTemplate]) ON [PRIMARY]
GO
