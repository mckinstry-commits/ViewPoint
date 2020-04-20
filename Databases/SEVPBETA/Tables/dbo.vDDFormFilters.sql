CREATE TABLE [dbo].[vDDFormFilters]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[FormName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[VPUserName] [dbo].[bVPUserName] NULL,
[Company] [dbo].[bCompany] NULL,
[FieldSeq] [smallint] NOT NULL,
[FilterValue] [varchar] (max) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
