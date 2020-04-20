
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_MASTER_JCCH] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
	Copyright © 2009 Viewpoint Construction Software (VCS) 
	The TSQL code in this procedure may not be reproduced, modified,
	transmitted or executed without written consent from VCS

=========================================================================
	Title:		JC Original Job Estimates (JCCH)
	Created:	03.30.09
	Created by:	Andrew Bynum
	Purpose:	Populates JC Phase Master table using JCPCCS CMS table.
	Revisions:	1. JRE 08/07/09 - created proc & @toco, @fromco
				2. 10/15/09 - Entered defaults into Customer defaults and switched to use variables here. - JH
				3. 10/04/13 - Added JCJobs cross reference - BTC
**/

set @errmsg=''
set @rowcount=0

-- get vendor group from HQCO
declare @PhaseGroup smallint
select @PhaseGroup=PhaseGroup from bHQCO where HQCo=@toco;



--get customer defaults
declare @BillFlag char(1), @ItemUnitFlag char(1), @PhaseUnitFlag char(1), 
	@BuyOutYN char(1), @Plugged char(1), @ActiveYN char(1), @SourceStatus char(1),
	@DefaultUM char(3), @DefaultUMUnits char(3), @OpenJobsYN varchar(1)

select @BillFlag=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='BillFlag' and a.TableName='bJCCH';

select @ItemUnitFlag=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ItemUnitFlag' and a.TableName='bJCCH';

select @PhaseUnitFlag=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PhaseUnitFlag' and a.TableName='bJCCH';

select @BuyOutYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='BuyOutYN' and a.TableName='bJCCH';

select @Plugged=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Plugged' and a.TableName='bJCCH';

select @ActiveYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ActiveYN' and a.TableName='bJCCH';

select @SourceStatus=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='SourceStatus' and a.TableName='bJCCH';

select @DefaultUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DefaultUM' and a.TableName='bJCCH';

select @DefaultUMUnits=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DefaultUMUnits' and a.TableName='bJCCH';

select @OpenJobsYN = ISNULL(b.DefaultString,a.DefaultString)
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='OpenJobYN' and a.TableName='OpenJobs'; 

--declare variables for functions
declare @JobFormat varchar(30)
Set @JobFormat =  (Select InputMask from vDDDTc where Datatype = 'bJob');

-- Job formatting
--declare @JobLen smallint, @SubJobLen smallint
--select @JobLen = left(InputMask,1) from vDDDTc where Datatype = 'bJob';
--select @SubJobLen = substring(InputMask,4,1) from vDDDTc where Datatype = 'bJob';


ALTER Table bJCCH disable trigger all;

-- delete existing trans
BEGIN tran
delete from bJCCH where JCCo=@toco
	and udConv='Y';
COMMIT TRAN;


-- add new trans
BEGIN TRAN
BEGIN TRY

insert into bJCCH (JCCo, Job, PhaseGroup,Phase, CostType,UM,BillFlag,ItemUnitFlag,PhaseUnitFlag, 
	BuyOutYN,Plugged,ActiveYN,OrigHours,OrigUnits,OrigCost,SourceStatus,udSource,udConv,udCGCTable,udCGCTableID)

select JCCHInfo.JCCo
	, JCCHInfo.Job
	, PhaseGroup
	, Phase
	, CostType
	, UM=MAX(UM)
	, @BillFlag
	, @ItemUnitFlag
	, @PhaseUnitFlag
	, @BuyOutYN
	, @Plugged
	, max(m.JobStatus)
	, OrigHours=sum(OrigHours)
	, OrigUnits=sum(OrigUnits)
	, OrigCost=sum(OrigCost)
	, SourceStatus=@SourceStatus
	, udSource ='MASTER_JCCH'
	, udConv='Y'
	, max(JCCHInfo.udCGCTable)
	, max(JCCHInfo.udCGCTableID)
