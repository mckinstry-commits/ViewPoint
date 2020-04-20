SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================================
Copyright Â© 2013 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================================
	Title:	SM Call Type (vSMCallType)
	Created: 05/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 11/26/2012 BBA - Added disable and enable trigger commands.
		2. 12/03/2012 BBA - Removed coding that used QINACTIVE column to filter as 
			per Scott Hegrenes we should convert everything by default regardless of this
			status field in STO SM. Added code to use a UD Cross Ref: SM Call Types table.

Notes: 

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMCallType]
(@Co bCompany, @DeleteDataYN char(1))

AS 


/** BACKUP vSMCallType TABLE **/
IF OBJECT_ID('vSMCallType_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMCallType_bak
END;
BEGIN
	SELECT * INTO vSMCallType_bak FROM vSMCallType
END;


/**DELETE DATA IN vSMCallType TABLE**/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMCallType NOCHECK CONSTRAINT ALL;
	ALTER TABLE vSMCallType DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMCallType WHERE SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';	
	ALTER TABLE vSMCallType CHECK CONSTRAINT ALL;
	ALTER TABLE vSMCallType ENABLE TRIGGER ALL;
END;


/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXID INT 
SET @MAXID=(SELECT ISNULL(MAX(SMCallTypeID),0) FROM dbo.vSMCallType)


/** POPULATE SM Call Types **/
SET IDENTITY_INSERT vSMCallType ON
ALTER TABLE vSMCallType NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMCallType DISABLE TRIGGER ALL;

INSERT vSMCallType
	(
		 SMCallTypeID
		,SMCo
		,CallType
		,Description
		,Active
		,Notes
		,IsTrackingWIP
		--,UniqueAttchID
		--UD Fields
		--,udConvertedYN 
	   )
--declare @Co bCompany set @Co=	
SELECT
		 SMCallTypeID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, xct.NewCallType)
		,SMCo=@Co
		,CallType=xct.NewCallType
		,Description=MAX(ct.DESCRIPTION)
		,Active=MAX(CASE WHEN ct.QINACTIVE='N' THEN 'Y' ELSE 'N' END)
		,Notes=NULL
		,IsTrackingWIP=MAX(ct.QWIPACCTG)
		--,UniqueAttchID
		--UD Fields
		--,udConvertedYN='Y'
		
--declare @Co bCompany set @Co=
--SELECT *
FROM CV_TL_Source_SM.dbo.CALLTYPE ct
INNER JOIN budXRefSMCallTypes xct
	ON xct.SMCo=@Co AND xct.OldCallType=ct.CALLTYPECODE
LEFT JOIN vSMCallType vct
	ON vct.SMCo=@Co AND vct.CallType=ct.CALLTYPECODE
WHERE vct.CallType IS NULL 
GROUP BY xct.SMCo, xct.NewCallType
ORDER BY xct.SMCo, xct.NewCallType;

SET IDENTITY_INSERT vSMCallType OFF
ALTER TABLE vSMCallType CHECK CONSTRAINT ALL;
ALTER TABLE vSMCallType ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from vSMCallType where SMCo=@Co;
select * from vSMCallType where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
SELECT * FROM vSMCallType where SMCo=@Co;
SELECT * FROM CV_TL_Source_SM.dbo.CALLTYPE;
SELECT DISTINCT CALLTYPECODE FROM CV_TL_Source_SM.dbo.CALLTYPE;

**/
GO
