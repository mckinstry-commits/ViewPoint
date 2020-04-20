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
	Title:	SM Labor Codes (vSMLaborCode)
	Created: 11/26/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes: 

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMLaborCode]
(@Co bCompany, @DeleteDataYN char(1))

AS 


/** BACKUP vSMLaborCode TABLE **/
IF OBJECT_ID('vSMLaborCode_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMLaborCode_bak
END;
BEGIN
	SELECT * INTO vSMLaborCode_bak FROM vSMLaborCode
END;


/**DELETE DATA IN vSMLaborCode TABLE**/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMLaborCode NOCHECK CONSTRAINT ALL;
	ALTER TABLE vSMLaborCode DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMLaborCode WHERE SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';	
	ALTER TABLE vSMLaborCode CHECK CONSTRAINT ALL;
	ALTER TABLE vSMLaborCode ENABLE TRIGGER ALL;
END;


/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXID int 
SET @MAXID=(SELECT ISNULL(MAX(SMLaborCodeID),0) FROM dbo.vSMLaborCode)


/** POPULATE SM Labor Codes **/
SET IDENTITY_INSERT vSMLaborCode ON
ALTER TABLE vSMLaborCode NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMLaborCode DISABLE TRIGGER ALL;

INSERT vSMLaborCode
	(
		 SMLaborCodeID
		,SMCo
		,LaborCode
		,Description
		,Active
		,Notes
		--,UniqueAttchID
		,PhaseGroup
		,JCCostType
		--UD Fields
		--,udConvertedYN 
	   )
--declare @Co bCompany set @Co=	
SELECT
		 SMLaborCodeID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, xlc.NewLaborCode)
		,SMCo=@Co
		,LaborCode=xlc.NewLaborCode
		,Description=MAX(xlc.NewDescription)
		,Active=MAX(xlc.ActiveYN)
		,Notes=NULL
		--,UniqueAttchID
		,PhaseGroup=MAX(co.PhaseGroup)
		,JCCostType=MAX(xlc.JCCostType)
		--UD Fields
		--,udConvertedYN='Y'
		
--declare @Co bCompany set @Co=
--SELECT *
FROM budXRefSMLaborCodes xlc
INNER JOIN bHQCO co
	ON co.HQCo=@Co	
LEFT JOIN vSMLaborCode vlc
	ON vlc.SMCo=@Co and vlc.LaborCode=xlc.NewLaborCode
WHERE vlc.LaborCode IS NULL
GROUP BY xlc.SMCo, xlc.NewLaborCode
ORDER BY xlc.SMCo, xlc.NewLaborCode;

SET IDENTITY_INSERT vSMLaborCode OFF
ALTER TABLE vSMLaborCode CHECK CONSTRAINT ALL;
ALTER TABLE vSMLaborCode ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from vSMLaborCode where SMCo=@Co;
select * from vSMLaborCode where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMLaborCode where SMCo=@Co;
select * from budXRefSMLaborCodes where SMCo=@Co;
**/
GO
