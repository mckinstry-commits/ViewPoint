SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================================
Copyright Â© 2013 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================================
	Title:	Populate SM Technician (budXRefSMTechnician) Cross Reference Table
	Created: 02/15/2013
	Created by:	VCS Technical Services
	Revisions:	
		1. 02/26/2013 BBA - Renamed columns for clarity due to having to add New Technician
			column which was needed because some Technician ID's need changed to resolve 
			conflicts.			 
		2. 05/20/13		MTG -	added a cross refernce for budXRefPREmployee so that we make sure the New Technician number matches the employee's PR Employee number
		
Notes:

**/

create PROCEDURE [dbo].[cvsp_STO_SM_XRefSMTechnician]
(@Co bCompany, @DeleteDataYN char(1))

AS 
--declare @Co tinyint select @Co =1

/** DECLARE AND SET PARAMETERS **/
declare @MAXSeq int set @MAXSeq=(select ISNULL(MAX(Seq),0) from budXRefSMTechnician) 


/** BACKUP budXRefSMTechnician TABLE **/
IF OBJECT_ID('budXRefSMTechnician_bak','U') IS NOT NULL
BEGIN
	DROP TABLE budXRefSMTechnician_bak
END;
BEGIN
	SELECT * INTO budXRefSMTechnician_bak FROM dbo.budXRefSMTechnician
END;


/**DELETE DATA IN budXRefSMTechnician TABLE**/
if @DeleteDataYN IN('Y','y')
begin
	delete budXRefSMTechnician where SMCo=@Co
end;


/** CHANGE NewYN='N' FOR REFRESH **/
update budXRefSMTechnician
set NewYN='N'
where SMCo=@Co and NewYN='Y'


/** INSERT/UPDATE SM PAY TYPES XREFERENCE TABLE **/
IF OBJECT_ID('budXRefSMTechnician') IS NOT NULL
BEGIN
	INSERT dbo.budXRefSMTechnician
		(
				Seq
			   ,OldSMCo
			   ,OldTechnician
			   ,OldPREmployee
			   ,SMCo
			   ,NewTechnician
			   ,NewEmployee
			   ,Name
			   ,ActiveYN
			   ,NewYN
			   --,UniqueAttchID
			   ,Notes
		   )
	--DECLARE @Co bCompany SET @Co=
	SELECT
				Seq=@MAXSeq+ROW_NUMBER () OVER (ORDER BY xt.SMCo, xt.OldTechnician)
			   ,OldSMCo=@Co
			   ,OldTechnician=EMPLOYEENBR
			   ,OldPREmployee=PREMPLOYEE
			   ,SMCo=@Co
			   ,NewTechnician=xe.VPEmployee			   
			   ,NewEmployee=xe.VPEmployee
			   ,Name=NAME
			   ,ActiveYN=case when QINACTIVE='N' then 'Y' else 'N' end
			   ,NewYN='Y'
			   --,UniqueAttchID
			   ,Notes=CASE WHEN ISNUMERIC(PREMPLOYEE)=0 THEN PREMPLOYEE ELSE NULL END
		
--DECLARE @Co bCompany SET @Co=
--SELECT *
--SELECT PREMPLOYEE, EMPLOYEENBR, NAME
FROM CV_TL_Source_SM.dbo.EMPLOYEE se
join budXRefPREmployee xe on xe.PRCo = 1 and case when PREMPLOYEE = 'SM 154    ' then 154
													   when PREMPLOYEE = 'WILSON, TO' then 155
													   when ISNUMERIC (rtrim(ltrim(se.PREMPLOYEE))) =1 then cast (rtrim(ltrim(se.PREMPLOYEE)) as bigint)
													   else 0 end = xe.TLEmployee
LEFT JOIN budXRefSMTechnician xt
	ON xt.SMCo=@Co AND se.EMPLOYEENBR=xt.OldTechnician
WHERE xt.OldTechnician IS NULL 
ORDER BY xt.SMCo, xt.OldTechnician;

END;


--/** RECORD COUNT **/
----DECLARE @Co bCompany SET @Co=	
--SELECT COUNT(*) FROM budXRefSMTechnician where SMCo=@Co;
--SELECT * FROM budXRefSMTechnician where SMCo=@Co;


--/** DATA REVIEW 
----DECLARE @Co bCompany SET @Co=	
--select * from CV_TL_Source_SM.dbo.EMPLOYEE;
--**/

GO
