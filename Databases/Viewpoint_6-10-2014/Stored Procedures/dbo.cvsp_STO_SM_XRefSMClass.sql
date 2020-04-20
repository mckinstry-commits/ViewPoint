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
	Title:	Populate SM Class (budXRefSMClass) Cross Reference Table
	Created: 10/16/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes:

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_XRefSMClass]
(@Co bCompany, @DeleteDataYN char(1))

AS 

/** DECLARE AND SET PARAMETERS **/
declare @MAXSeq int set @MAXSeq=(select ISNULL(MAX(Seq),0) from budXRefSMClass) 


/** BACKUP budXRefSMClass TABLE **/
IF OBJECT_ID('budXRefSMClass_bak','U') IS NOT NULL
BEGIN
	DROP TABLE budXRefSMClass_bak
END;
BEGIN
	SELECT * INTO budXRefSMClass_bak FROM budXRefSMClass
END;


/**DELETE DATA IN budXRefSMClass TABLE**/
if @DeleteDataYN IN('Y','y')
begin
	delete budXRefSMClass where SMCo=@Co
end;


/** CHANGE NewYN='N' FOR REFRESH **/
update budXRefSMClass
set NewYN='N'
where SMCo=@Co and NewYN='Y'


/** INSERT/UPDATE SM CLASS XREFERENCE TABLE **/
IF OBJECT_ID('budXRefSMClass') IS NOT NULL
BEGIN
	INSERT dbo.budXRefSMClass
		(
				Seq
			   ,OldSMCo
			   ,OldClass
			   ,OldDescription
			   ,SMCo
			   ,NewClass
			   ,NewDescription
			   ,ActiveYN
			   ,NewYN
			   --,UniqueAttchID
			   ,Notes
		   )
	--declare @Co bCompany set @Co=
	SELECT
				Seq=@MAXSeq+ROW_NUMBER () OVER (ORDER BY @Co,eqc.EQPCLASS)
			   ,OldSMCo=@Co
			   ,OldClass=eqc.EQPCLASS
			   ,OldDescription=eqc.DESCRIPTION
			   ,SMCo=@Co
			   ,NewClass=eqc.EQPCLASS --Default
			   ,NewDescription=eqc.DESCRIPTION
			   ,ActiveYN=case when QINACTIVE='N' then 'Y' else 'N' end
			   ,NewYN='Y'
			   --,UniqueAttchID
			   ,Notes=NULL
		
	--declare @Co bCompany set @Co=
	--SELECT *
	FROM CV_TL_Source_SM.dbo.EQPCLASS eqc
	LEFT JOIN budXRefSMClass xsc
		ON xsc.SMCo=@Co and xsc.OldClass=eqc.EQPCLASS
	WHERE xsc.OldClass IS NULL
	ORDER BY xsc.SMCo, xsc.OldClass;
END;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from budXRefSMClass where SMCo=@Co;
select * from budXRefSMClass where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMClass where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.EQPCLASS;
**/


GO
