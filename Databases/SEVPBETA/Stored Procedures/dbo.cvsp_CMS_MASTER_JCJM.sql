SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================================
Copyright © 2012 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, modified,
transmitted or executed without written consent from VCS.
=========================================================================================
	Title:		JC Job Master (JCJM)
	Created:	4.2.09
	Created by:	VCS Technical Services - Shayona Roberts
	Revisions:	
		1. JRE 08/07/09 - created proc & @toco, @fromco
		2. CR 3/31/11 -- see notes at bottom for code that can be used for new ud fields
		3. 03/19/2012 BBA - Reviewed hardcoded database name for Viewpoint.dbo so this
			can be run in a copy of Viewpoint. Added missing columns to resolve error:
			The select list for the INSERT statement contains more items than the insert list. 
					
**/

CREATE PROCEDURE [dbo].[cvsp_CMS_MASTER_JCJM] 
(@fromco smallint, @toco smallint, @errmsg varchar(1000) output, @rowcount bigint output) 

as

set @errmsg=''
set @rowcount=0

-- Open Jobs Only or all Jobs
declare @OpenJobsYN varchar(1)
select @OpenJobsYN = ISNULL(b.DefaultString,a.DefaultString)
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='OpenJobYN' and a.TableName='OpenJobs'; 

-- get vendor group from HQCO
declare @VendorGroup smallint, @TaxGroup smallint,@CustGroup smallint
select @VendorGroup=VendorGroup, @CustGroup=CustGroup,@TaxGroup=TaxGroup from bHQCO where HQCo=@toco;

-- get customer defaults
declare @defaultLockPhases varchar(1)
select @defaultLockPhases=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='LockPhases' and a.TableName='bJCJM'; 

declare @defaultPRStateCode varchar(2)
select @defaultPRStateCode=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PRStateCode' and a.TableName='bJCJM'; 

declare @defaultTaxCode varchar(4)
select @defaultTaxCode=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='TaxCode' and a.TableName='bJCJM'; 

declare @defaultInsTemplate tinyint
select @defaultInsTemplate=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='InsTemplate' and a.TableName='bJCJM'; 

declare @defaultLiabTemplate tinyint
select @defaultLiabTemplate=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='LiabTemplate' and a.TableName='bJCJM'; 

declare @defaultAutoGenRFINo varchar(1)
select @defaultAutoGenRFINo=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='AutoGenRFINo' and a.TableName='bJCJM'; 

declare @defaultAutoGenMTGNo varchar(1)
select @defaultAutoGenMTGNo=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='AutoGenMTGNo' and a.TableName='bJCJM'; 

declare @defaultAutoGenPCONo varchar(1)
select @defaultAutoGenPCONo=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='AutoGenPCONo' and a.TableName='bJCJM'; 

declare @defaultUpdateMSActualsYN varchar(1)
select @defaultUpdateMSActualsYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UpdateMSActualsYN' and a.TableName='bJCJM'; 

declare @defaultUpdateAPActualsYN varchar(1)
select @defaultUpdateAPActualsYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UpdateAPActualsYN' and a.TableName='bJCJM'; 

declare @defaultAutoGenSubNo varchar(1)
select @defaultAutoGenSubNo=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='AutoGenSubNo' and a.TableName='bJCJM'; 

declare @defaultHrsPerManDay tinyint
select @defaultHrsPerManDay=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='HrsPerManDay' and a.TableName='bJCJM'; 

declare @defaultWghtAvgOT varchar(1)
select @defaultWghtAvgOT=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='WghtAvgOT' and a.TableName='bJCJM'; 

declare @defaultAutoAddItemYN varchar(1)
select @defaultAutoAddItemYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='AutoAddItemYN' and a.TableName='bJCJM'; 

declare @defaultUpdatePlugs varchar(1)
select @defaultUpdatePlugs=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UpdatePlugs' and a.TableName='bJCJM'; 

declare @defaultBaseTaxOn varchar(1)
select @defaultBaseTaxOn=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='BaseTaxOn' and a.TableName='bJCJM'; 

declare @defaultHaulTaxOpt tinyint
select @defaultHaulTaxOpt=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='HaulTaxOpt' and a.TableName='bJCJM'; 

declare @defaultProjMinPct numeric(8,2)
select @defaultProjMinPct=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ProjMinPct' and a.TableName='bJCJM'; 

declare @defaultMarkUpDiscRate numeric(8,2)
select @defaultMarkUpDiscRate=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='MarkUpDiscRate' and a.TableName='bJCJM';

declare @defaultFixedRateTemp int
select @defaultFixedRateTemp=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='FixedRateTemp' and a.TableName='bJCJM';


--declare variables for use in fuctions
declare @JobFormat varchar(30), @PhaseFormat varchar(30)
Set @JobFormat =  (Select InputMask from vDDDTc where Datatype = 'bJob')
Set @PhaseFormat =  (Select InputMask from vDDDTc where Datatype = 'bPhase');

ALTER Table bJCJM disable trigger all;

-- delete existing trans
alter table bPMMF NOCHECK CONSTRAINT FK_bPMMF_bJCJM;
alter table bPMSL NOCHECK CONSTRAINT FK_bPMSL_bJCJM;
alter table bPMOH NOCHECK CONSTRAINT FK_bPMOH_bJCJM;
alter table bPMOP NOCHECK CONSTRAINT FK_bPMOP_bJCJM;
alter table bPMCD NOCHECK CONSTRAINT FK_bPMCD_bJCJM;
alter table vPMPOCO NOCHECK CONSTRAINT FK_vPMPOCO_bJCJM;
BEGIN tran
delete from bJCJM where JCCo=@toco
	and udConv = 'Y';
