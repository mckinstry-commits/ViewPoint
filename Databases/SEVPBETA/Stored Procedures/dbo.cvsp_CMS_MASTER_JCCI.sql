SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_MASTER_JCCI] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, modified,
transmitted or executed without written consent from VCS.
=========================================================================
	Title:		JCCI Contract Items 
	Created:	12.1.08
	Created by:	Shayona Roberts
	Revisions:	1. 02.20.09 - A. Bynum - No edit or variables needed for CMS; all field issues are addressed in CMSJobContractItems.
				2. 3.9.09 - @Job &amp; @Phase variables added to pull formats from vDDDTc table.
			    3. 7.9.09 JRE - added defaults
			    4. 11.18.09 CR - added Open Jobs functionality
				5. 06.11.10 - JH - Added update back to JCCM to make JCCM department match item department
					The JCCM script defaults in a department of 1.
**/


set @errmsg=''
set @rowcount=0

-- get vendor group from HQCO
declare @VendorGroup smallint, @TaxGroup smallint,@CustGroup smallint
select @VendorGroup=VendorGroup, @CustGroup=CustGroup,@TaxGroup=TaxGroup from bHQCO where HQCo=@toco

-- Open Jobs Only or all Jobs
declare @OpenJobsYN varchar(1)
select @OpenJobsYN = ISNULL(b.DefaultString,a.DefaultString)
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='OpenJobYN' and a.TableName='OpenJobs'; 

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

declare @defaultItem varchar(16)
select @defaultItem=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Item' and a.TableName='bJCCI';

declare @defaultUM varchar(3)
select @defaultUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UM' and a.TableName='bJCCI';

declare @defaultInitSubs varchar(3)
select @defaultInitSubs=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='InitSubs' and a.TableName='bJCCI';

declare @defaultMarkUpRate numeric(8,2)
select @defaultMarkUpRate=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='MarkUpRate' and a.TableName='bJCCI'; 

declare @defaultProjPlug varchar(1)
select @defaultProjPlug=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ProjPlug' and a.TableName='bJCCI';

--declare variables for use in functions
declare @JobFormat varchar(30), @PhaseFormat varchar(30)
Set @JobFormat =  (Select InputMask from vDDDTc where Datatype = 'bJob')
Set @PhaseFormat =  (Select InputMask from vDDDTc where Datatype = 'bPhase');


ALTER Table bJCCI disable trigger btJCCId;
ALTER Table bJCID disable trigger all;

alter table bPMOI NOCHECK CONSTRAINT FK_bPMOI_bJCCI;
-- delete existing trans
BEGIN tran
delete from bJCCI where JCCo=@toco
	and udConv='Y';
delete bJCID where JCCo=@toco and JCTransType='OC'
	and udConv='Y';
alter table bPMOI CHECK CONSTRAINT FK_bPMOI_bJCCI;

COMMIT TRAN;


ALTER Table bJCCI enable trigger btJCCId;
ALTER Table bJCID disable trigger all;

--update trans numbers before JCCI insert
--trigger is inserting records into JCID
exec cvsp_CMS_HQTC_JCID_Update  @fromco, @toco, null, null

-- add new trans
BEGIN TRAN
BEGIN TRY

insert bJCCI (JCCo, Contract, Item, Description, Department, UM, RetainPCT, OrigContractAmt, OrigContractUnits,
	OrigUnitPrice, ContractAmt, ContractUnits, UnitPrice, BilledAmt, BilledUnits, ReceivedAmt,
	CurrentRetainAmt, BillOriginalUnits, BillOriginalAmt, BillCurrentUnits, BillCurrentAmt,
	BillUnitPrice, InitSubs, MarkUpRate, ProjPlug, TaxGroup, TaxCode, BillType, StartMonth, udSource,udConv
	,udCGCTable,udCGCTableID)

select JCCo
	, Contract
	, Item
	, Description
	/*********  need xref setup!   */
	, Department='0120'--case when Department is null then @defaultDepartment else Department end
	, UM=@defaultUM
	, RetainPCT=@defaultRetainPct
	, OrigContractAmt=isnull(OrigContractAmt,0)
	, OrigContractUnits=isnull(OrigContractUnits,0)
	, OrigUnitPrice=0 
	, ContractAmt=isnull(OrigContractAmt,0)
	, ContractUnits=isnull(OrigContractUnits,0) 
	, UnitPrice=0
	, BilledAmt=0
	, BilledUnits=0
	, ReceivedAmt=0
	, CurrentRetainAmt=0
	, BillOriginalUnits=0
	, BillOriginalAmt=0
	, BillCurrentUnits=0
	, BillCurrentAmt=0
	, BillUnitPrice=0
	, InitSubs=@defaultInitSubs
	, MarkUpRate=@defaultMarkUpRate
	, ProjPlug=@defaultProjPlug
	, TaxGroup=@TaxGroup
	, TaxCode
	, BillType='B' 
	, StartMonth=StartMth
	, udSource = 'MASTER_JCCI'
	, udConv='Y'
	,udCGCTable
	,udCGCTableID
