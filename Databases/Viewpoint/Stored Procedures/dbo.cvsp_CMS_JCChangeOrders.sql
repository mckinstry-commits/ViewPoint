
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure  [dbo].[cvsp_CMS_JCChangeOrders] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		JC Change Orders (JCOH, JCOI, JCOD, PMOH, PMOI, PMOL)
	Created:	09.12.09
	Created by:	SR    
	Revisions:	1. 09/12/09 - Changed Mth in several places to have day '1' i.e. 12/1/2009 and not the date - JRE
				2. 9/14/09 - Changed the linking in the JCOI select statement to pull the correct contract item	- JH
				3. 9/14/09 - Corrected JCOH and JCOI inserts when no header exists (cost only CO) to pull - JH 
							the minimum item from JCCI (excluding item 1). 
				4. 9/14/09 - Added description to 999 change orders. - JH
**/


set @errmsg=''
set @rowcount=0

--get defaults from HQCO
declare @PhaseGroup tinyint
select @PhaseGroup=PhaseGroup from bHQCO where HQCo=@toco;

--get Customer defaults
declare @defaultACO varchar(10), @defaultACODesc varchar(40), @defaultUM char(3), @status char(10),
	@ecm char(1), @BillFlag char(1), @ItemUnitFlag char(1), @PhaseUnitFlag char(1), 
	@BuyOutYN char(1), @Plugged char(1), @ActiveYN char(1), @SourceStatus char(1)

select @defaultACO=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DefaultACO' and a.TableName='bJCOH';

select @defaultACODesc=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DefaultACODesc' and a.TableName='bJCOH';

select @defaultUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DefaultUM' and a.TableName='bJCCI';

select @status=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Status' and a.TableName='bPMOI';

select @ecm=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ECM' and a.TableName='bPMOL';


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



ALTER Table bJCOH disable trigger all;
ALTER Table bJCOD disable trigger all;
ALTER Table bJCOI disable trigger all;
ALTER Table bPMOH disable trigger all;
ALTER Table bPMOI disable trigger all;
ALTER Table bPMOL disable trigger all;
ALTER Table bJCCP disable trigger all;

ALter table bPMOI NOCHECK CONSTRAINT FK_bPMOI_bPMOH;


-- delete existing trans
BEGIN tran
delete from bJCOH where JCCo=@toco
	--and udConv = 'Y';
delete from bJCOD where JCCo=@toco
	--and udConv = 'Y';
delete from bJCOI where JCCo=@toco
	--and udConv = 'Y';
delete from bPMOH where PMCo=@toco
	--and udConv = 'Y';
delete from bPMOI where PMCo=@toco
	--and udConv = 'Y';
delete from bPMOL where PMCo=@toco
	--and udConv = 'Y';
delete from bJCID where JCCo=@toco and JCTransType='CO'
	--and udConv = 'Y';
delete from bJCCD where JCCo=@toco and JCTransType='CO'
	--and udConv = 'Y';
COMMIT TRAN;

ALter table bPMOI CHECK CONSTRAINT FK_bPMOI_bPMOH;


ALTER Table bJCOD enable trigger all;
ALTER Table bJCOI enable trigger all;

-- add new trans
BEGIN TRAN
BEGIN TRY


--Change Order Header
insert bJCOH (JCCo, Job, ACO, ACOSequence, Contract, Description, ApprovalDate, IntExt, 
udSource,udConv,udCGCTable,udCGCTableID)
select JCCo
	, Job
	, ACO
	, ACOSequence=row_number() over (partition by JCCo, Job order by JCCo, Job, min(ApprovalDate))
	, Contract=Job
	, Description=case when ACO='       999' then @defaultACODesc else min(HeaderDesc1) end
	, ApprovalDate=min(ApprovalDate)
	, IntExt='E'
	, udSource ='JCChangeOrders'
	, udConv='Y'
	, max(udCGCTable)
	, max(udCGCTableID)
from JCChangeOrders	
where JCCo=@toco
group by JCCo, Job, ACO;


select @rowcount=@@rowcount;

--Change Order items (Revenue)
insert bJCOI (JCCo, Job, ACO, ACOItem,Description,Contract,Item,ApprovedMonth,ContractUnits,ContUnitPrice,ContractAmt,
udSource,udConv,udCGCTable,udCGCTableID)
select c.JCCo
	, Job
	, ACO
	, ACOItem=space(10-datalength(rtrim(ACOItem))) + rtrim(ACOItem)
	, Description=min(DetailDesc)
	, Contract=Job
	, Item= min(i.Item)
		--max(case when c.Item='' or c.Item is null 
		--		then i.Item 
		--		else space(16-datalength(rtrim(c.Item))) + RTRIM(c.Item) 
		--	    end)
	, ApprovalMth=convert(nvarchar(max),datepart(mm,min(ApprovalDate))) + '/01/' + 
			convert(nvarchar(max),datepart(yy,min(ApprovalDate)))
	, ContractUnits=sum(RevenueCOUnits)
	, UnitCost=0
	, ContractAmt=sum(RevenueCOAmt)
	, udSource ='JCChangeOrders'
	, udConv='Y'
	,max(c.udCGCTable)
	,max(c.udCGCTableID)
from JCChangeOrders c 
	left join bJCCI i on c.JCCo=i.JCCo and c.Job=i.Contract
where c.JCCo=@toco	
	
group by c.JCCo, Job, ACO, ACOItem;


select @rowcount=@rowcount+@@rowcount;

