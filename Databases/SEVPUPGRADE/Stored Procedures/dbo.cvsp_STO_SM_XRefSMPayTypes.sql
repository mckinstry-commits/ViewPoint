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
	Title:	Populate SM Pay Types (budXRefSMPayTypes) Cross Reference Table
	Created: 10/16/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes:

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_XRefSMPayTypes]
(@Co bCompany, @DeleteDataYN char(1))

AS 

/** DECLARE AND SET PARAMETERS **/
declare @MAXSeq int set @MAXSeq=(select ISNULL(MAX(Seq),0) from budXRefSMPayTypes) 


/** BACKUP budXRefSMPayTypes TABLE **/
IF OBJECT_ID('budXRefSMPayTypes_bak','U') IS NOT NULL
BEGIN
	DROP TABLE budXRefSMPayTypes_bak
END;
BEGIN
	SELECT * INTO budXRefSMPayTypes_bak FROM dbo.budXRefSMPayTypes
END;


/**DELETE DATA IN budXRefSMPayTypes TABLE**/
if @DeleteDataYN IN('Y','y')
begin
	delete budXRefSMPayTypes where SMCo=@Co
end;


/** CHANGE NewYN='N' FOR REFRESH **/
update budXRefSMPayTypes
set NewYN='N'
where SMCo=@Co and NewYN='Y'


/** INSERT/UPDATE SM PAY TYPES XREFERENCE TABLE **/
IF OBJECT_ID('budXRefSMPayTypes') IS NOT NULL
BEGIN
	INSERT dbo.budXRefSMPayTypes
		(
				Seq
			   ,OldSMCo
			   ,OldPayType
			   ,OldDescription
			   ,OldEarnCode
			   ,SMCo
			   ,NewPayType
			   ,NewDescription
			   ,NewEarnCode
			   ,ActiveYN
			   ,NewYN
			   --,UniqueAttchID
			   ,Notes
		   )
	--declare @Co bCompany set @Co=	
	SELECT
				Seq=@MAXSeq+ROW_NUMBER () OVER (ORDER BY xpt.SMCo, xpt.OldPayType)
			   ,OldSMCo=@Co
			   ,OldPayType=PAYTYPENBR
			   ,OldDescription=[DESCRIPTION]
			   ,OldEarnCode=PRPAYID
			   ,SMCo=@Co
			   ,NewPayType=PAYTYPENBR --Default
			   ,NewDescription=[DESCRIPTION]
			   ,NewEarnCode=xec.NewEarnCode
			   ,ActiveYN=case when QINACTIVE='N' then 'Y' else 'N' end
			   ,NewYN='Y'
			   --,UniqueAttchID
			   ,Notes=NULL
		
	--declare @Co bCompany set @Co=
	--SELECT *
	FROM CV_TL_Source_SM.dbo.PAYTYPE spt
	LEFT JOIN budXRefPREarnCodes xec
		ON xec.PRCo=@Co and xec.OldEarnCode=spt.PRPAYID
	LEFT JOIN budXRefSMPayTypes xpt
		ON xpt.SMCo=@Co and xpt.OldPayType=spt.PAYTYPENBR
	WHERE xpt.OldPayType IS NULL
	ORDER BY xpt.SMCo, xpt.OldPayType;
END;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from budXRefSMPayTypes where SMCo=@Co;
select * from budXRefSMPayTypes where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMPayType where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.PAYTYPE;
**/


GO
