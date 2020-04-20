SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE procedure [dbo].[cvsp_CMS_JCChangeOrderTempTable_custom] 
	( @fromco1	smallint
	, @fromco2	smallint
	, @fromco3	smallint
	, @toco		smallint
	, @errmsg	varchar(1000) output
	, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		JC Change Order Temp Table
	Created:	12.01.08
	Created by:	Shayona Roberts
	Revisions:	1. 02.20.09 - A. Bynum - Edited for CMS.
				2. 10/03/13 BTC - Added JCJobs cross reference
	
	
**/


set @errmsg=''
set @rowcount=0


--get Customer defaults
declare @defaultACO varchar(10), @defaultItem varchar(16), @PhaseGroup int
select @defaultACO=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DefaultACO' and a.TableName='bJCOH';

select @defaultItem=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Item' and a.TableName='bJCCI';

select @PhaseGroup = PhaseGroup
  from bHQCO
 where HQCo = @toco



--declare variables for functions
Declare @Job varchar(30)
Set @Job =  (Select InputMask from vDDDTc where Datatype = 'bJob')

--clear existing table
if exists (select * from sysobjects where name='JCChangeOrders') drop table JCChangeOrders;
--Drop table instead of truncate table since the records are inserted directly below within the select statement instead of an "insert" statement

-- add new trans
BEGIN TRAN
BEGIN TRY


select JCCo = 1
	,Job    = xj.VPJob -- dbo.bfMuliPartFormat(RTRIM(d.JOBNUMBER) +  RTRIM(d.SUBJOBNUMBER),@Job)
	,ACO    = space(10-len(ltrim(rtrim(h.CONTRACTNO)))) + ltrim(rtrim(h.CONTRACTNO))
			
	,ACOItem		= space(10-len(ltrim(rtrim(h.ITEMNUMBER)))) + ltrim(rtrim(h.ITEMNUMBER))
	,ApprovalDate	= case 
						when h.ENTEREDDATE=0 
						then convert(varchar(5),datepart(mm,getdate() )) + '/' +
							 convert(varchar(5),datepart(dd,getdate() )) + '/' + 
							 convert(varchar(5),datepart(yy,getdate() )) 
						else substring(convert(nvarchar(max),h.ENTEREDDATE),5,2) + '/' + 
							 substring(convert(nvarchar(max),h.ENTEREDDATE),7,2) + '/' + 
							 substring(convert(nvarchar(max),h.ENTEREDDATE),1,4) 
							 end
	,REVISIONAMT   = h.CHANGEORDAMT
	,HeaderDesc1   = LEFT(h.CONTDESC1,30)
	,DetailDesc    = LEFT(h.CONTDESC1,30)
	,CHGORDERTYPE  = 2     /*  1 = Cost, 2 = Revenue */
	,Phase         = null--p.newPhase
	,CostType      = null--t.CostType
	,RECORDTYPE    = 2
	,CONTRACTNO    = xj.VPJobExt -- dbo.bfMuliPartFormat(RTRIM(d.JOBNUMBER) +  RTRIM(d.SUBJOBNUMBER),@Job)
	,Item          = space(16-len(ltrim(rtrim(h.CONTRACTNO)))) + ltrim(rtrim(h.CONTRACTNO))
	,DESCRIPTION1  = h.CONTDESC1
	,REVISIONHRS   = 0
	,ESTQTY        = h.ESTQTY 
	,CHGORDERQTY   = 0
	,RevenueCOAmt  = h.CHANGEORDAMT
	,RevenueCOUnits= 0
	,UM            = 'LS'
	,udCGCTable    = 'ARTCNS'
	,udCGCTableID  = h.ARTCNSID
	
into JCChangeOrders
from CV_CMS_SOURCE.dbo.ARTCNS h 

	INNER JOIN [MCK_MAPPING_DATA ].[dbo].[McKCGCActiveJobsForConversion2] jobs 
		ON	jobs.GCONO = h.COMPANYNUMBER
		AND jobs.GJBNO     = h.JOBNUMBER
		and jobs.GSJNO  = h.SUBJOBNUMBER
		and jobs.GDVNO  = h.DIVISIONNUMBER
		
	join Viewpoint.dbo.budxrefJCJobs xj
		on xj.COMPANYNUMBER = h.COMPANYNUMBER and xj.DIVISIONNUMBER = h.DIVISIONNUMBER and xj.JOBNUMBER = h.JOBNUMBER
			and xj.SUBJOBNUMBER = h.SUBJOBNUMBER
		and xj.VPJob is not null
	
	left join (select JCCo, Contract, Item=min(Item)
				from bJCCI
				where JCCo=1
				group by JCCo, Contract)
				as i on i.JCCo=1 
					and i.Contract = xj.VPJobExt --dbo.bfMuliPartFormat(RTRIM(d.JOBNUMBER) +  RTRIM(d.SUBJOBNUMBER),@Job)=i.Contract
	
where h.COMPANYNUMBER in (1,15,50)
  and h.CHANGEORDAMT <> 0
order by h.COMPANYNUMBER, h.JOBNUMBER, h.SUBJOBNUMBER, h.SEQCTL04   


select @rowcount=@@rowcount


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


return @@error










GO
