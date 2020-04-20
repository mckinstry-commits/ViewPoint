
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure [dbo].[cvsp_CMS_JCChangeOrderTempTable] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
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
	
	
	
	
	
**/


set @errmsg=''
set @rowcount=0


--get Customer defaults
declare @defaultACO varchar(10), @defaultItem varchar(16)
select @defaultACO=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DefaultACO' and a.TableName='bJCOH';

select @defaultItem=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Item' and a.TableName='bJCCI';



--declare variables for functions
Declare @Job varchar(30)
Set @Job =  (Select InputMask from vDDDTc where Datatype = 'bJob')

--clear existing table
if exists (select * from sysobjects where name='JCChangeOrders') drop table JCChangeOrders;
--Drop table instead of truncate table since the records are inserted directly below within the select statement instead of an "insert" statement

-- add new trans
BEGIN TRAN
BEGIN TRY


select JCCo = @toco
	,Job    = dbo.bfMuliPartFormat(RTRIM(d.JOBNUMBER) +  RTRIM(d.SUBJOBNUMBER),@Job)
	,ACO    = case 
				when (c.ContOnly='Y' or c.UpdateAll='Y' or c.ContCostOnly='Y') and h.ESTIMATENU<>'' 
						then space(10-len(ltrim(rtrim(h.ESTIMATENU)))) + ltrim(rtrim(h.ESTIMATENU))
				when (c.ContOnly='Y' or c.UpdateAll='Y' or c.ContCostOnly='Y') and h.ESTIMATENU='' 
						then space(10-len(ltrim(rtrim(h.REVISIONNO)))) + ltrim(rtrim(h.REVISIONNO))
				when (c.CostOnly='Y' or c.ContCostOnly='Y' or c.UpdateAll='Y') and h.RHWONA<>'' 
						then space(10-len(ltrim(rtrim(h.RHWONA)))) + ltrim(rtrim(h.RHWONA))
				when (c.CostOnly='Y' or c.ContCostOnly='Y' or c.UpdateAll='Y') and h.RHWONA='' 
						then space(10-len(ltrim(rtrim(h.REVISIONNO)))) + ltrim(rtrim(h.REVISIONNO)) 
				else @defaultACO 
				end
	,ACOItem		= '         1'
	,ApprovalDate	= case 
						when h.RHDTRV=0 
						then convert(varchar(5),datepart(mm,getdate() )) + '/' +
							 convert(varchar(5),datepart(dd,getdate() )) + '/' + 
							 convert(varchar(5),datepart(yy,getdate() )) 
						else substring(convert(nvarchar(max),h.RHDTRV),5,2) + '/' + 
							 substring(convert(nvarchar(max),h.RHDTRV),7,2) + '/' + 
							 substring(convert(nvarchar(max),h.RHDTRV),1,4) 
							 end
	,REVISIONAMT   = d.REVISIONAMT
	,HeaderDesc1   = LEFT(h.DESCRIPTION1,30)
	,DetailDesc    = LEFT(d.DESCRIPTION1,30)
	,CHGORDERTYPE  = h.CHGORDERTYPE     /*  1 = Cost, 2 = Revenue */
	,Phase         = p.newPhase
	,CostType      = t.CostType
	,RECORDTYPE    = d.RECORDTYPE
	,CONTRACTNO    = dbo.bfMuliPartFormat(RTRIM(d.JOBNUMBER) +  RTRIM(d.SUBJOBNUMBER),@Job)
	,Item          = case 
						when (c.ContOnly='Y' or c.UpdateAll='Y' or c.ContCostOnly='Y') 
						then @defaultItem
					--case when space(16-len(ltrim(rtrim(d.ITEMNUMBER)))) + ltrim(rtrim(d.ITEMNUMBER))=''
					--	then isnull(i.Item, @defaultItem) 
					--else space(16-len(ltrim(rtrim(d.ITEMNUMBER)))) + ltrim(rtrim(d.ITEMNUMBER)) end
						else null 
						end
	,DESCRIPTION1  = d.DESCRIPTION1
	,REVISIONHRS   = d.REVISIONHRS
	,ESTQTY        = d.ESTQTY 
	,CHGORDERQTY   = d.CHGORDERQTY
	,RevenueCOAmt  = case when (c.ContOnly='Y' or c.UpdateAll='Y' or c.ContCostOnly='Y') then d.REVISIONAMT else 0 end
	,RevenueCOUnits= case when (c.ContOnly='Y' or c.UpdateAll='Y' or c.ContCostOnly='Y') then d.CHGORDERQTY else 0 end	
	,UM            = case 
						when isnull(u.VPUM,d.ESTUOM)='' 
						then 
							case 
								when d.CHGORDERQTY=0 
								then isnull(x.UM,'LS') 
								else isnull(x.UM,'EA') 
								end
					  else isnull(u.VPUM,d.ESTUOM) 
					  end
	,udCGCTable    = 'JCTCGH'
	,udCGCTableID  = h.JCTCGHID
	
into JCChangeOrders

from CV_CMS_SOURCE.dbo.JCTCGH h 

	INNER JOIN CV_CMS_SOURCE.dbo.cvspMcKCGCActiveJobsForConversion jobs 
		ON	jobs.COMPANYNUMBER = h.RHCONO
		AND jobs.JOBNUMBER     = h.JOBNUMBER
		and jobs.SUBJOBNUMBER  = h.SUBJOBNUMBER

	join CV_CMS_SOURCE.dbo.JCTCGO d 
		on h.RHCONO=d.COMPANYNUMBER 
		and h.JOBNUMBER=d.JOBNUMBER 
		and h.SUBJOBNUMBER=d.SUBJOBNUMBER 
		and h.RHGP05=d.GROUPNO	
		
	join CV_CMS_SOURCE.dbo.COTypes c on h.CHGORDERTYPE=c.COType
	
	left join Viewpoint.dbo.budxrefPhase p on p.Company=@fromco and d.JCDISTRIBTUION=p.oldPhase
	
	left join Viewpoint.dbo.budxrefCostType t on t.Company=@fromco and d.COSTTYPE=t.CMSCostType
	
	left join (select JCCo, Contract, Item=min(Item)
				from bJCCI
				where JCCo=@toco
				group by JCCo, Contract)
				as i on i.JCCo=@toco 
					and dbo.bfMuliPartFormat(RTRIM(d.JOBNUMBER) +  RTRIM(d.SUBJOBNUMBER),@Job)=i.Contract
					
	left join Viewpoint.dbo.budxrefUM u on d.ESTUOM=u.CGCUM
	
	left join bJCCH x on x.JCCo=@toco 
		and dbo.bfMuliPartFormat(RTRIM(d.JOBNUMBER) +  RTRIM(d.SUBJOBNUMBER),@Job)=x.Job
		and x.Phase=p.newPhase and x.CostType=t.CostType
		
where isnull(c.SubOnly,'N')<>'Y'
	and h.RHCONO=@fromco
	
order by h.RHCONO, h.JOBNUMBER, h.SUBJOBNUMBER, h.RHGP05   



select @rowcount=@@rowcount


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


return @@error




GO