from 
	(select JCCo   = @toco
		, Contract = dbo.bfMuliPartFormat(rtrim(j.JOBNUMBER), @JobFormat)
		, Item     =  SPACE(16 - datalength(rtrim(ltrim( 
				row_number() over 
				(Partition  by c.COMPANYNUMBER, c.DIVISIONNUMBER, c.JOBNUMBER, c.SUBJOBNUMBER
				order by c.COMPANYNUMBER, c.DIVISIONNUMBER, /*c.CUSTOMERNUMBER,*/ c.JOBNUMBER, c.SUBJOBNUMBER, c.CONTRACTNO)
				)))) + RTRIM(ltrim(row_number() over 
				(Partition  by c.COMPANYNUMBER, c.DIVISIONNUMBER, c.JOBNUMBER, c.SUBJOBNUMBER
				order by c.COMPANYNUMBER, c.DIVISIONNUMBER, /*c.CUSTOMERNUMBER,*/ c.JOBNUMBER, c.SUBJOBNUMBER, c.CONTRACTNO)))
				/*case 
			   when isnull(c.ITEMNUMBER, ' ') = ' '
			   then @defaultItem
			   else space(16-datalength(rtrim(c.ITEMNUMBER))) + rtrim(c.ITEMNUMBER)
			   end*/
		, Description=min(j.DESC20A) 
		, Department=min(case 
						when x.VPDept is null 
						then j.DEPARTMENTNO 
						else x.VPDept 
						end)
		, OrigContractAmt=sum(c.CONTRACTAMT3)
		, OrigContractUnits=sum(c.ESTQTY)
		, TaxCode=null--min(case when j.STSLSTAXCD='' then  null else j.STSLSTAXCD end)
		, StartMth=max(JCCM.StartMonth)
		, udCGCTable='JCTDSC'
		, udCGCTableID=max(j.JCTDSCID)
		
	from CV_CMS_SOURCE.dbo.JCTDSC j with (nolock)
	
	INNER JOIN CV_CMS_SOURCE.dbo.cvspMcKCGCActiveJobsForConversion jobs 
		ON	jobs.COMPANYNUMBER = j.COMPANYNUMBER
		AND jobs.JOBNUMBER     = j.JOBNUMBER
		and jobs.SUBJOBNUMBER  = j.SUBJOBNUMBER
		
	LEFT JOIN CV_CMS_SOURCE.dbo.ARTCNS c with (nolock)
		on j.COMPANYNUMBER    = c.COMPANYNUMBER 
		and j.JOBNUMBER       = c.JOBNUMBER 
		and j.SUBJOBNUMBER    = c.SUBJOBNUMBER
				
	JOIN bJCCM JCCM on JCCM.JCCo=@toco 
		and JCCM.Contract  =  dbo.bfMuliPartFormat(rtrim(j.JOBNUMBER), @JobFormat)
		
	LEFT JOIN Viewpoint.dbo.budxrefJCDept x 
		on x.Company  = @fromco
		and x.CMSDept = j.DEPARTMENTNO 
		
	WHERE j.COMPANYNUMBER=@fromco 
	
		
	GROUP BY dbo.bfMuliPartFormat(rtrim(j.JOBNUMBER), @JobFormat),
	c.COMPANYNUMBER, c.DIVISIONNUMBER, /*CUSTOMERNUMBER,*/ c.JOBNUMBER, c.SUBJOBNUMBER, c.CONTRACTNO
				
		    -- , case 
			   --when isnull(c.ITEMNUMBER, ' ') = ' '
			   --then @defaultItem
			   --else space(16-datalength(rtrim(c.ITEMNUMBER))) + rtrim(c.ITEMNUMBER)
			   --end
			 ) 
			 
	as CMSJobContractItems;

		
select @rowcount=@@rowcount

--Updates JCCM to reflect the department on the items.
update bJCCM 
set Department=JCCI.Department
from bJCCM
	left join (select JCCo, Contract, Department=min(Department)
				from bJCCI
				group by JCCo, Contract)
				as JCCI
				on bJCCM.JCCo=JCCI.JCCo 
				and bJCCM.Contract=JCCI.Contract
				
where bJCCM.JCCo=@toco
and bJCCM.Department<>JCCI.Department

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bJCCI enable trigger all;
ALTER Table bJCID enable trigger all;

return @@error

GO
