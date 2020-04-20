SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



CREATE procedure  [dbo].[cvsp_CMS_JCUpdate] 
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
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Synch's JCCM/JCCI with the detail tables
	Created:	11.12.09
	Created by:	JJH  
	Revisions:	1. none
**/



set @errmsg=''
set @rowcount=0


ALTER TABLE bJCCM DISABLE TRIGGER ALL;
ALTER TABLE bJCCI DISABLE TRIGGER ALL;

-- add new trans
BEGIN TRAN
BEGIN TRY



--Update Contract Amounts on JCCI 
update bJCCI set bJCCI.ContractAmt=JCID.ContractAmt, bJCCI.ContractUnits=JCID.ContractUnits,
	 bJCCI.BilledUnits=JCID.BilledUnits, bJCCI.BilledAmt=JCID.BilledAmt
from bJCCI 
	join (select JCCo, Contract, Item, BilledAmt=sum(BilledAmt), BilledUnits=sum(BilledUnits),
				ContractAmt=sum(ContractAmt), ContractUnits=sum(ContractUnits)
			from bJCID
			where JCCo=@toco
			group by JCCo, Contract, Item)
			as JCID
			on JCID.JCCo=bJCCI.JCCo and JCID.Contract=bJCCI.Contract and JCID.Item=bJCCI.Item
where bJCCI.JCCo=@toco
	and (bJCCI.BilledAmt<> isnull(JCID.BilledAmt,0)
	or bJCCI.BilledUnits<> isnull(JCID.BilledUnits,0)
	or bJCCI.ContractAmt<> isnull(JCID.ContractAmt,0)
	or bJCCI.ContractUnits<> isnull(JCID.ContractUnits,0))

select @rowcount=@@rowcount;	

--Updates Original Contract Amounts with JCCI values 
--triggers are turned off which results in a difference
update bJCCM set bJCCM.OrigContractAmt=JCCI.OrigContractAmt
from bJCCM 
	join (select JCCo, Contract, OrigContractAmt=sum(OrigContractAmt)
			from bJCCI
			where JCCo=@toco
			group by JCCo, Contract)
			as JCCI
			on JCCI.JCCo=bJCCM.JCCo and JCCI.Contract=bJCCM.Contract
where bJCCM.JCCo=@toco
	and bJCCM.OrigContractAmt<> isnull(JCCI.OrigContractAmt,0)


select @rowcount=@rowcount+@@rowcount;


--Updates Current Contract Amounts with JCCI values 
--triggers are turned off which results in a difference
update bJCCM set bJCCM.ContractAmt=JCCI.ContractAmt
from bJCCM 
	join (select JCCo, Contract, ContractAmt=sum(ContractAmt)
			from bJCCI
			where JCCo=@toco
			group by JCCo, Contract)
			as JCCI
			on JCCI.JCCo=bJCCM.JCCo and JCCI.Contract=bJCCM.Contract
where bJCCM.JCCo=@toco
	and bJCCM.ContractAmt<> isnull(JCCI.ContractAmt,0)


select @rowcount=@rowcount+@@rowcount;


--Update Billed Amounts on JCCM 
update bJCCM set bJCCM.BilledAmt=JCID.BilledAmt
from bJCCM 
	join (select JCCo, Contract, BilledAmt=sum(BilledAmt)
			from bJCID
			where JCCo=@toco
			group by JCCo, Contract)
			as JCID
			on JCID.JCCo=bJCCM.JCCo and JCID.Contract=bJCCM.Contract
where bJCCM.JCCo=@toco
	and bJCCM.BilledAmt<> isnull(JCID.BilledAmt,0)


select @rowcount=@rowcount+@@rowcount;




--Update Received Amounts on JCCM 
update bJCCM set bJCCM.ReceivedAmt=JCID.ReceivedAmt
from bJCCM 
	join (select JCCo, Contract, ReceivedAmt=sum(ReceivedAmt)
			from bJCID
			where JCCo=@toco
			group by JCCo, Contract)
			as JCID
			on JCID.JCCo=bJCCM.JCCo and JCID.Contract=bJCCM.Contract
where bJCCM.JCCo=@toco
	and bJCCM.ReceivedAmt<> isnull(JCID.ReceivedAmt,0)


select @rowcount=@rowcount+@@rowcount;


--Update Received Amounts on JCCI 
update bJCCI set bJCCI.ReceivedAmt=JCID.ReceivedAmt
from bJCCI 
	join (select JCCo, Contract, Item, ReceivedAmt=sum(ReceivedAmt)
			from bJCID
			where JCCo=@toco
			group by JCCo, Contract, Item)
			as JCID
			on JCID.JCCo=bJCCI.JCCo and JCID.Contract=bJCCI.Contract and JCID.Item=bJCCI.Item
where bJCCI.JCCo=@toco
	and bJCCI.ReceivedAmt<> isnull(JCID.ReceivedAmt,0)


select @rowcount=@rowcount+@@rowcount;

--Update Retg Amounts on JCCM 
update bJCCM set bJCCM.CurrentRetainAmt=JCID.CurrentRetainAmt
from bJCCM 
	join (select JCCo, Contract, CurrentRetainAmt=sum(CurrentRetainAmt)
			from bJCID
			where JCCo=@toco
			group by JCCo, Contract)
			as JCID
			on JCID.JCCo=bJCCM.JCCo and JCID.Contract=bJCCM.Contract
where bJCCM.JCCo=@toco
	and bJCCM.CurrentRetainAmt<> isnull(JCID.CurrentRetainAmt,0)


select @rowcount=@rowcount+@@rowcount;


--Update Retg Amounts on JCCI 
update bJCCI set bJCCI.CurrentRetainAmt=JCID.CurrentRetainAmt
from bJCCI 
	join (select JCCo, Contract, Item, CurrentRetainAmt=sum(CurrentRetainAmt)
			from bJCID
			where JCCo=@toco
			group by JCCo, Contract, Item)
			as JCID
			on JCID.JCCo=bJCCI.JCCo and JCID.Contract=bJCCI.Contract and JCID.Item=bJCCI.Item
where bJCCI.JCCo=@toco
	and bJCCI.CurrentRetainAmt<> isnull(JCID.CurrentRetainAmt,0)


select @rowcount=@rowcount+@@rowcount;




COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER TABLE bJCCM ENABLE TRIGGER ALL;
ALTER TABLE bJCCI ENABLE TRIGGER ALL;

return @@error



GO
