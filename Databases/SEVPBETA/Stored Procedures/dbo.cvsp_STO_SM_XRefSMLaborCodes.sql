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
	Title:	Populate SM Labor Codes (budXRefSMLaborCodes) Cross Reference Table
	Created: 10/16/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 12/04/2012 BBA - Per Meeting with R&D, should be mapped to SM REPAIRS table.

Notes: 

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_XRefSMLaborCodes]
(@Co bCompany, @DeleteDataYN char(1))

AS 

/** DECLARE AND SET PARAMETERS **/
declare @MAXSeq int set @MAXSeq=(select ISNULL(MAX(Seq),0) from budXRefSMLaborCodes) 


/** BACKUP budXRefSMLaborCodes TABLE **/
IF OBJECT_ID('budXRefSMLaborCodes_bak','U') IS NOT NULL
BEGIN
	DROP TABLE budXRefSMLaborCodes_bak
END;
BEGIN
	SELECT * INTO budXRefSMLaborCodes_bak FROM dbo.budXRefSMLaborCodes
END;



/**DELETE DATA IN budXRefSMLaborCodes TABLE**/
if @DeleteDataYN IN('Y','y')
begin
	delete budXRefSMLaborCodes where SMCo=@Co
end;


/** CHANGE NewYN='N' FOR REFRESH **/
update budXRefSMLaborCodes
set NewYN='N'
where SMCo=@Co and NewYN='Y'


/** INSERT/UPDATE SM LABOR CODES XREFERENCE TABLE **/
IF OBJECT_ID('budXRefSMLaborCodes') IS NOT NULL
BEGIN

	/** REPAIR CODES **/
	INSERT dbo.budXRefSMLaborCodes
		(
				Seq
			   ,OldSMCo
			   ,OldLaborCode
			   ,OldDescription
			   ,SMCo
			   ,NewLaborCode
			   ,NewDescription
			   ,JCCostType
			   ,ActiveYN
			   ,NewYN
			   --,UniqueAttchID
			   ,Notes
		   )
	--declare @Co bCompany set @Co=	
	SELECT
				Seq=@MAXSeq+ROW_NUMBER () OVER (ORDER BY @Co,r.REPAIRNBR)
			   ,OldSMCo=@Co
			   ,OldLaborCode=r.REPAIRNBR
			   ,OldDescription=r.DESCRIPTION
			   ,SMCo=@Co
			   ,NewLaborCode=r.REPAIRNBR --Default
			   ,NewDescription=r.DESCRIPTION
			   ,JCCostType=(--Assumption is that these are all Labor. Modify if not.
							select TOP 1 JCCostType 
							from vSMCostType 
							where SMCo=@Co and SMCostTypeCategory='L'
							)
			   ,ActiveYN=case when QINACTIVE='N' then 'Y' else 'N' end
			   ,NewYN='Y'
			   --,UniqueAttchID
			   ,Notes=NULL
		
	--declare @Co bCompany set @Co=
	--SELECT *
	FROM CV_TL_Source_SM.dbo.REPAIRS r
	LEFT JOIN budXRefSMLaborCodes xlc
		ON xlc.SMCo=@Co and xlc.OldLaborCode=r.REPAIRNBR
	WHERE xlc.OldLaborCode IS NULL 
	ORDER BY xlc.SMCo, xlc.OldLaborCode;
END;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from budXRefSMLaborCodes where SMCo=@Co;
select * from budXRefSMLaborCodes where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMLaborCode where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.REPAIRS;
**/


GO
