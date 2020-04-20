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
	Title:	SM Cost Type (vSMCostType)
	Created: 12/04/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes: 

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMCostType]
(@Co bCompany, @DeleteDataYN char(1))

AS 


/** BACKUP vSMCostType TABLE **/
IF OBJECT_ID('vSMCostType_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMCostType_bak
END;
BEGIN
	SELECT * INTO vSMCostType_bak FROM vSMCostType
END;


/**DELETE DATA IN vSMCostType TABLE**/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMCostType NOCHECK CONSTRAINT ALL;
	ALTER TABLE vSMCostType DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMCostType WHERE SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';	
	ALTER TABLE vSMCostType CHECK CONSTRAINT ALL;
	ALTER TABLE vSMCostType ENABLE TRIGGER ALL;	
END;


/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXID int 
SET @MAXID=(SELECT ISNULL(MAX(SMCostTypeID),0) FROM dbo.vSMCostType)


/** POPULATE SM Cost Type **/
SET IDENTITY_INSERT vSMCostType ON
ALTER TABLE vSMCostType NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMCostType DISABLE TRIGGER ALL;

INSERT vSMCostType
	(
		 SMCostTypeID
		,SMCo
		,SMCostType
		,Description
		,SMCostTypeCategory
		,TaxableYN
		,Notes
		--,UniqueAttchID
		,PhaseGroup
		,JCCostType
		--UD Fields
		--,udConvertedYN 
	   )
--declare @Co bCompany set @Co=	
SELECT
		 SMCostTypeID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, xct.NewCostType)
		,SMCo=@Co
		,SMCostType=xct.NewCostType
		,Description=MAX(xct.NewDescription)
		,SMCostTypeCategory=MAX(
			CASE 
				WHEN jct.JBCategory='E' THEN 'E' 
				WHEN jct.JBCategory='M' THEN 'M' 
				WHEN jct.JBCategory='O' THEN 'O' 
				WHEN jct.JBCategory='S' THEN 'S' 
				ELSE 'L' 
			END)
		,TaxableYN=MAX(CASE WHEN pc.EXEMPTSTATUS='Taxable' THEN 'Y' ELSE 'N' END)          		
		,Notes=NULL
		--,UniqueAttchID
		,PhaseGroup=MAX(co.PhaseGroup)
		,JCCostType=MAX(jct.CostType)
		--UD Fields
		--,udConvertedYN='Y'
		
--declare @Co bCompany set @Co=
--SELECT xct.SMCo, xct.NewCostType
FROM CV_TL_Source_SM.dbo.PRODCODE pc
INNER JOIN budXRefSMCostTypes xct
	ON xct.SMCo=@Co AND xct.OldCostType=pc.PRODUCT
INNER JOIN bHQCO co
	ON co.HQCo=@Co	
LEFT JOIN budXRefJCCostType jct
	ON jct.PhaseGroup=co.PhaseGroup AND jct.TLCategory=pc.JCCAT
LEFT JOIN vSMCostType vct
	ON vct.SMCo=@Co AND vct.SMCostType=xct.NewCostType
WHERE vct.SMCostType IS NULL 
GROUP BY xct.SMCo, xct.NewCostType
ORDER BY xct.SMCo, xct.NewCostType;

SET IDENTITY_INSERT vSMCostType OFF
ALTER TABLE vSMCostType CHECK CONSTRAINT ALL;
ALTER TABLE vSMCostType ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from vSMCostType where SMCo=@Co;
select * from vSMCostType where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMCostType where SMCo=@Co;
select * from budXRefSMCostTypes where SMCo=@Co;
select * from budXRefJCCostType;

select LEFT(Accumulate_As,1),* --The first letter of Accumulate_As = JBCategory on budXRefJCCostType
from CV_TL_Source.dbo.JCM_MASTER__STANDARD_CATEGORY; 
**/
GO
