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
	Title:	Populate SM Agreement Types (budXRefSMAgrTypes) Cross Reference Table
	Created: 12/03/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes:

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_XRefSMAgrTypes]
(@Co bCompany, @DeleteDataYN char(1))

AS 

/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXSeq INT
SET @MAXSeq=(SELECT ISNULL(MAX(Seq),0) FROM budXRefSMAgrTypes) 


/** BACKUP budXRefSMAgrTypes TABLE **/
IF OBJECT_ID('budXRefSMAgrTypes_bak','U') IS NOT NULL
BEGIN
	DROP TABLE budXRefSMAgrTypes_bak
END;
BEGIN
	SELECT * INTO budXRefSMAgrTypes_bak FROM budXRefSMAgrTypes
END;


/**DELETE DATA IN budXRefSMAgrTypes TABLE**/
if @DeleteDataYN IN('Y','y')
BEGIN
	DELETE budXRefSMAgrTypes WHERE SMCo=@Co
END;


/** CHANGE NewYN='N' FOR REFRESH **/
--declare @Co bCompany set @Co=	
UPDATE budXRefSMAgrTypes
SET NewYN='N'
WHERE SMCo=@Co AND NewYN='Y'


/** INSERT/UPDATE SM AGREEMENT TYPES XREFERENCE TABLE **/
IF OBJECT_ID('budXRefSMAgrTypes') IS NOT NULL
BEGIN
	INSERT dbo.budXRefSMAgrTypes
		(
				Seq
			   ,OldSMCo
			   ,OldAgrType
			   ,OldDescription
			   ,SMCo
			   ,NewAgrType
			   ,NewDescription
			   ,ActiveYN
			   ,NewYN
			   --,UniqueAttchID
			   ,Notes
		   )
	--declare @Co bCompany set @Co=	
	SELECT
				Seq=@MAXSeq+ROW_NUMBER () OVER (ORDER BY @Co,agt.AGRTYPENBR)
			   ,OldSMCo=@Co
			   ,OldAgrType=agt.AGRTYPENBR
			   ,OldDescription=agt.DESCRIPTION
			   ,SMCo=@Co
			   ,NewAgrType=agt.AGRTYPENBR --Default
			   ,NewDescription=agt.DESCRIPTION
			   ,ActiveYN=CASE WHEN QINACTIVE='N' THEN 'Y' ELSE 'N' END
			   ,NewYN='Y'
			   --,UniqueAttchID
			   ,Notes=NULL
		
	--declare @Co bCompany set @Co=
	--SELECT *
	FROM CV_TL_Source_SM.dbo.AGRTYPE agt
	LEFT JOIN budXRefSMAgrTypes xat
		ON xat.SMCo=@Co AND xat.OldAgrType=agt.AGRTYPENBR
	WHERE xat.OldAgrType IS NULL
	ORDER BY xat.SMCo, xat.OldAgrType;
END;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
SELECT COUNT(*) FROM budXRefSMAgrTypes WHERE SMCo=@Co;
SELECT * FROM budXRefSMAgrTypes WHERE SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
SELECT * FROM vSMAgreementType WHERE SMCo=@Co;
SELECT * FROM CV_TL_Source_SM.dbo.AGRTYPE
**/


GO
