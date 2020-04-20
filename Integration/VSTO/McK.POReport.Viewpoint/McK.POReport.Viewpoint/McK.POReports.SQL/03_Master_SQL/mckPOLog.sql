USE Viewpoint
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.TABLES Where TABLE_NAME='mckPOLog' and TABLE_SCHEMA='dbo' and TABLE_TYPE='BASE TABLE' )
Begin
	Print 'DROP TABLE dbo.mckPOLog'
	DROP TABLE dbo.mckPOLog
End
GO

Print 'CREATE TABLE dbo.mckPOLog'
GO


CREATE TABLE dbo.mckPOLog(
	KeyID			bigint IDENTITY(1,1) NOT NULL,
	VPUserName	dbo.bVPUserName NULL,
	DateTime		datetime NULL,
	Version		varchar(7) NULL,
	JCCo			dbo.bCompany NULL,
	POFrom		varchar(30) NULL,
	POTo			varchar(30) NULL,
	DateFrom		dbo.bMonth	NULL,
	DateTo		dbo.bMonth	NULL,
	Action		varchar(20) NULL,
	Details		varchar(50) NULL,
	ErrorText	varchar(255) NULL,
 CONSTRAINT [PK_POLog] PRIMARY KEY CLUSTERED 
(
	[KeyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]

GO


Grant INSERT ON dbo.mckPOLog TO [MCKINSTRY\Viewpoint Users]

--select * from mckPOLog