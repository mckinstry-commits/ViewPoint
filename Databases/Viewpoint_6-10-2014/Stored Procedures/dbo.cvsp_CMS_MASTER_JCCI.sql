SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[cvsp_CMS_MASTER_JCCI] 
	( @fromco1	smallint
	, @fromco2	smallint
	, @fromco3	smallint
	, @toco		smallint
	, @errmsg	varchar(1000) output
	, @rowcount bigint output
	) 
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
				6. 10/03/13 BTC - Added JCJobs cross reference
				7. 10/05/13 BTC - Modified to hard code a valid department
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
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='OpenJobYN' and a.TableName='OpenJobs'; 

-- get customer defaults
declare @defaultRetainPct numeric(8,2)
select @defaultRetainPct=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='RetainPCT' and a.TableName='bJCCM'; -- shared JCCM & JCCI
	
declare @defaultDepartment varchar(10)
select @defaultDepartment=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Department' and a.TableName='bJCCM'; -- shared JCCM & JCCI

declare @defaultItem varchar(16)
select @defaultItem=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Item' and a.TableName='bJCCI';

declare @defaultUM varchar(3)
select @defaultUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UM' and a.TableName='bJCCI';

declare @defaultInitSubs varchar(3)
select @defaultInitSubs=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='InitSubs' and a.TableName='bJCCI';

declare @defaultMarkUpRate numeric(8,2)
select @defaultMarkUpRate=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='MarkUpRate' and a.TableName='bJCCI'; 

declare @defaultProjPlug varchar(1)
select @defaultProjPlug=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ProjPlug' and a.TableName='bJCCI';

--declare variables for use in functions
declare @JobFormat varchar(30), @PhaseFormat varchar(30)
Set @JobFormat =  (Select InputMask from vDDDTc where Datatype = 'bJob')
Set @PhaseFormat =  (Select InputMask from vDDDTc where Datatype = 'bPhase');


ALTER Table bJCCI disable trigger all;
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


ALTER Table bJCCI enable trigger all;

--update trans numbers before JCCI insert
--trigger is inserting records into JCID
exec cvsp_CMS_HQTC_JCID_Update  @fromco1, @toco, null, null

-- add new trans
BEGIN TRAN
BEGIN TRY
;with JOBCOSTS as (
select isnull(sum(ACTUALCSTJTD),0) COST
	 , JM.JOBNUMBER
	 , JM.SUBJOBNUMBER
	 , JM.DIVISIONNUMBER
	 , JM.COMPANYNUMBER
  from CV_CMS_SOURCE.dbo.JCTMST JM
 where JM.COSTTYPE not in ('I')
   and (JM.JOBNUMBER between '15000' and '15999'
    or JM.JOBNUMBER between '300000' and '349999'
    or JM.JOBNUMBER between '70000' and '72999'
    or JM.JOBNUMBER between '12000' and '12999'
    or JM.JOBNUMBER between '36000' and '37999'
    or JM.JOBNUMBER between '85000' and '87999'
    or JM.JOBNUMBER between '750000' and '799999'
    or JM.JOBNUMBER between '200000' and '299999'
    or JM.JOBNUMBER between '170000' and '179999'
    or JM.JOBNUMBER between '180000' and '189999'
    or JM.JOBNUMBER between '160000' and '169999'
    or JM.JOBNUMBER between '630000' and '639999'
    or JM.JOBNUMBER between '640000' and '649999'
    or JM.JOBNUMBER between '530000' and '549999')
   and JM.COMPANYNUMBER in (@fromco1,@fromco2,@fromco3)
 group by JM.JOBNUMBER
	 , JM.SUBJOBNUMBER
	 , JM.DIVISIONNUMBER
	 , JM.COMPANYNUMBER)
	 
insert bJCCI 
	( JCCo
	, Contract
	, Item
	, Description
	, Department
	, UM
	, RetainPCT
	, OrigContractAmt
	, OrigContractUnits
	, OrigUnitPrice
	, ContractAmt
	, ContractUnits
	, UnitPrice
	, BilledAmt
	, BilledUnits
	, ReceivedAmt
	, CurrentRetainAmt
	, BillOriginalUnits
	, BillOriginalAmt
	, BillCurrentUnits
	, BillCurrentAmt
	, BillUnitPrice
	, InitSubs
	, MarkUpRate
	, ProjPlug
	, TaxGroup
	, TaxCode
	, BillType
	, StartMonth
	, udSource
	, udConv
	, udCGCTable
	, udCGCTableID
	)