from (select JCCo=@toco
		, Job          = xj.VPJob --dbo.bfMuliPartFormat(ltrim(rtrim(j.JOBNUMBER)) +  ltrim(RTRIM(j.SUBJOBNUMBER)),@JobFormat)
		, PhaseGroup   = @PhaseGroup
		, Phase        = xrefPhase.newPhase
		, CostType     = xrefCostType.CostType
		, UM           = case 
						 when BQ<>0 and max(j.UNITOFMEASURE)<>'' 
						 then MAX(isnull(j.UNITOFMEASURE, @DefaultUMUnits))
						 else 
						     case 
							 	 when max(j.UNITOFMEASURE)<>'' 
							 	 then max(isnull(j.UNITOFMEASURE, @DefaultUM))
							 	 else @DefaultUM 
							 end 
						 end
		, OrigHours    = sum(BH)
		, OrigUnits    = sum(BQ)
		, OrigCost     = sum(BA)
		, udCGCTable   = 'JCTMST'
		, udCGCTableID = max(j.JCTMSTID)
	from CV_CMS_SOURCE.dbo.JCTMST j
		
		INNER JOIN CV_CMS_SOURCE.dbo.cvspMcKCGCActiveJobsForConversion jobs 
			ON	jobs.COMPANYNUMBER = j.COMPANYNUMBER
			AND jobs.JOBNUMBER     = j.JOBNUMBER
			and jobs.SUBJOBNUMBER  = j.SUBJOBNUMBER
			
		join Viewpoint.dbo.budxrefJCJobs xj
			on xj.COMPANYNUMBER = j.COMPANYNUMBER and xj.DIVISIONNUMBER = j.DIVISIONNUMBER and xj.JOBNUMBER = j.JOBNUMBER
				and xj.SUBJOBNUMBER = j.SUBJOBNUMBER
		
		join Viewpoint.dbo.budxrefPhase  xrefPhase
		on xrefPhase.Company=@fromco 
		and xrefPhase.oldPhase=JCDISTRIBTUION
		
		join Viewpoint.dbo.budxrefCostType xrefCostType 
			on xrefCostType.Company=@fromco 
			and xrefCostType.CMSCostType=j.COSTTYPE
			
		join (select CN=COMPANYNUMBER, JN=JOBNUMBER,SJ=SUBJOBNUMBER, JD=JCDISTRIBTUION, 
				CT=COSTTYPE , UM=max(UNITOFMEASURE), BH=sum(BUDGETEDHRS), BQ=sum(BUDGETEDQTY),BA=sum(BUDGETAMT)
				from CV_CMS_SOURCE.dbo.JCTMST j2
				where j2.COMPANYNUMBER=@fromco
				group by j2.COMPANYNUMBER, j2.JOBNUMBER, j2.SUBJOBNUMBER, j2.JCDISTRIBTUION, j2.COSTTYPE) 
				as x 
				on CN=j.COMPANYNUMBER 
				and JN=j.JOBNUMBER 
				and SJ=j.SUBJOBNUMBER 
				and JD=JCDISTRIBTUION 
				and CT=COSTTYPE
				
		--left join (select COMPANYNUMBER, JOBNUMBER, SUBJOBNUMBER, JOBSTATUS=max(JOBSTATUS)
		--			from CV_CMS_SOURCE.dbo.JCTDSC
		--			group by COMPANYNUMBER, JOBNUMBER, SUBJOBNUMBER)
		--			as o
		--			on o.COMPANYNUMBER=j.COMPANYNUMBER 
		--			and o.JOBNUMBER=j.JOBNUMBER 
		--			and o.SUBJOBNUMBER=j.SUBJOBNUMBER
					
	where j.COMPANYNUMBER=@fromco 
			and j.COSTTYPE not in ('R') 
			and j.JOBNUMBER<>'' 
			--and isnull(o.JOBSTATUS,0)<>case when @OpenJobsYN='Y' then 3 else 99 end 
			
	group by j.COMPANYNUMBER
		, xj.VPJob --dbo.bfMuliPartFormat(ltrim(rtrim(j.JOBNUMBER)) +  ltrim(RTRIM(j.SUBJOBNUMBER)),@JobFormat)
		, newPhase 
		, CostType
		, UM,BH,BQ,BA ) 
		
	as JCCHInfo
	
JOIN bJCJM m 
	on JCCHInfo.JCCo = m.JCCo 
	and JCCHInfo.Job = m.Job 
		
		
		
group by JCCHInfo.JCCo,JCCHInfo.Job, PhaseGroup, Phase, CostType;

 
select @rowcount=@@rowcount



COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


ALTER Table bJCCH enable trigger all;

return @@error

GO
