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
	Title:	Populate SM Types (budXRefSMTypes) Cross Reference Table
	Created: 10/16/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes:

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_XRefSMTypes]
(@Co bCompany, @DeleteDataYN char(1))

AS 

/** DECLARE AND SET PARAMETERS **/
declare @MAXSeq int set @MAXSeq=(select ISNULL(MAX(Seq),0) from budXRefSMTypes) 

/** BACKUP budXRefSMTypes TABLE **/
if OBJECT_ID('budXRefSMTypes_bak','U') IS NOT NULL 
drop table budXRefSMTypes_bak
begin
	select * into budXRefSMTypes_bak from dbo.budXRefSMTypes
end;


/**DELETE DATA IN budXRefSMTypes TABLE**/
if @DeleteDataYN IN('Y','y')
begin
	delete budXRefSMTypes where SMCo=@Co
end;


/** CHANGE NewYN='N' FOR REFRESH **/
update budXRefSMTypes
set NewYN='N'
where SMCo=@Co and NewYN='Y'


/** INSERT/UPDATE SM TYPES XREFERENCE TABLE **/
IF OBJECT_ID('budXRefSMTypes') IS NOT NULL
BEGIN
	INSERT dbo.budXRefSMTypes
		(
				Seq
			   ,OldSMCo
			   ,OldType
			   ,OldDescription
			   ,OldClass
			   ,SMCo
			   ,NewType
			   ,NewDescription
			   ,NewClass
			   ,ActiveYN
			   ,NewYN
			   --,UniqueAttchID
			   ,Notes
		   )
	--declare @Co bCompany set @Co=1	
	SELECT
				Seq=@MAXSeq+ROW_NUMBER () OVER (ORDER BY @Co,eqt.EQPTYPE)
			   ,OldSMCo=@Co
			   ,OldType=eqt.EQPTYPE
			   ,OldDescription=eqt.DESCRIPTION
			   ,OldClass=eqt.EQPCLASS
			   ,SMCo=@Co
			   ,NewType=eqt.EQPTYPE --Default
			   ,NewDescription=eqt.DESCRIPTION
			   ,NewClass=xsc.NewClass
			   ,ActiveYN=case when QINACTIVE='N' then 'Y' else 'N' end
			   ,NewYN='Y'
			   --,UniqueAttchID
			   ,Notes=NULL
		
	--declare @Co bCompany set @Co=1
	--SELECT *
	FROM CV_TL_Source_SM.dbo.EQPTYPE eqt
	INNER JOIN budXRefSMClass xsc
		ON xsc.SMCo=@Co and xsc.OldClass=eqt.EQPCLASS	
	LEFT JOIN budXRefSMTypes xt
		ON xt.SMCo=@Co and xt.OldType=eqt.EQPTYPE
	WHERE xt.OldType IS NULL
	ORDER BY xt.SMCo, xt.OldType;
END;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from budXRefSMTypes where SMCo=@Co;
select * from budXRefSMTypes where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMType where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.EQPTYPE
**/


GO