select JCCo
	 , Contract
	 , Item
	 , Description
	 /*********  need xref setup!   */
	 , Department
	 , UM=@defaultUM
	 , RetainPCT=isnull(RetentionPct,0)
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
	 , udCGCTable
	 , udCGCTableID
  from (
	select JCCo				= @toco
		 , Contract			= xj.VPJobExt -- dbo.bfMuliPartFormat(rtrim(j.JOBNUMBER), @JobFormat)
		 , Item				= SPACE(16 - datalength(rtrim(ltrim( row_number() over (Partition  by xj.VPJobExt order by c.CONTRACTNO) )))) 
							+ RTRIM(ltrim(row_number() over (Partition  by xj.VPJobExt order by c.CONTRACTNO))) 
		 , Description		= min(j.DESC20A) 
		 , Department		= min(isnull(dm.Department,case when @toco = 60 then '02820' else '00000' end))
		 , OrigContractAmt	= isnull(MAX(case when JM.JOBNUMBER is not null and isnull(c.CONTRACTAMT3,0) = 0 then JM.COST + case when isnull(j.FEEPCT,0) > 0 then (JM.COST*j.FEEPCT/100) else 0 end else isnull(c.CONTRACTAMT3,0) end),0)
		 , OrigContractUnits= sum(c.ESTQTY)
		 , TaxCode			= null--min(case when j.STSLSTAXCD='' then  null else j.STSLSTAXCD end)
		 , StartMth			= max(JCCM.StartMonth)
		 , udCGCTable		= 'JCTDSC'
		 , udCGCTableID		= max(j.JCTDSCID)
		 , RetentionPct		= MAX(c.RETENTIONPCT)/100 
	  from CV_CMS_SOURCE.dbo.JCTDSC j with (nolock)
 	  JOIN [MCK_MAPPING_DATA ].[dbo].[McKCGCActiveJobsForConversion2] jobs 
		ON jobs.GCONO = j.COMPANYNUMBER
	   AND jobs.GJBNO     = j.JOBNUMBER
	   and jobs.GSJNO  = j.SUBJOBNUMBER
	   and jobs.GDVNO = j.DIVISIONNUMBER
	  join Viewpoint.dbo.budxrefJCJobs xj
		on xj.COMPANYNUMBER = j.COMPANYNUMBER 
	   and xj.DIVISIONNUMBER = j.DIVISIONNUMBER 
	   and xj.JOBNUMBER = j.JOBNUMBER
	   and xj.SUBJOBNUMBER = j.SUBJOBNUMBER
	   and xj.VPJobExt is not null
	  LEFT JOIN CV_CMS_SOURCE.dbo.ARTCNS c with (nolock)
		on j.COMPANYNUMBER    = c.COMPANYNUMBER 
	   and j.JOBNUMBER       = c.JOBNUMBER 
	   and j.SUBJOBNUMBER    = c.SUBJOBNUMBER
	   and j.DIVISIONNUMBER  = c.DIVISIONNUMBER	
	  JOIN bJCCM JCCM on JCCM.JCCo=@toco 
	   and JCCM.Contract  =  xj.VPJobExt --dbo.bfMuliPartFormat(rtrim(j.JOBNUMBER), @JobFormat)
	  LEFT JOIN Viewpoint.dbo.budxrefJCDept x 
		on x.Company  = @toco
	   and x.CMSDept = j.DEPARTMENTNO 
	  LEFT JOIN Viewpoint.dbo.bJCDM dm
	    on dm.JCCo = x.VPCo
	   and dm.Department = x.VPDept
	  LEFT JOIN JOBCOSTS JM
	    on xj.COMPANYNUMBER = JM.COMPANYNUMBER
	   and xj.DIVISIONNUMBER = JM.DIVISIONNUMBER
	   and xj.SUBJOBNUMBER = JM.SUBJOBNUMBER
	   and xj.JOBNUMBER = JM.JOBNUMBER
	 WHERE j.COMPANYNUMBER in (@fromco1,@fromco2,@fromco3)
	 GROUP BY xj.VPJobExt, c.CONTRACTNO -- dbo.bfMuliPartFormat(rtrim(j.JOBNUMBER), @JobFormat),
	--c.COMPANYNUMBER, c.DIVISIONNUMBER, /*CUSTOMERNUMBER,*/ c.JOBNUMBER, c.SUBJOBNUMBER, c.CONTRACTNO
				
		    -- , case 
			   --when isnull(c.ITEMNUMBER, ' ') = ' '
			   --then @defaultItem
			   --else space(16-datalength(rtrim(c.ITEMNUMBER))) + rtrim(c.ITEMNUMBER)
			   --end
			 ) 
			 
	as CMSJobContractItems;

		
select @rowcount=@@rowcount

--Updates JCCM to reflect the department on the items.
alter table bJCCM disable trigger all
--decalare @toco int = 20
	update bJCCM 
	   set Department=JCCI.Department
	  from bJCCM
	  left join (select JCCo, Contract, Department=min(Department)
				   from bJCCI
				  group by JCCo, Contract) as JCCI
		on bJCCM.JCCo=JCCI.JCCo 
	   and bJCCM.Contract=JCCI.Contract
	where bJCCM.JCCo=@toco
	  and bJCCM.Department<>JCCI.Department
	  
alter table bJCCM enable trigger all

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
