CREATE TABLE [dbo].[bIMTD]
(
[ImportTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[RecordType] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NULL,
[Identifier] [int] NOT NULL,
[DefaultValue] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ColDesc] [dbo].[bDesc] NULL,
[FormatInfo] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Required] [smallint] NULL,
[XRefName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[RecColumn] [int] NULL,
[BegPos] [int] NULL,
[EndPos] [int] NULL,
[BidtekDefault] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[UserDefault] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OverrideYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bIMTD_OverrideYN] DEFAULT ('N'),
[UpdateKeyYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bIMTD_UpdateKeyYN] DEFAULT ('N'),
[UpdateValueYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bIMTD_UpdateValueYN] DEFAULT ('N'),
[ImportPromptYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bIMTD_ImportPromptYN] DEFAULT ('N'),
[XMLTag] [varchar] (30) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE TRIGGER [dbo].[btIMTDi] on [dbo].[bIMTD] FOR INSERT AS

/*-----------------------------------------------------------------
* Created by:	Dave C 8/3/2009
* Modified by:	
*
* Purpose:		#134967 -- Converts empty strings ('') in the UserDefault
*				field to NULL when DefaultValue is set to '[Bidtek]' on records
*				inserted into bIMTD
*
*
*
*/----------------------------------------------------------------

		BEGIN
			UPDATE dbo.bIMTD
			SET UserDefault = NULL
				FROM dbo.bIMTD d INNER JOIN inserted i ON
					d.ImportTemplate = i.ImportTemplate
				AND d.RecordType = i.RecordType
				AND d.Identifier = i.Identifier
				WHERE i.UserDefault = ''
		END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE TRIGGER [dbo].[btIMTDu] on [dbo].[bIMTD] FOR UPDATE AS

/*-----------------------------------------------------------------
* Created by:	Dave C 8/3/2009
* Modified by:	
*
* Purpose:		#134967 -- Converts empty strings ('') in the UserDefault
*				field to NULL when DefaultValue is set to '[Bidtek]' on records
*				updated in bIMTD
*
*
*
*/----------------------------------------------------------------


		BEGIN
			UPDATE dbo.bIMTD
			SET UserDefault = NULL
				FROM dbo.bIMTD d INNER JOIN inserted i ON
					d.ImportTemplate = i.ImportTemplate
				AND d.RecordType = i.RecordType
				AND d.Identifier = i.Identifier
				WHERE i.UserDefault = ''
		END
GO
CREATE UNIQUE CLUSTERED INDEX [biIMTD] ON [dbo].[bIMTD] ([ImportTemplate], [RecordType], [Identifier]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bIMTD].[OverrideYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bIMTD].[UpdateKeyYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bIMTD].[UpdateValueYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bIMTD].[ImportPromptYN]'
GO
