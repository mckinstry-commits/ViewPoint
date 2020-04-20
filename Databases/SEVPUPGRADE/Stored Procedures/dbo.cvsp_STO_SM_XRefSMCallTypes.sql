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
	Title:	Populate SM Call Types (budXRefSMCallTypes) Cross Reference Table
	Created: 12/03/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes:

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_XRefSMCallTypes]
(@Co bCompany, @DeleteDataYN CHAR(1))

AS 

/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXSeq INT
SET @MAXSeq=(SELECT ISNULL(MAX(Seq),0) FROM budXRefSMCallTypes) 


/** BACKUP budXRefSMCallTypes TABLE **/
IF OBJECT_ID('budXRefSMCallTypes_bak','U') IS NOT NULL
BEGIN
	DROP TABLE budXRefSMCallTypes_bak
END;
BEGIN
	SELECT * INTO budXRefSMCallTypes_bak FROM budXRefSMCallTypes
END;


/**DELETE DATA IN budXRefSMCallTypes TABLE**/
IF @DeleteDataYN IN('Y','y')
BEGIN
	DELETE budXRefSMCallTypes WHERE SMCo=@Co
END;


/** CHANGE NewYN='N' FOR REFRESH **/
--declare @Co bCompany set @Co=	
UPDATE budXRefSMCallTypes
SET NewYN='N'
WHERE SMCo=@Co AND NewYN='Y'


/** INSERT/UPDATE SM CALL TYPES XREFERENCE TABLE **/
IF OBJECT_ID('budXRefSMCallTypes') IS NOT NULL
BEGIN
	INSERT dbo.budXRefSMCallTypes
		(
				Seq
			   ,OldSMCo
			   ,OldCallType
			   ,OldDescription
			   ,SMCo
			   ,NewCallType
			   ,NewDescription
			   ,ActiveYN
			   ,NewYN
			   --,UniqueAttchID
			   ,Notes
		   )
	--declare @Co bCompany set @Co=	
	SELECT
				Seq=@MAXSeq+ROW_NUMBER () OVER (ORDER BY @Co,xct.OldCallType)
			   ,OldSMCo=@Co
			   ,OldCallType=ct.CALLTYPECODE
			   ,OldDescription=ct.DESCRIPTION
			   ,SMCo=@Co
			   ,NewCallType=ct.CALLTYPECODE--Default
			   ,NewDescription=ct.DESCRIPTION
			   ,ActiveYN=CASE WHEN QINACTIVE='N' THEN 'Y' ELSE 'N' END
			   ,NewYN='Y'
			   --,UniqueAttchID
			   ,Notes=NULL
		
	--declare @Co bCompany set @Co=
	--SELECT *
	FROM CV_TL_Source_SM.dbo.CALLTYPE ct
	LEFT JOIN budXRefSMCallTypes xct
		ON xct.SMCo=@Co AND xct.OldCallType=ct.CALLTYPECODE
	WHERE xct.OldCallType IS NULL
	ORDER BY xct.SMCo, xct.OldCallType;
END;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
SELECT COUNT(*) FROM budXRefSMCallTypes WHERE SMCo=@Co;
SELECT * FROM budXRefSMCallTypes WHERE SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
SELECT * FROM vSMType WHERE SMCo=@Co;
SELECT * FROM CV_TL_Source_SM.dbo.EQPTYPE
**/


GO
