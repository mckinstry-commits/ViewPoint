SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE proc [dbo].[cvsp_CMS_PRTH_Neg] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as

/**
=========================================================================
	Copyright © 2009 Viewpoint Construction Software (VCS) 
	The TSQL code in this procedure may not be reproduced, modified,
	transmitted or executed without written consent from VCS
=========================================================================
	Title:		Negative Earnings (PRTH)
	Created:	06.15.09
	Created by:	CR
	Revisions:	1. 8.10.09 - CR - changed InsState and InsCode, added nolocks,changed PostedDate to use WEEKENDDATE instead of JOURNALDATE.
						2. 8.19.10 - JH - Added TC source as ud field to PRTH 

**/

set @errmsg=''
set @rowcount=0



--Declare Variables for functions
Declare @Job varchar(30)
Set @Job=(Select InputMask from vDDDTc where Datatype='bJob')

--Get Customer Defaults
declare @defaultShift tinyint

select @defaultShift=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Shift' and a.TableName='bPREH';




ALTER Table bPRTH disable trigger all;

-- delete existing trans
--no delete necessary, done in earlier SP

-- add new trans
BEGIN TRAN
BEGIN TRY



insert bPRTH(PRCo, PRGroup,PREndDate,Employee,PaySeq,PostSeq,Type,PostDate, GLCo,
	TaxState,UnempState,InsState,PRDept,Cert,Craft,Class,Shift,EarnCode,
	Hours,Rate,Amt, BatchId, InsCode, udPaidDate, udCMCo, udCMAcct, udCMRef, udTCSource, udSource,udConv
	,udCGCTable,udCGCTableID)

select PRCo=@toco
		, PRGroup=e.PRGroup
		, PREndDate=n.WkEndDate
		, Employee=n.EMPLOYEENUMBER
		, PaySeq=n.PaySeq
		, PostSeq=isnull((select max(PostSeq) 
							from PRTH b 
							where b.PRCo=@toco 
									and b.PREndDate=n.WkEndDate 
								and b.Employee=n.EMPLOYEENUMBER),0) + 
						row_number() over(partition by n.COMPANYNUMBER,n.WkEndDate, n.EMPLOYEENUMBER 
								order by n.COMPANYNUMBER, n.WkEndDate, n.EMPLOYEENUMBER)
		, Type='J'
		, PostDate=substring(convert(nvarchar(max),n.WEEKENDDATE),5,2) + '/' + substring(convert(nvarchar(max),n.WEEKENDDATE),7,2) + '/' + 
					substring(convert(nvarchar(max),n.WEEKENDDATE),1,4)
		, GLCo=@toco
		, TaxState=e.TaxState
		, UnempState=e.UnempState
		, InsState= null  -- might need to be filled in, get from PRTTCH.CHWCST or PREH.InsState
		, PRDept=e.PRDept
		, Cert=e.CertYN
		, Craft=isnull(a.Craft,e.Craft) 
		, Class=isnull(a.Class,e.Class) 
		, Shift=@defaultShift
		, EarnCode= prearn.EarnCode
		, Hours=0
		, Rate=0
		, Amt=(n.DEDUCTIONAMT*-1)
		, BatchId=0
		, InsCode=e.InsCode
		, udPaidDate=substring(convert(nvarchar(max),n.CHECKDATE),5,2) 
				+ '/' + substring(convert(nvarchar(max),n.CHECKDATE),7,2) + '/' 
				+ substring(convert(nvarchar(max),n.CHECKDATE),1,4)
		, udCMCo=g.CMCo
		, udCMAcct=g.CMAcct
		, udCMRef = n.CHECKNUMBER
		, udTCSource='NEG'
		, udSource ='PRTH_Neg'
		, udConv='Y'
		,udCGCTable='PRTMED',udCGCTableID=PRTMEDID
from CV_CMS_SOURCE.dbo.PRTMED n
	join bPREH e with(nolock) on e.PRCo=@toco and n.EMPLOYEENUMBER=e.Employee
	left join bPRGR g on e.PRCo=g.PRCo and e.PRGroup=g.PRGroup
	join Viewpoint.dbo.budxrefPREarn prearn  with(nolock) on prearn.Company=@fromco 
			and convert(varchar(max),n.DEDNUMBER)=prearn.CMSDedCode and prearn.CMSCode='M'
	left join(select COMPANYNUMBER, EMPLOYEENUMBER, EMPLOYEECLASS=max(EMPLOYEECLASS), 
			EMPLTYPE=max(EMPLTYPE), 
			WkEndDate, Craft=max(x.Craft), Class=max(x.Class)
					from CV_CMS_SOURCE.dbo.PRTTCH H
							left join Viewpoint.dbo.budxrefUnion x on x.Company=@fromco 
								and H.UNIONNO=x.CMSUnion and H.EMPLOYEECLASS=x.CMSClass 
								and H.EMPLTYPE=x.CMSType
					where H.COMPANYNUMBER=@fromco
					group by COMPANYNUMBER, EMPLOYEENUMBER, WkEndDate)
					as a 
					on n.COMPANYNUMBER=a.COMPANYNUMBER and n.EMPLOYEENUMBER=a.EMPLOYEENUMBER 
						and n.WkEndDate=a.WkEndDate 

where n.COMPANYNUMBER=@fromco


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bPRTH enable trigger ALL;

return @@error


GO
