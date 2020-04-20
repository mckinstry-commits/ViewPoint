Use Viewpoint;
Go
-- Creates MCKPO error logging table

If EXISTS ( Select * From INFORMATION_SCHEMA.TABLES Where TABLE_NAME='MCKPOerror' and TABLE_SCHEMA='dbo' and TABLE_TYPE='BASE TABLE' )
Begin
	Print 'DROP TABLE dbo.MCKPOerror'
	DROP TABLE dbo.MCKPOerror
End
GO

Print 'CREATE TABLE dbo.MCKPOerror'
GO

Create table dbo.MCKPOerror(
	JCCo			bCompany		NULL
	,BatchNum	varchar(30)	NULL
	,MCKPO		varchar(30)	NULL
	,PO			varchar(30)	NULL
	,BatchMth	bMonth		NULL
	,ErrMsg		varchar(255)	NULL
	,ErrDate		datetime		NULL DEFAULT (getdate()),
	);

Grant INSERT, Select, Update ON dbo.MCKPOerror TO [MCKINSTRY\Viewpoint Users]
GO