USE Viewpoint
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.TABLES Where TABLE_NAME='MCKVPUserCreation' and TABLE_SCHEMA='dbo' and TABLE_TYPE='BASE TABLE' )
Begin
	Print 'DROP TABLE dbo.MCKVPUserCreation'
	DROP TABLE dbo.MCKVPUserCreation
End
GO

Print 'CREATE TABLE dbo.MCKVPUserCreation'
GO

CREATE TABLE [dbo].[MCKVPUserCreation](
	[Co] [float] NULL,
	[Role] [varchar](255) NULL,
	[UserName] [varchar](255) NULL,
	[Name] [varchar](255) NULL,
	[Email] [varchar](255) NULL,
	[RequestedBy] [varchar](255) NULL,
	[BatchNum] [varchar](30) NULL,
	[Creationdate] [datetime] NULL,
	[Createdby] [varchar](30) NULL,
	[Status] [varchar](30) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[MCKVPUserCreation] ADD  DEFAULT (getdate()) FOR [Creationdate]
GO

ALTER TABLE [dbo].[MCKVPUserCreation] ADD  DEFAULT (suser_sname()) FOR [Createdby]
GO

ALTER TABLE [dbo].[MCKVPUserCreation] ADD  DEFAULT ('N') FOR [Status]
GO


Grant INSERT ON dbo.MCKVPUserCreation TO [MCKINSTRY\Viewpoint Users]
