SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================================
Copyright Â© 2012 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================================
	Title:	SM Type (vSMType)
	Created: 11/26/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes: STO Equipment Types

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMType]
(@Co bCompany, @DeleteDataYN char(1))

AS 


/** BACKUP vSMType TABLE **/
IF OBJECT_ID('vSMType_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMType_bak
END;
BEGIN
	SELECT * INTO vSMType_bak FROM vSMType
END;


/** DELETE DATA IN vSMType TABLE **/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMType NOCHECK CONSTRAINT ALL;
	ALTER TABLE vSMType DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMType WHERE SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';	
	ALTER TABLE vSMType CHECK CONSTRAINT ALL;
	ALTER TABLE vSMType ENABLE TRIGGER ALL;
END;


/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXID int 
SET @MAXID=(SELECT ISNULL(MAX(SMTypeID),0) FROM dbo.vSMType)


/** POPULATE SM Types **/
SET IDENTITY_INSERT vSMType ON
ALTER TABLE vSMType NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMType DISABLE TRIGGER ALL;

INSERT vSMType
	(
		 SMTypeID
		,SMCo
		,Class
		,Type
		,Description
		,Active
		,Notes
		--,UniqueAttchID
		--UD Fields
		--,udConvertedYN 
	   )
--declare @Co bCompany set @Co=	
SELECT
		 SMTypeID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, xet.NewClass, xet.NewEQPType)
		,SMCo=@Co
		,Class=xet.NewClass
		,Type=xet.NewEQPType
		,Description=MAX(xet.NewDescription)
		,Active=MAX(CASE WHEN eqt.QINACTIVE='N' THEN 'Y' ELSE 'N' END)
		,Notes=NULL
		--,UniqueAttchID
		--UD Fields
		--,udConvertedYN='Y'
		
--declare @Co bCompany set @Co=1
--SELECT *
FROM CV_TL_Source_SM.dbo.EQPTYPE eqt
INNER JOIN budXRefSMEQPTypes xet
	ON xet.SMCo=@Co AND xet.OldEQPType=eqt.EQPTYPE
LEFT JOIN vSMType vtp
	ON vtp.SMCo=@Co AND vtp.Type=eqt.EQPTYPE
WHERE vtp.Type IS NULL
GROUP BY xet.SMCo, xet.NewClass, xet.NewEQPType 
ORDER BY xet.SMCo, xet.NewClass, xet.NewEQPType;

SET IDENTITY_INSERT vSMType OFF
ALTER TABLE vSMType CHECK CONSTRAINT ALL;
ALTER TABLE vSMType ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
SELECT COUNT(*) FROM vSMType WHERE SMCo=@Co;
SELECT * FROM vSMType WHERE SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMType where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.EQPCLASS;
select * from CV_TL_Source_SM.dbo.EQPTYPE;
**/
GO
