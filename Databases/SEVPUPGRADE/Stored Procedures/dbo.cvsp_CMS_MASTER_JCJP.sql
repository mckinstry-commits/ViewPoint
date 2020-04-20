SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE proc [dbo].[cvsp_CMS_MASTER_JCJP] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, modified,
transmitted or executed without written consent from VCS.
=========================================================================

	Title:		JC Job Phases (JCJP)
	Created:	12.01.08
	Created by:	Shayona Roberts
	Revisions:	1. 02.20.09 - A. Bynum - Edited for CMS; variables entered for multiple company conversion.
				2. JRE 08/07/09 - created proc & @toco, @fromco		
				3. CR 11/18/09 - added Open Job functionality
				4. BC 05/14/12 - Added Company to join for budXRefPhase
				5. BC 05/14/12 - Added query to populate JCJP with Subcontract Phases not in JCTMST.
	Notes:		Imports JCJP Job Phases table from CMS JCPMST table.

**/

set @errmsg=''
set @rowcount=0

-- get vendor group from HQCO
declare @PhaseGroup smallint
select @PhaseGroup=PhaseGroup from bHQCO where HQCo=@toco;

-- Open Jobs Only or all Jobs
declare @OpenJobsYN varchar(1)
select @OpenJobsYN = ISNULL(b.DefaultString,a.DefaultString)
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='OpenJobYN' and a.TableName='OpenJobs';

-- get customer defaults
declare @defaultItem varchar(16)
select @defaultItem=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Item' and a.TableName='bJCCI'; 

--declare variables for use in functions
declare @JobFormat varchar(30), @JobLen smallint, @SubJobLen smallint
Set @JobFormat =  (Select InputMask from vDDDTc where Datatype = 'bJob');
select @JobLen = LEFT(InputMask,1) from vDDDTc where Datatype = 'bJob'
select @SubJobLen = SUBSTRING(InputMask,4,1) from vDDDTc where Datatype = 'bJob'

ALTER Table bJCJP disable trigger all;	

-- delete existing trans
BEGIN tran
delete from bJCJP where JCCo=@toco 
	and udConv = 'Y';
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY

insert bJCJP (JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, 
				ActiveYN, Notes, udSource,udConv,udCGCTable,udCGCTableID)

select JCCo        = @toco
	, Job          = dbo.bfMuliPartFormat(ltrim(rtrim(j.JOBNUMBER)) + ltrim(rtrim(j.SUBJOBNUMBER)),@JobFormat)
	, PhaseGroup   =  @PhaseGroup
	, Phase        = x.newPhase
	, Description  = max(rtrim(j.DESC20A))
	, Contract     = min(dbo.bfMuliPartFormat(ltrim(rtrim(j.JOBNUMBER)),@JobFormat))
	, Item         = @defaultItem
	, ActiveYN     = 'Y'
	, Notes        = max(j.DESC20A) + '  '+ max(x.oldPhase)
	, udSource     = 'MASTER_JCJP'
	, udConv       = 'Y'
	, udCGCTable   =  'JCTMST'
	, udCGCTableID =  min(j.JCTMSTID)
	
from CV_CMS_SOURCE.dbo.JCTMST j 

INNER JOIN CV_CMS_SOURCE.dbo.cvspMcKCGCActiveJobsForConversion jobs 
		ON	jobs.COMPANYNUMBER = j.COMPANYNUMBER
		AND jobs.JOBNUMBER     = j.JOBNUMBER
		and jobs.SUBJOBNUMBER  = j.SUBJOBNUMBER


join Viewpoint.dbo.budxrefPhase x
	on x.oldPhase=j.JCDISTRIBTUION 
	and x.Company=j.COMPANYNUMBER
	
WHERE j.COMPANYNUMBER=@fromco 
--and isnull(j.JOBSTATUS,0) <> case when @OpenJobsYN = 'Y' then 3 else isnull(c.JOBSTATUS,0) end 

/* email from Sarah 8/27/2013
I(sarah) wanted to clarify that we only want CGC pay items with a budget or actual amount associated
 to be brought over.  
 */
and 
(BUDGETAMT <> 0 OR ACTUALCSTJTD <> 0)   

group by dbo.bfMuliPartFormat(ltrim(rtrim(j.JOBNUMBER)) + ltrim(rtrim(j.SUBJOBNUMBER)),@JobFormat)
	--,j.JCDISTRIBTUION
	,x.newPhase;

select @rowcount=@@rowcount


----Add subcontract phases not set up in JCTMST
--insert bJCJP (JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ActiveYN)
--select distinct
--	 JCCo = @toco
--	,Job = dbo.bfMuliPartFormat(ltrim(rtrim(ap.JOBNUMBER)) + LTRIM(rtrim(ap.SUBJOBNUMBER)), @JobFormat)
--	,PhaseGroup = @PhaseGroup
--	,Phase = xp.newPhase
--	,Description = ap.CONTRDESC1
--	,Contract=dbo.bfMuliPartFormat(ltrim(rtrim(ap.JOBNUMBER)),@JobFormat)
--	,Item = @defaultItem
--	,ActiveYN = 'Y'
----select top 1000 *
--from (select COMPANYNUMBER, JOBNUMBER, SUBJOBNUMBER, JCDISTRIBTUION, MAX(CONTRDESC1) as CONTRDESC1
--			from CV_CMS_SOURCE.dbo.APTCNS
--			group by COMPANYNUMBER, JOBNUMBER, SUBJOBNUMBER, JCDISTRIBTUION) ap
--join budxrefPhase xp
--	on xp.Company=ap.COMPANYNUMBER and xp.oldPhase=ap.JCDISTRIBTUION
--left join bJCJP jp
--	on jp.JCCo=ap.COMPANYNUMBER and jp.Phase=xp.newPhase
--		and jp.Job=dbo.bfMuliPartFormat(ltrim(rtrim(ap.JOBNUMBER)) + LTRIM(rtrim(ap.SUBJOBNUMBER)), @JobFormat)
--where ap.COMPANYNUMBER=@fromco and jp.Phase is null

--select @rowcount=@rowcount + @@ROWCOUNT


update bJCJP
set Item = a.Item
from (select JCCo, Contract, Item = min(Item) 
		from bJCCI 
		where bJCCI.JCCo=@toco
		group by JCCo, Contract) 
		as a
	join bJCJP b on a.JCCo=b.JCCo and a.Contract=b.Contract;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bJCJP enable trigger all;

return @@error

GO