COMMIT TRAN;
alter table bPMMF CHECK CONSTRAINT FK_bPMMF_bJCJM;
alter table bPMSL CHECK CONSTRAINT FK_bPMSL_bJCJM;
alter table bPMOH CHECK CONSTRAINT FK_bPMOH_bJCJM;
alter table bPMOP CHECK CONSTRAINT FK_bPMOP_bJCJM;
alter table bPMCD CHECK CONSTRAINT FK_bPMCD_bJCJM;
alter table vPMPOCO CHECK CONSTRAINT FK_vPMPOCO_bJCJM;


-- add new trans
BEGIN TRAN
BEGIN TRY



insert bJCJM (JCCo, Job, Description, Contract, JobStatus, LockPhases, 
	JobPhone, JobFax, MailAddress, MailCity, MailState, MailZip, MailAddress2,
	TaxGroup, MarkUpDiscRate, Certified,
	ProjMinPct, HaulTaxOpt, BaseTaxOn, UpdatePlugs, AutoAddItemYN, WghtAvgOT, HrsPerManDay, AutoGenSubNo,
	UpdateAPActualsYN, UpdateMSActualsYN, AutoGenPCONo, AutoGenMTGNo, AutoGenRFINo, ProjectMgr,
	VendorGroup, TaxCode, InsTemplate, LiabTemplate, PRStateCode, RateTemplate,
	udSource, udConv, udCGCTable, udCGCTableID, udCGCJob)

select 
	 JCCo=@toco
	,Job=dbo.bfMuliPartFormat(ltrim(rtrim(j.JOBNUMBER)) +  ltrim(RTRIM(j.SUBJOBNUMBER)),@JobFormat)
	,Description=rtrim(j.DESC20A)
	,Contract=dbo.bfMuliPartFormat(ltrim(rtrim(j.JOBNUMBER)),@JobFormat)
	,JobStatus=CASE jobs.JOBSTATUS WHEN 0 THEN 1 else 3 end   -- modified, get from custom view
	,LockPhases=@defaultLockPhases
	,JobPhone=case when CONTACTAREAC =0 then
				case when CONTACTPHONE=0 then null 
					else convert(varchar(3),left(CONTACTPHONE,3))+'-'+convert(varchar(4), right(CONTACTPHONE,4)) 
				end
			else 
				convert(varchar(4),CONTACTAREAC)+'-'+ convert(varchar(3),left(CONTACTPHONE,3))
					+'-'+convert(varchar(4), right(CONTACTPHONE,4)) end
	,JobFax=null
	,MailAddress=case when j.ADDRESS25A='' then null else rtrim(j.ADDRESS25A) end
	,MailCity=case when j.CITY18='' then null else rtrim(j.CITY18) end
	,MailState=case when j.STATECODE='' then null else rtrim(j.STATECODE) end
	,MailZip=case when j.ZIPCODE='' then null else rtrim(j.ZIPCODE) end
	,MailAddress2=case when j.ADDRESS25B='' then null else rtrim(j.ADDRESS25B) end
	,TaxGroup=@TaxGroup 
	,MarkupDiscRate=@defaultMarkUpDiscRate
	,Certified=j.CERTIFIEDJOB 
	,ProjMinPct=@defaultProjMinPct
	,@defaultHaulTaxOpt
	,@defaultBaseTaxOn
	,@defaultUpdatePlugs
	,@defaultAutoAddItemYN
	,@defaultWghtAvgOT
	,@defaultHrsPerManDay
	,@defaultAutoGenSubNo
	,@defaultUpdateAPActualsYN
	,@defaultUpdateMSActualsYN
	,@defaultAutoGenPCONo
	,@defaultAutoGenMTGNo
	,@defaultAutoGenRFINo
	,ProjectMgr=case j.PROJMANAGER WHEN 0 then null else convert(nvarchar(max),j.PROJMANAGER) end
	,@VendorGroup
	,@defaultTaxCode  
	,@defaultInsTemplate
	,@defaultLiabTemplate
	,PRStateCode = case when j.STATECODE='' then null else rtrim(j.STATECODE) end
	,RateTemplate=@defaultFixedRateTemp
	,udSource     = 'MASTER_JCJM'
	,udConv       = 'Y'
	,udCGCTable   = 'JCTDSC'
	,udCGCTableID = JCTDSCID
	,udCGCJob     = j.JOBNUMBER
	
--select *
from CV_CMS_SOURCE.dbo.JCTDSC j 

INNER JOIN CV_CMS_SOURCE.dbo.cvspMcKCGCActiveJobsForConversion jobs 
		ON	jobs.COMPANYNUMBER = j.COMPANYNUMBER
		AND jobs.JOBNUMBER     = j.JOBNUMBER
		and jobs.SUBJOBNUMBER  = j.SUBJOBNUMBER

WHERE j.COMPANYNUMBER=@fromco 
--and	ISNULL(JOBSTATUS,0) <> case when @OpenJobsYN = 'Y' then 3 else 99 end

select @rowcount=@@rowcount

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bJCJM enable trigger all;

return @@error

/*

if customer wants ud fields for a Date try using this:

	udStartDate = 
				case when MAX(j.STARTDATE) = 0 then null else 
				CONVERT(SMALLDATETIME,(substring(convert(nvarchar(max),max(j.STARTDATE)),5,2) + '/' +  
				substring(convert(nvarchar(max),max(j.STARTDATE)),7,2) + '/' + 
				substring(convert(nvarchar(max),max(j.STARTDATE)),1,4))) end
				
if you need to join in TaxLimits for States
1.  import the file as a csv
2.  when joining the TaxLimits StateCode will be a varchar but the CMS State Codes will be decimals
		Ex:  join CV_CMS_SOURCE.dbo.TaxLimits x on x.StateCode=convert(varchar(3),j.STIDCODE)
				
*/
GO
