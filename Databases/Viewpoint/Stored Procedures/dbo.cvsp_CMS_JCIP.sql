
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure  [dbo].[cvsp_CMS_JCIP] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		JCIP
	Created:	07.02.09
	Created by:	JJH  
	Revisions:	1. none
**/



set @errmsg=''
set @rowcount=0


--get Customer default
declare @defaultProjPlug varchar(1)
select @defaultProjPlug=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ProjPlug' and a.TableName='bJCCI'; 


ALTER TABLE bJCIP DISABLE TRIGGER ALL;

-- delete existing trans
BEGIN tran
delete from bJCIP where JCCo=@toco
	--and udConv = 'Y';
COMMIT TRAN;


-- add new trans
BEGIN TRAN
BEGIN TRY



INSERT bJCIP
	( JCCo	
	, Contract
	, Item
	, Mth
	, OrigContractAmt
	, OrigContractUnits
	, OrigUnitPrice
	, ContractAmt
	, ContractUnits
	, CurrentUnitPrice
	, BilledUnits
	, BilledAmt
	, ReceivedAmt
	, CurrentRetainAmt
	, BilledTax
	, ProjUnits
	, ProjDollars
	, ProjPlug
	, udSource
	, udConv
	 )

SELECT JCID.JCCo
	, JCID.Contract
	, JCID.Item
	, JCID.Mth
	, OrigContractAmt=SUM(case when JCTransType='OC' then ContractAmt else 0 end)
	, OrigContractUnits=SUM(case when JCTransType='OC' then ContractUnits else 0 end)
	, OrigUnitPrice=MAX(JCID.UnitPrice)
	, ContractAmt=SUM(JCID.ContractAmt)
	, ContractUnits=SUM(JCID.ContractUnits)
	, CurrentUnitPrice=MAX(JCID.UnitPrice)
	, BilledUnits=SUM(BilledUnits)
	, BilledAmt=SUM(BilledAmt)
	, ReceivedAmt=SUM(ReceivedAmt)
	, CurrentRetainAmt=SUM(CurrentRetainAmt)
	, BilledTax=sum(JCID.BilledTax)
	, ProjUnits=SUM(JCID.ProjUnits)
	, ProjDollars=SUM(JCID.ProjDollars)
	, ProjPlug=@defaultProjPlug
	, udSource ='JCIP'
	, udConv='Y'
from bJCID JCID
where JCID.JCCo=@toco
group by JCID.JCCo, JCID.Contract, JCID.Item, JCID.Mth



select @rowcount=@@rowcount;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER TABLE bJCIP ENABLE TRIGGER ALL;

return @@error
GO
