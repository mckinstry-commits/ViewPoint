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
	Title:	Populate SM Rate Template (budXRefSMRateTemplate) Cross Reference Table
	Created: 12/07/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes:

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_XRefSMRateTemplate]
(@Co bCompany, @DeleteDataYN char(1))

AS 

/** DECLARE AND SET PARAMETERS **/
declare @MAXSeq int set @MAXSeq=(select ISNULL(MAX(Seq),0) from budXRefSMRateTemplate) 


/** BACKUP budXRefSMRateTemplate TABLE **/
IF OBJECT_ID('budXRefSMRateTemplate_bak','U') IS NOT NULL
BEGIN
	DROP TABLE budXRefSMRateTemplate_bak
END;
BEGIN
	SELECT * INTO budXRefSMRateTemplate_bak FROM budXRefSMRateTemplate
END;


/**DELETE DATA IN budXRefSMRateTemplate TABLE**/
IF @DeleteDataYN IN('Y','y')
BEGIN
	DELETE budXRefSMRateTemplate WHERE SMCo=@Co
END;


/** CHANGE NewYN='N' FOR REFRESH **/
UPDATE budXRefSMRateTemplate
SET NewYN='N'
WHERE SMCo=@Co and NewYN='Y'


/** INSERT/UPDATE SM RateTemplate XREFERENCE TABLE **/
IF OBJECT_ID('budXRefSMRateTemplate') IS NOT NULL
BEGIN
	INSERT dbo.budXRefSMRateTemplate
		(
				Seq
			   ,OldSMCo
			   ,OldRateTemplate
			   ,OldDescription
			   ,OldLaborRate
			   ,SMCo
			   ,NewRateTemplate
			   ,NewDescription
			   ,ActiveYN
			   ,NewYN
			   --,UniqueAttchID
			   ,Notes
		   )
	--declare @Co bCompany set @Co=	
	SELECT
				Seq=@MAXSeq+ROW_NUMBER () OVER (ORDER BY @Co,rs.RATESHEETNBR)
			   ,OldSMCo=@Co
			   ,OldRateTemplate=rs.RATESHEETNBR
			   ,OldDescription=rs.DESCRIPTION
			   ,OldLaborRate=rs.LABORRATE
			   ,SMCo=@Co
			   ,NewRateTemplate=rs.RATESHEETNBR --Default
			   ,NewDescription=rs.DESCRIPTION
			   ,ActiveYN=case when QINACTIVE='N' then 'Y' else 'N' end
			   ,NewYN='Y'
			   --,UniqueAttchID
			   ,Notes=NULL
		
	--declare @Co bCompany set @Co=
	--SELECT *
	FROM CV_TL_Source_SM.dbo.RATESHEET rs
	LEFT JOIN budXRefSMRateTemplate xrs
		ON xrs.SMCo=@Co AND xrs.OldRateTemplate=rs.RATESHEETNBR
	WHERE xrs.OldRateTemplate IS NULL
	ORDER BY xrs.SMCo, rs.RATESHEETNBR;
END;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from budXRefSMRateTemplate where SMCo=@Co;
select * from budXRefSMRateTemplate where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMRateTemplate where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.RATESHEET;
**/


GO
