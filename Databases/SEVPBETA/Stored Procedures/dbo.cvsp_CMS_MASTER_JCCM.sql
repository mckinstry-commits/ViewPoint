SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_MASTER_JCCM] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		JCCM
	Created:	04.02.09
	Created by:	Andrew Bynum
	Revisions:	1. JRE 08/07/09 - created proc & @toco, @fromco
				2. BTC 05/11/12 - Modified to use JC Dept Cross Reference
				3. BTC 05/13/12 - Modified to pull customer from first ARTCNS record
					rather than just pull min(Customer) from records grouped by JOBNUMBER.
				
**/
set @errmsg=''
set @rowcount=0

-- Open Jobs Only or all Jobs
declare @OpenJobsYN varchar(1)
select @OpenJobsYN = ISNULL(b.DefaultString,a.DefaultString)
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='OpenJobYN' and a.TableName='OpenJobs'; 

-- get vendor group from HQCO
declare @VendorGroup smallint, @TaxGroup smallint,@CustGroup smallint
select @VendorGroup=VendorGroup, @CustGroup=CustGroup, @TaxGroup=TaxGroup from bHQCO where HQCo=@toco

-- get customer defaults
declare @defaultRetainPct numeric(8,2)
select @defaultRetainPct=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='RetainPCT' and a.TableName='bJCCM'; -- shared JCCM & JCCI
	
declare @defaultDepartment varchar(10)
select @defaultDepartment=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Department' and a.TableName='bJCCM'; -- shared JCCM & JCCI

declare @defaultPayTerms varchar(10)
select @defaultPayTerms=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PayTerms' and a.TableName='bJCCM';

declare @defaultTaxInterface varchar(1)
select @defaultTaxInterface=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='TaxInterface' and a.TableName='bJCCM'; -- shared JCCM & JCCI

declare @defaultCompleteYN varchar(1)
select @defaultCompleteYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='CompleteYN' and a.TableName='bJCCM'; -- shared JCCM & JCCI

declare @defaultBillOnCompletionYN varchar(1)
select @defaultBillOnCompletionYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='BillOnCompletionYN' and a.TableName='bJCCM'; -- shared JCCM & JCCI

declare @defaultRoundOpt varchar(1)
select @defaultRoundOpt=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='RoundOpt' and a.TableName='bJCCM'; -- shared JCCM & JCCI

declare @defaultReportRetgItemYN varchar(1)
select @defaultReportRetgItemYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ReportRetgItemYN' and a.TableName='bJCCM'; -- shared JCCM & JCCI

declare @defaultJBLimitOpt varchar(1)
select @defaultJBLimitOpt=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='JBLimitOpt' and a.TableName='bJCCM'; -- shared JCCM & JCCI

declare @defaultUpdateJCCI varchar(1)
select @defaultUpdateJCCI=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UpdateJCCI' and a.TableName='bJCCM'; -- shared JCCM & JCCI

declare @defaultRecType int
select @defaultRecType=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='RecType' and a.TableName='bJCCM';

--declare variables for functions
declare @JobFormat varchar(30), @PhaseFormat varchar(30)
Set @JobFormat =  (Select InputMask from vDDDTc where Datatype = 'bJob')
Set @PhaseFormat =  (Select InputMask from vDDDTc where Datatype = 'bPhase');


-- delete existing trans
alter table bPMOH NOCHECK CONSTRAINT FK_bPMOH_bJCCM;
alter table bPMOP NOCHECK CONSTRAINT FK_bPMOP_bJCCM;
alter table bJCCM disable trigger all;
BEGIN tran
delete from bJCCM where JCCo=@toco
	and udConv='Y';
alter table bPMOP CHECK CONSTRAINT FK_bPMOP_bJCCM;
alter table bPMOH CHECK CONSTRAINT FK_bPMOH_bJCCM;
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY


insert dbo.bJCCM
(JCCo,Contract,Description,Department,ContractStatus,OriginalDays,CurrentDays,StartMonth,MonthClosed,ActualCloseDate,
	CustGroup,Customer,PayTerms,TaxInterface,TaxGroup, TaxCode,RetainagePCT,DefaultBillType,
	OrigContractAmt,ContractAmt,BilledAmt,ReceivedAmt,CurrentRetainAmt,BillOnCompletionYN,
	CompleteYN,RoundOpt,ReportRetgItemYN,JBFlatBillingAmt,JBLimitOpt,UpdateJCCI,RecType,
	BillAddress, BillAddress2, BillCity, BillState, BillZip,udSource,udConv,udCGCTable,udCGCTableID)