--Insert JCCH records if they don't exist
alter table bJCCH disable trigger all;
insert bJCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, 
	BillFlag, ItemUnitFlag, PhaseUnitFlag, BuyOutYN, Plugged, ActiveYN, SourceStatus, udSource,udConv,udCGCTable,udCGCTableID)
select c.JCCo, c.Job, @PhaseGroup, c.Phase, c.CostType, @defaultUM,
	@BillFlag, @ItemUnitFlag, @PhaseUnitFlag, @BuyOutYN, @Plugged, @ActiveYN, @SourceStatus,'JCChangeOrders'
	, udConv='Y',max(c.udCGCTable),max(c.udCGCTableID)
from JCChangeOrders c
	left join bJCCH on c.JCCo=bJCCH.JCCo and c.Job=bJCCH.Job and c.Phase=bJCCH.Phase
		and c.CostType=bJCCH.CostType
where c.JCCo=@toco 
	and bJCCH.JCCo is null
	and c.Phase is not null
	and c.CostType is not null
group by c.JCCo, c.Job, c.Phase, c.CostType

select @rowcount=@rowcount+@@rowcount;

alter table bJCCH enable trigger all;



--Change Order Detail (Cost)
insert bJCOD (JCCo,Job, ACO, ACOItem, PhaseGroup, Phase, CostType, MonthAdded,
		UnitCost, EstHours, EstUnits, EstCost, UM,udSource,udConv,udCGCTable,udCGCTableID)
select c.JCCo
	, c.Job
	, c.ACO
	, ACOItem=space(10-datalength(rtrim(ACOItem))) + rtrim(ACOItem)
	, @PhaseGroup
	, c.Phase
	, c.CostType
	, convert(nvarchar(max),datepart(mm,min(c.ApprovalDate))) + '/01/' + 
			convert(nvarchar(max),datepart(yy,min(c.ApprovalDate)))
	, UnitCost=0
	, EstHours=sum(c.REVISIONHRS)
	, EstUnits=(case when sum(c.ESTQTY)=0 then 0 else sum(c.ESTQTY)/100 end)
	, EstCost=sum(c.REVISIONAMT)
	, UM=isnull(h.UM, @defaultUM)
	, udSource ='JCChangeOrders'
	, udConv='Y'
	, max(c.udCGCTable)
	,max(c.udCGCTableID)
from JCChangeOrders c 
	left join bJCCH h on c.JCCo=h.JCCo and c.Job=h.Job and c.Phase=h.Phase and
			c.CostType=h.CostType
where c.CostType is not null 
	and c.Phase is not null
	and isnull(h.ActiveYN,'Y')='Y'
group by c.JCCo, c.Job, c.ACO,c.ACOItem, c.Phase, c.CostType, isnull(h.UM,@defaultUM);


select @rowcount=@rowcount+@@rowcount;

--Insert PMOH records from JCOH
insert bPMOH (PMCo, Project,ACO, Description, ACOSequence, Contract, IntExt, ApprovalDate, ApprovedBy,udSource,
udConv,udCGCTable,udCGCTableID)
select JCCo
	, Project=Job
	, ACO
	, Description
	, ACOSequence
	, Contract
	, IntExt
	, ApprovalDate
	, ApprovedBy='viewpointcs'
	, udSource ='JCChangeOrders'
	, udConv='Y'
	, udCGCTable
	, udCGCTableID
	from bJCOH
where bJCOH.JCCo=@toco;


select @rowcount=@rowcount+@@rowcount;


--Insert PMOI records from JCOI
insert bPMOI (PMCo, Project, ACO, ACOItem, Description, Status, ApprovedDate, UM, Units, UnitPrice,
	ApprovedAmt, Contract, ContractItem, Approved, ApprovedBy, InterfacedDate, ProjectCopy,udSource,
	udConv,udCGCTable,udCGCTableID)
select JCCo
	, Job
	, ACO
	, ACOItem
	, Description
	, Status=@status
	, ApprovedMonth
	, UM=@defaultUM
	, ContractUnits
	, ContUnitPrice
	, ContractAmt
	, Contract
	, Item
	, Approved='Y'
	, ApprovedBy='viewpointcs'
	, InterfacedDate=getdate()
	, ProjectCopy='N'
	, udSource ='JCChangeOrders'
	, udConv='Y'
	,udCGCTable
	,udCGCTableID
from bJCOI
where bJCOI.JCCo=@toco;


select @rowcount=@rowcount+@@rowcount;

insert bPMOL (PMCo, Project, ACO, ACOItem, PhaseGroup, Phase, CostType, EstUnits, UM, UnitHours, EstHours, HourCost
	,UnitCost, ECM, EstCost, SendYN, InterfacedDate,udSource,udConv,udCGCTable,udCGCTableID)
select JCCo
	, Project=Job
	, ACO
	, ACOItem
	, PhaseGroup
	, Phase
	, CostType
	, EstUnits
	, UM
	, UnitHours=0
	, EstHours
	, HourCost=0
	, UnitCost
	, ECM=@ecm
	, EstCost
	, SendYN='Y'
	, InterfacedDate=getdate() 
	, udSource = 'JCChangeOrders'
	, udConv='Y'
	,udCGCTable,udCGCTableID
from bJCOD
where JCCo=@toco;


select @rowcount=@rowcount+@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


ALTER Table bJCOH enable trigger all;
ALTER Table bJCOI enable trigger all;
ALTER Table bJCOD enable trigger all;
ALTER Table bPMOH enable trigger all;
ALTER Table bPMOI enable trigger all;
ALTER Table bPMOL enable trigger all;
ALTER Table bJCCP enable trigger all;

return @@error





GO
