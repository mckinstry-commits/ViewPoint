CREATE TABLE [dbo].[vDDFormRelatedInfo]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Detail] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vDDFormRelatedInfo_Detail] DEFAULT ('N'),
[TypeColumn1] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[KeyColumn1] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DateColumn1] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DescColumn1] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DefaultTypeDesc] [nvarchar] (128) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vDDFormRelatedInfo] WITH NOCHECK ADD
CONSTRAINT [FK_vDDFormRelatedInfo_vDDFH_Form] FOREIGN KEY ([Form]) REFERENCES [dbo].[vDDFH] ([Form]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vDDFormRelatedInfo] ADD CONSTRAINT [PK_vDDFormRelatedInfo] PRIMARY KEY CLUSTERED  ([Form]) ON [PRIMARY]
GO