select JCCo
	, Contract
	, Description=rtrim(ContractDesc)
	, Department
	, ContractStatus=JobStatus 
	, OriginalDays=0 
	, CurrentDays=0 
	, StartMonth=case when ClosedMth is not null and convert(smalldatetime,ClosedMth)<convert(smalldatetime,StartMth)
		then convert(smalldatetime,ClosedMth) else convert(smalldatetime,StartMth) end
	, MonthClosed=convert(smalldatetime,ClosedMth)
	, ActualCloseDate=convert(smalldatetime,ActualCloseDate)
	, @CustGroup
	, Customer
	, PayTerms=@defaultPayTerms 
	, TaxInterface=@defaultTaxInterface 
	, TaxGroup=@TaxGroup
	, TaxCode 
	, RetainagePCT=@defaultRetainPct 
	, DefaultBillType='B' 
	, OrigContractAmt=0
	, ContractAmt=0
	, BilledAmt=0
	, ReceivedAmt=0
	, CurrentRetainAmt=0
	, BillOnCompletionYN=@defaultBillOnCompletionYN 
	, CompleteYN=@defaultCompleteYN 
	, RoundOpt=@defaultRoundOpt 
	, ReportRetgItemYN=@defaultReportRetgItemYN
	, JBFlatBillingAmt=0 
	, JBLimitOpt=@defaultJBLimitOpt 
	, UpdateJCCI=@defaultUpdateJCCI 
	, RecType=@defaultRecType 
	, BillAddress=case when CMSJobContractItems.Address='' then null else rtrim(CMSJobContractItems.Address) end
	, BillAddress2=case when CMSJobContractItems.Address2='' then null else rtrim(CMSJobContractItems.Address2) end
	, BillCity=case when CMSJobContractItems.City='' then null else rtrim(CMSJobContractItems.City) end
	, BillState=case when CMSJobContractItems.State='' then null else rtrim(CMSJobContractItems.State) end
	, BillZip=case when CMSJobContractItems.Zip='' then null else rtrim(CMSJobContractItems.Zip) end
	, udSource='MASTER_JCCM'
	, udConv='Y'
	,udCGCTable
	,udCGCTableID
from (select JCCo=@toco 
		, Contract=dbo.bfMuliPartFormat(RTRIM(j.JOBNUMBER), @JobFormat) 
		, Customer=min(c.CUSTOMERNUMBER)
		, Department=isnull(min(xd.VPDept), @defaultDepartment)
		, ContractDesc=min(DESC20A) 
		, JobStatus=case when min(jobs.JOBSTATUS)=0 then 1 else 3 end 
		, StartMth=case when min(j.STARTDATE)=0 then '01/01/2009'
		      else (substring(convert(nvarchar(max),min(STARTDATE)),5,2) + '/01/' 
	             + substring(convert(nvarchar(max),min(STARTDATE)),1,4)) end 
		, ClosedMth=case when min(j.CLOSEDDATE)=0 then null 
		      else (substring(convert(nvarchar(max),min(CLOSEDDATE)),5,2) + '/01/' 
	             + substring(convert(nvarchar(max),min(CLOSEDDATE)),1,4)) end 
          , ActualCloseDate= case when min(j.CLOSEDDATE)=0 then null 
		      else (substring(convert(nvarchar(max),min(CLOSEDDATE)),5,2) + '/' +substring(convert(nvarchar(max),min(CLOSEDDATE)),7,2) + '/' +
	             + substring(convert(nvarchar(max),min(CLOSEDDATE)),1,4)) end 
		, TaxCode=min(case when j.STSLSTAXCD is null or j.STSLSTAXCD=0 then null else convert(varchar(10),j.STSLSTAXCD) end)
		, Address=max(j.ADDRESS25A)
		, Address2=max(j.ADDRESS25B)
		, City=max(j.CITY18)
		, State=max(j.STATECODE)
		, Zip=max(j.ZIPCODE)
		,udCGCTable='JCTDSC'
		,udCGCTableID= max(j.JCTDSCID)
FROM CV_CMS_SOURCE.dbo.JCTDSC j with (nolock)

INNER JOIN CV_CMS_SOURCE.dbo.cvspMcKCGCActiveJobsForConversion jobs 
		ON	jobs.COMPANYNUMBER = j.COMPANYNUMBER
		AND jobs.JOBNUMBER     = j.JOBNUMBER
		and jobs.SUBJOBNUMBER  = j.SUBJOBNUMBER
		
LEFT JOIN (select c.COMPANYNUMBER, c.JOBNUMBER, c.SUBJOBNUMBER, c.CUSTOMERNUMBER 
			from CV_CMS_SOURCE.dbo.ARTCNS c
			join (select COMPANYNUMBER, JOBNUMBER, SUBJOBNUMBER, CONTRACTNO, MIN(CUSTOMERNUMBER) as CUSTOMERNUMBER
				from CV_CMS_SOURCE.dbo.ARTCNS 
				where CONTRACTNO=1
				group by COMPANYNUMBER, JOBNUMBER, SUBJOBNUMBER, CONTRACTNO) a
				on a.COMPANYNUMBER=c.COMPANYNUMBER 
				and a.JOBNUMBER=c.JOBNUMBER 
				and a.SUBJOBNUMBER=c.SUBJOBNUMBER 
				and a.CONTRACTNO=c.CONTRACTNO 
				and a.CUSTOMERNUMBER=c.CUSTOMERNUMBER) c
			on j.COMPANYNUMBER=c.COMPANYNUMBER 
			and j.JOBNUMBER=c.JOBNUMBER 
			and j.SUBJOBNUMBER=c.SUBJOBNUMBER
				
LEFT JOIN budxrefJCDept xd
	on xd.Company=j.COMPANYNUMBER 
	and xd.CMSDept=j.DEPARTMENTNO
		
WHERE j.COMPANYNUMBER=@fromco 
	--and ISNULL(JOBSTATUS,0) <> case when @OpenJobsYN = 'Y' then 3 else 99 end
GROUP BY dbo.bfMuliPartFormat(RTRIM(j.JOBNUMBER), @JobFormat)) 
as CMSJobContractItems


select @rowcount=@@rowcount

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bJCCM enable trigger all

return @@error

GO
