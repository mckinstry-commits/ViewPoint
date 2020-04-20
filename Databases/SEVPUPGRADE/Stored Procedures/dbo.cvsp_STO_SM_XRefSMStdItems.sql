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
	Title:	Populate SM Std Items (XRefSMStdItems) Cross Reference Table
	Created: 12/04/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes:

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_XRefSMStdItems]
(@Co bCompany, @DeleteDataYN CHAR(1))

AS 

/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXSeq INT
SET @MAXSeq=(SELECT ISNULL(MAX(Seq),0) FROM budXRefSMStdItems) 


/** BACKUP budXRefSMStdItems TABLE **/
IF OBJECT_ID('budXRefSMStdItems_bak','U') IS NOT NULL
BEGIN
	DROP TABLE budXRefSMStdItems_bak
END;
BEGIN
	SELECT * INTO budXRefSMStdItems_bak FROM budXRefSMStdItems
END;


/**DELETE DATA IN budXRefSMStdItems TABLE**/
IF @DeleteDataYN IN('Y','y')
BEGIN
	DELETE budXRefSMStdItems WHERE SMCo=@Co
END;
IF OBJECT_ID('budXRefSMPayTypes_bak','U') IS NOT NULL


--/** CHANGE NewYN='N' FOR REFRESH **/
--declare @Co bCompany set @Co=	
UPDATE budXRefSMStdItems
SET NewYN='N'
WHERE SMCo=@Co and NewYN='Y'


/** INSERT/UPDATE SM STANDARDS ITEMS XREFERENCE TABLE **/
IF OBJECT_ID('budXRefSMStdItems') IS NOT NULL
BEGIN
	INSERT dbo.budXRefSMStdItems
		(
				Seq
			   ,OldSMCo
			   ,OldStdItem
			   ,OldDescription
			   ,SMCo
			   ,NewStdItem
			   ,NewDescription
			   ,ActiveYN
			   ,NewYN
			   --,UniqueAttchID
			   ,Notes
		   )
	--declare @Co bCompany set @Co=	
	SELECT
				Seq=@MAXSeq+ROW_NUMBER () OVER (ORDER BY xsi.SMCo,mi.MISCITEMNBR)
			   ,OldSMCo=@Co
			   ,OldStdItem=mi.MISCITEMNBR
			   ,OldDescription=mi.DESCRIPTION
			   ,SMCo=@Co
			   ,NewStdItem=mi.MISCITEMNBR--Default
			   ,NewDescription=mi.DESCRIPTION
			   ,ActiveYN=case when QINACTIVE='N' then 'Y' else 'N' end
			   ,NewYN='Y'
			   --,UniqueAttchID
			   ,Notes=NULL
		
	--declare @Co bCompany set @Co=
	--SELECT *
	FROM CV_TL_Source_SM.dbo.MISCITEMS mi
	LEFT JOIN budXRefSMStdItems xsi
		ON xsi.SMCo=@Co AND xsi.OldStdItem=mi.MISCITEMNBR
	WHERE xsi.OldStdItem IS NULL
	ORDER BY xsi.SMCo, mi.MISCITEMNBR;
END;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
SELECT COUNT(*) FROM budXRefSMStdItems WHERE SMCo=@Co;
SELECT * FROM budXRefSMStdItems WHERE SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
SELECT * from vSMStandardItem WHERE SMCo=@Co;
SELECT * from CV_TL_Source_SM.dbo.MISCITEMS;
**/


GO
