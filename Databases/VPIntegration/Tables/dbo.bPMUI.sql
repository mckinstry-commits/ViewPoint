CREATE TABLE [dbo].[bPMUI]
(
[ImportRoutine] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[FileType] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL,
[Delimiter] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[OtherDelim] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[TextQualifier] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[ScheduleOfValues] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUI_ScheduleOfValues] DEFAULT ('N'),
[StandardItemCode] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUI_StandardItemCode] DEFAULT ('Y'),
[RecordTypeCol] [int] NULL,
[BegRecTypePos] [int] NULL,
[EndRecTypePos] [int] NULL,
[XMLRowTag] [varchar] (30) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMUI] ADD CONSTRAINT [PK_bPMUI] PRIMARY KEY CLUSTERED  ([ImportRoutine]) ON [PRIMARY]
GO
