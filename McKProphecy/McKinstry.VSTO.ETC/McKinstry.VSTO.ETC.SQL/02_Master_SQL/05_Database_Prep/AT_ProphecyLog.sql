/*
   Thursday, October 19, 20172:42:26 PM
   User: 
   Server: MCKTESTSQL05\VIEWPOINT
   Database: Viewpoint
   Application: 
*/

/* To prevent any potential data loss issues, you should review this script in detail before running it outside the context of the database designer.*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE mers.Tmp_ProphecyLog
	(
	KeyID bigint NOT NULL IDENTITY (1, 1),
	VPUserName dbo.bVPUserName NULL,
	DateTime datetime NULL,
	Version varchar(6) NULL,
	JCCo dbo.bCompany NULL,
	Contract dbo.bContract NULL,
	Job dbo.bJob NULL,
	Mth dbo.bMonth NULL,
	BatchId dbo.bBatchID NULL,
	Action varchar(20) NULL,
	FullETC varchar(1) NULL,
	HoursWeeks varchar(1) NULL,
	Details varchar(50) NULL,
	ErrorText varchar(255) NULL
	)  ON [PRIMARY]
GO
ALTER TABLE mers.Tmp_ProphecyLog SET (LOCK_ESCALATION = TABLE)
GO
SET IDENTITY_INSERT mers.Tmp_ProphecyLog ON
GO
IF EXISTS(SELECT * FROM mers.ProphecyLog)
	 EXEC('INSERT INTO mers.Tmp_ProphecyLog (KeyID, VPUserName, DateTime, Version, JCCo, Contract, Job, Mth, BatchId, Action, FullETC, Details, ErrorText)
		SELECT KeyID, VPUserName, DateTime, Version, JCCo, Contract, Job, Mth, BatchId, Action, FullETC, Details, ErrorText FROM mers.ProphecyLog WITH (HOLDLOCK TABLOCKX)')
GO
SET IDENTITY_INSERT mers.Tmp_ProphecyLog OFF
GO
DROP TABLE mers.ProphecyLog
GO
EXECUTE sp_rename N'mers.Tmp_ProphecyLog', N'ProphecyLog', 'OBJECT' 
GO
ALTER TABLE mers.ProphecyLog ADD CONSTRAINT
	PK_ProphecyLog PRIMARY KEY CLUSTERED 
	(
	KeyID
	) WITH( PAD_INDEX = OFF, FILLFACTOR = 80, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
COMMIT
