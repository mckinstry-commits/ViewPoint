USE Viewpoint
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.TABLES Where TABLE_NAME='mckDetailInvoiceLog' and TABLE_SCHEMA='dbo' and TABLE_TYPE='BASE TABLE' )
Begin
	Print 'DROP TABLE dbo.mckDetailInvoiceLog'
	DROP TABLE dbo.mckDetailInvoiceLog
End
GO

Print 'CREATE TABLE dbo.mckDetailInvoiceLog'
GO


CREATE TABLE dbo.mckDetailInvoiceLog
(
	KeyID				bigint IDENTITY(1,1) NOT NULL,
	VPUserName		dbo.bVPUserName NULL,
	DateTime			datetime		NULL,
	Version			varchar(7)	NULL,
	JCCo				dbo.bCompany NULL,
	InvoiceFrom		varchar(10) NULL,
	InvoiceTo		varchar(10) NULL,
	DateFrom			dbo.bMonth	NULL,
	DateTo			dbo.bMonth	NULL,
	Action			varchar(20) NULL,
	Details			varchar(50) NULL,
	ErrorText		varchar(255) NULL,
 CONSTRAINT PK_DetailInvoiceLog PRIMARY KEY CLUSTERED 
	(
		KeyID ASC
	) 
) 

GO



Grant INSERT ON dbo.mckDetailInvoiceLog TO [MCKINSTRY\Viewpoint Users]

--  select * from DetailInvoiceLog

