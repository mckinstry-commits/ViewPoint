SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_MASTER_PRED](@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Employee Deductions (PRED)
	Created:	04.15.09
	Created by: CR      
	Revisions:	1. None
**/


set @errmsg=''
set @rowcount=0

--get Customer Defaults
declare @defaultEmplBased varchar(1), @defaultFrequency varchar(1), @defaultProcess tinyint;

select @defaultEmplBased=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='EmplBased' and a.TableName='bPRED';

select @defaultFrequency=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Frequency' and a.TableName='bPRED';

select @defaultProcess=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ProcessSeq' and a.TableName='bPRED';



-- delete existing trans
BEGIN tran
delete from bPRED where PRCo=@toco
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY

ALTER Table bPRED disable trigger btPREDi;

insert into bPRED
	(DLCode, PRCo, Employee, EmplBased, Frequency, ProcessSeq, 
		FileStatus, RegExempts, OverMiscAmt, MiscAmt, 
		GLCo, OverCalcs, RateAmt, OverLimit, Limit, NetPayOpt, 
		MinNetPay, AddonType, AddonRateAmt, udSource,udConv,udCGCTable,udCGCTableID)


--Fed WithHolding
select DLCode = x.DLCode
	, PRCo = @toco
	, Employee = EMPLOYEENUMBER
	, EmplBased = @defaultEmplBased
	, Frequency = null
	, ProcessSeq = null
	, FileStatus = MTXST 
	, RegExempts = case when FEDEXEMPCODE = 'N' then 0 else FEDEXEMPTIONS end
	, OverMiscAmt = 'N' 
	, MiscAmt = 0 
	, GLCo = @toco
	, OverCalcs = case when FEDEXEMPCODE = 'N' then 
						case when MXFTP <> 0 then 'R' 
							when MXFTD <> 0 then 'A' 
						else 'N' end 
					else 'N' end
	, RateAmt = case when FEDEXEMPCODE='N' then 
						case when MXFTP<>0 then MXFTP/100 
							when MXFTD <> 0 then MXFTD end 
				else 0 end
	, OverLimit='N'
	, Limit=0
	, NetPayOpt='N'
	, MinNetPay=null
	, ADDONTYPE = case when FEDEXEMPCODE = 'Y' then 
					case when MXFTD <> 0 then 'A'  
						when MXFTP <> 0 then 'R' 
					else 'N' end 
				else 'N' end
	, ADDONRATEAMT = case when FEDEXEMPCODE = 'Y' then 
						case when MXFTD <> 0 then MXFTD  
							when MXFTP <> 0 then MXFTP/100 
						else 0 end 
					else 0 end
	, udSource = 'MASTER_PRED'
	, udConv='Y'
	,udCGCTable='PRTMST'
	,udCGCTableID PRTMSTID
	
from CV_CMS_SOURCE.dbo.PRTMST
	join Viewpoint.dbo.budxrefPRDedLiab x on x.Company=@fromco
	join bPRDL d on d.PRCo=@toco and x.DLCode=d.DLCode
	join bPRFI f on d.PRCo=f.PRCo and d.DLCode=f.TaxDedn
	join bPREH h on h.PRCo=@toco and CV_CMS_SOURCE.dbo.PRTMST.EMPLOYEENUMBER=h.Employee
where CV_CMS_SOURCE.dbo.PRTMST.COMPANYNUMBER=@fromco
and h.ActiveYN='Y'


union all

--state withholding codes 
select DLCode = max(x.DLCode)
	, PRCo=@toco
	, Employee=L.EMPLOYEENUMBER
	, EmplBased=@defaultEmplBased
	, Frequency=null
	, ProcessSeq=null--@defaultProcess
	, FileStatus=Max(L.TAXSTATUS)
	, RegExempts=Max(L.EXEMPTWITHHELD)
	, OverMiscAmt='N'
	, MiscAmt=0
	, GLCo=@toco
	, OverCalcs='N'
	, RateAmt=0
	, OverLimit='N'
	, Limit=0
	, NetPayOut='N'
	, MinNetPay=null
	, AddOnType='N'
	, AddOnRateAmt=0
	, udSource = 'MASTER_PRED'
	, udConv='Y'
	,udCGCTable='PRTSTL'
	,udCGCTableID=max(PRTSTLID)
from CV_CMS_SOURCE.dbo.PRTSTL L
	join Viewpoint.dbo.budxrefPRDedLiab x on x.Company=@fromco and L.DISTNUMBER=x.CMSDedCode
		and x.VPType='D'
	join bPRSI i on i.PRCo=@toco and x.DLCode=i.TaxDedn
	join bPREH h on h.PRCo=@toco and L.EMPLOYEENUMBER=h.Employee
where x.VPType = 'D'    
	and L.STATUSCODE = 'A'
	and L.COMPANYNUMBER=@fromco
	and h.ActiveYN='Y'
group by L.COMPANYNUMBER, L.EMPLOYEENUMBER, L.DISTNUMBER


union all


-- Local and School Taxes 
--  Usually Employee Based!! 
select DLCode = max(x.DLCode)
	,PRCo=@toco
	,Employee = L.EMPLOYEENUMBER
	,EmplBased = @defaultEmplBased
	,Frequency = null
	,ProcessSeq = null
	,FileStatus = null
	,RegExempts = null
	,OverMiscAmt = 'N'
	,MiscAmt = 0
	,GLCo = @toco
	,OverCalcs =  'N'
	,RateAmt = 0
	,OverLimit = 'N'
	,Limit = 0
	,NetPayOut = 'N'
	,MinNetPay = null
	,AddOnType = 'N'
	,AddOnRateAmt = 0
	,udSource = 'MASTER_PRED'
	, udConv='Y'
	,udCGCTable='PRTSTL'
	,udCGCTableID=max(PRTSTLID)
from CV_CMS_SOURCE.dbo.PRTSTL L
	join Viewpoint.dbo.budxrefPRDedLiab x on x.Company=@fromco and L.DISTNUMBER=x.CMSDedCode
		and x.VPType='D'
	join bPRLI i on i.PRCo=@toco and x.DLCode=i.TaxDedn
	join bPREH h on h.PRCo=@toco and L.EMPLOYEENUMBER=h.Employee
where x.CMSDedType = 'L' 
	and x.VPType='D'    
	and L.STATUSCODE = 'A'
	and L.COMPANYNUMBER=@fromco
	and h.ActiveYN='Y'
	/*and D.DDEFQ<>0*/  -- most customer use zero as a frequency code for ded codes that don't exist.
group by L.COMPANYNUMBER, L.EMPLOYEENUMBER, L.DISTNUMBER



union all


--Other Deductions 
select DLCode = max(x.DLCode)
	, PRCo = @toco
	, Employee = D.DEENO
	, EmplBased = 'Y'
	, Frequency = @defaultFrequency
	, ProcessSeq = @defaultProcess
	, FileStatus = null
	, RegExempts = null
	, OverMiscAmt = 'N'
	, MiscAmt = 0
	, GLCo=@toco
	, OverCalcs=case when max(D.DAMDE)<> 0 then 'A' else'R' end
	, RateAmt=case when max(D.DAMDE)<> 0 then max(D.DAMDE) 
					when max(D.DAMDE) = 0 and max(DDEFQ) = 7 then 1
					else (max(D.DDEPC)/100) end
	, OverLimit=case when max(D.DDELM) <> 0 then 'Y' else 'N' end
	, Limit=max(D.DDELM)
	, NetPayOut = 'N'
	, MinNetPay = null
	, AddOnType = 'N'
	, AddOnRateAmt = 0
	, udSource = 'MASTER_PRED'
	, udConv='Y'
	,udCGCTable='PRPDED'
	,udCGCTableID =null
from CV_CMS_SOURCE.dbo.PRPDED D
	join Viewpoint.dbo.budxrefPRDedLiab x on x.Company=@fromco and D.DDENO=x.CMSDedCode
		and x.VPType='D'
	join bPREH h on h.PRCo=@toco and D.DEENO=h.Employee
	join (select DCONO, DEENO, DDENO, DDTCM=max(DDTCM)
			from CV_CMS_SOURCE.dbo.PRPDED
			group by DCONO, DEENO, DDENO) 
			as DED 
			on D.DCONO=DED.DCONO 
				and D.DEENO=DED.DEENO 
				and D.DDENO=DED.DDENO 
				and D.DDTCM=DED.DDTCM
where D.DDENO not in (998,999) 
	and x.CMSDedType='M' 
	and x.VPType = 'D' 
	and D.DCONO=@fromco   
	and (D.DAMDE<>0 or D.DDEPC<>0)
	and h.ActiveYN='Y'
group by D.DCONO, D.DEENO, D.DDENO, DED.DDTCM






COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bPRED enable trigger all;

return @@error





GO
