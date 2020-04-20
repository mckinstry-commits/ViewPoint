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
	Title:	Populate SM Work Scopes (budXRefSMWorkScopes) Cross Reference Table
	Created: 11/26/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes:

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_XRefSMWorkScopes]
(@Co bCompany, @UseScopeDescriptionYN char(1), @DeleteDataYN char(1))

AS 

/** DECLARE AND SET PARAMETERS **/
declare @MAXSeq int set @MAXSeq=(select ISNULL(MAX(Seq),0) from budXRefSMWorkScopes) 


/** BACKUP budXRefSMWorkScopes TABLE **/
IF OBJECT_ID('budXRefSMWorkScopes_bak','U') IS NOT NULL
BEGIN
	DROP TABLE budXRefSMWorkScopes_bak
END;
BEGIN
	SELECT * INTO budXRefSMWorkScopes_bak FROM  dbo.budXRefSMWorkScopes
END;


/**DELETE DATA IN budXRefSMWorkScopes TABLE**/
if @DeleteDataYN IN('Y','y')
begin
	delete budXRefSMWorkScopes where SMCo=@Co
end;


/** CHANGE NewYN='N' FOR REFRESH **/
update budXRefSMWorkScopes
set NewYN='N'
where SMCo=@Co and NewYN='Y'


/** INSERT/UPDATE SM WORK SCOPES XREFERENCE TABLE **/
IF OBJECT_ID('budXRefSMWorkScopes') IS NOT NULL
BEGIN
	INSERT dbo.budXRefSMWorkScopes
		(
				Seq
			   ,OldSMCo
			   ,OldProblemCode
			   ,OldDescription
			   ,SMCo
			   ,NewWorkScope
			   ,NewDescription
			   ,ActiveYN
			   ,NewYN
			   --,UniqueAttchID
			   ,Notes
		   )
	--declare @Co bCompany set @Co=	
	SELECT
				Seq=@MAXSeq+ROW_NUMBER () OVER (ORDER BY xws.SMCo, xws.OldProblemCode)
			   ,OldSMCo=@Co
			   ,OldProblemCode=p.PROBLEMCODE
			   ,OldDescription=p.DESCRIPTION
			   ,SMCo=@Co
			   ,NewWorkScope=
					CASE	
						WHEN @UseScopeDescriptionYN IN('y','Y') THEN
							LEFT(REPLACE(OldDescription,SPACE(1),''),20)
						ELSE CAST(p.PROBLEMCODE AS VARCHAR(20)) 
					END					
			   ,NewDescription=p.DESCRIPTION
			   ,ActiveYN=case when QINACTIVE='N' then 'Y' else 'N' end
			   ,NewYN='Y'
			   --,UniqueAttchID
			   ,Notes=NULL
		
	--declare @Co bCompany set @Co=
	--SELECT *
	FROM CV_TL_Source_SM.dbo.PROBLEMS p
	LEFT JOIN budXRefSMWorkScopes xws
		ON xws.SMCo=@Co and xws.OldProblemCode=p.PROBLEMCODE
	WHERE xws.OldProblemCode IS NULL
	ORDER BY xws.SMCo, xws.OldProblemCode;
END;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from budXRefSMWorkScopes where SMCo=@Co;
select * from budXRefSMWorkScopes where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMWorkScope where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.PROBLEMS;
**/


GO
