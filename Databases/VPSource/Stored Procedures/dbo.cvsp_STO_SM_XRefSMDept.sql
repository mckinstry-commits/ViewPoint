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
	Title:	Populate SM Departments (budXRefSMDept) Cross Reference Table
	Created: 10/16/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes:

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_XRefSMDept]
(@Co bCompany, @DeleteDataYN char(1))

AS 


/** DECLARE AND SET PARAMETERS **/
declare @MAXSeq int set @MAXSeq=(select ISNULL(MAX(Seq),0) from budXRefSMDept)


/** BACKUP budXRefSMDept TABLE **/
IF OBJECT_ID('budXRefSMDept_bak','U') IS NOT NULL
BEGIN
	DROP TABLE budXRefSMDept_bak
END;
BEGIN
	SELECT * INTO budXRefSMDept_bak FROM dbo.budXRefSMDept
END;


/**DELETE DATA IN budXRefSMDept TABLE**/
if @DeleteDataYN IN('Y','y')
begin
	delete budXRefSMDept where SMCo=@Co
end;


/** CHANGE NewYN='N' FOR REFRESH **/
update budXRefSMDept
set NewYN='N'
where SMCo=@Co and NewYN='Y'


/** INSERT/UPDATE SM PAY TYPES XREFERENCE TABLE **/
IF OBJECT_ID('budXRefSMDept') IS NOT NULL
BEGIN
	INSERT dbo.budXRefSMDept
		(
				Seq
			   ,OldSMCo
			   ,OldSMDept
			   ,OldDescription
			   ,OldPRDept
			   ,SMCo
			   ,NewSMDept
			   ,NewDescription
			   ,NewPRDept
			   ,ActiveYN
			   ,NewYN
			   --,UniqueAttchID
			   ,Notes
		   )
	--declare @Co bCompany set @Co=	
	SELECT
				Seq=@MAXSeq+ROW_NUMBER () OVER (ORDER BY @Co,xsd.NewSMDept)
			   ,OldSMCo=@Co
			   ,OldSMDept=DEPTNBR
			   ,OldDescription=[DESCRIPTION]
			   ,OldPRDept=PRDEPT
			   ,SMCo=@Co
			   ,NewSMDept=DEPTNBR
			   ,NewDescription=[DESCRIPTION]
			   ,NewPRDept=xpd.NewDepartment
			   ,ActiveYN=case when QINACTIVE='N' then 'Y' else 'N' end
			   ,NewYN='Y'
			   --,UniqueAttchID
			   ,Notes=NULL
		
	--declare @Co bCompany set @Co=
	--SELECT *
	FROM CV_TL_Source_SM.dbo.DEPT d
	LEFT JOIN budXRefSMDept xsd
		ON xsd.SMCo=@Co AND xsd.OldSMDept=d.DEPTNBR
	LEFT JOIN budXRefPRDept xpd
		ON xpd.PRCo=@Co	AND xpd.OldDepartment=d.PRDEPT
	LEFT JOIN vSMDepartment vdt
	ON vdt.SMCo=@Co AND vdt.Department=xsd.NewSMDept
	WHERE xsd.OldSMDept IS NULL
	ORDER BY xsd.SMCo, xsd.NewSMDept;
END;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from budXRefSMDept where SMCo=@Co;
select * from budXRefSMDept where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMDepartment where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.DEPT
**/


GO
