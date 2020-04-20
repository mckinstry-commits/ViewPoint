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
	Title:	Populate SM Cost Types (budXRefSMCostTypes) Cross Reference Table
	Created: 12/04/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes:

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_XRefSMCostTypes]
(@Co bCompany, @DeleteDataYN char(1))

AS 

/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXSeq INT
SET @MAXSeq=(SELECT ISNULL(MAX(Seq),0) FROM budXRefSMCostTypes) 


/** BACKUP budXRefSMCostTypes TABLE **/
IF OBJECT_ID('budXRefSMCostTypes_bak','U') IS NOT NULL
BEGIN
	DROP TABLE budXRefSMCostTypes_bak
END;
BEGIN
	SELECT * INTO budXRefSMCostTypes_bak FROM dbo.budXRefSMCostTypes
END;


/**DELETE DATA IN budXRefSMCostTypes TABLE**/
IF @DeleteDataYN IN('Y','y')
BEGIN
	DELETE budXRefSMCostTypes WHERE SMCo=@Co
END;


/** CHANGE NewYN='N' FOR REFRESH **/
--declare @Co bCompany set @Co=	
UPDATE budXRefSMCostTypes
SET NewYN='N'
WHERE SMCo=@Co and NewYN='Y'


/** INSERT/UPDATE SM COST TYPES XREFERENCE TABLE **/
IF OBJECT_ID('budXRefSMCostTypes') IS NOT NULL
BEGIN
	INSERT dbo.budXRefSMCostTypes
		(
				Seq
			   ,OldSMCo
			   ,OldCostType
			   ,OldDescription
			   ,SMCo
			   ,NewCostType
			   ,NewDescription
			   ,ActiveYN
			   ,NewYN
			   --,UniqueAttchID
			   ,Notes
		   )
	--declare @Co bCompany set @Co=	
	SELECT
				Seq=@MAXSeq+ROW_NUMBER () OVER (ORDER BY @Co,xct.OldCostType)
			   ,OldSMCo=@Co
			   ,OldCostType=pc.PRODUCT
			   ,OldDescription=pc.DESCRIPTION
			   ,SMCo=@Co
			   ,NewCostType=pc.PRODUCT --Default
			   ,NewDescription=pc.DESCRIPTION
			   ,ActiveYN=CASE WHEN QINACTIVE='N' THEN 'Y' ELSE 'N' END
			   ,NewYN='Y'
			   --,UniqueAttchID
			   ,Notes=NULL
		
	--declare @Co bCompany set @Co=
	--SELECT *
	FROM CV_TL_Source_SM.dbo.PRODCODE pc
	LEFT JOIN budXRefSMCostTypes xct
		ON xct.SMCo=@Co AND xct.OldCostType=pc.PRODUCT
	WHERE xct.OldCostType IS NULL
	ORDER BY xct.SMCo, xct.OldCostType;
END;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
SELECT COUNT(*) FROM budXRefSMCostTypes WHERE SMCo=@Co;
SELECT * FROM budXRefSMCostTypes WHERE SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
SELECT * FROM vSMType WHERE SMCo=@Co;
SELECT * FROM CV_TL_Source_SM.dbo.PRODUCT;
**/


GO
