USE Viewpoint
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.TABLES Where TABLE_NAME='MCKPOLoad' and TABLE_SCHEMA='dbo' and TABLE_TYPE='BASE TABLE' )
Begin
	Print 'DROP TABLE dbo.MCKPOLoad'
	DROP TABLE dbo.MCKPOLoad
End
GO

Print 'CREATE TABLE dbo.MCKPOLoad'
GO

CREATE TABLE [dbo].MCKPOLoad(
	[JCCo]		TINYINT NOT NULL,
	[MCKPO]		[nvarchar](255) NOT NULL,
	[PO]		[nvarchar](255) NULL,
	[BatchNum]	[varchar](30) NULL,
	[BatchMth]	[datetime] NULL,
	[Creationdate] [datetime] NULL DEFAULT (getdate()),
	[Createdby] [varchar](30) NULL DEFAULT (suser_sname()),
	[Status]	[varchar](30) NULL DEFAULT ('P')

) ON [PRIMARY]

GO

Grant INSERT, SELECT, UPDATE ON dbo.MCKPOLoad TO [MCKINSTRY\Viewpoint Users]
GO



