
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_ARReceipts_to_JC] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, modified,
transmitted or executed without written consent from VCS.
=========================================================================
	Title:		AR Receipt update to JC
	Created:	07.02.09
	Created by:	JRE
	Revisions:	1. none
**/


set @errmsg=''
set @rowcount=0

--get Customer defaults
declare @defaultItem varchar(16)
select @defaultItem=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Item' and a.TableName='bJCCI';


--ALTER Table bJCID disable trigger ALL; --leave on so JCCI and JCCM get updated

-- delete existing trans
BEGIN tran
delete from bJCID where JCCo=@toco and ReceivedAmt<>0
	and udConv = 'Y';
COMMIT TRAN;


-- add new trans
BEGIN TRAN
BEGIN TRY

insert bJCID (JCCo, Mth, ItemTrans, Contract, Item, JCTransType, TransSource, 
	Description, PostedDate, ActualDate, 
	BilledAmt, ReceivedAmt, CurrentRetainAmt, 
	ReversalStatus, ARCo, ARTrans, ARTransLine, ARCheck, udSource,udConv)


select  L.ARCo
	, L.Mth
	, isnull(T.LastTrans,0) + ROW_NUMBER() OVER (PARTITION BY L.ARCo, L.Mth ORDER BY L.ARCo, L.Mth, L.ARTrans,L.ARLine)
	, L.Contract
	, Item=(case when Item.Item is null then j.MinItem else Item.Item end)
	, JCTransType='AR' 
	, TransSource='AR Receipt' 
	, Description=H.Description 
	, PostedDate=L.ActDate 
	, ActualDate=L.ActDate 
	, BilledAmt = 0
	, ReceivedAmt=(L.Amount*-1) 
	, CurrentRetainAmt = L.Retainage
	, ReversalStatus = 0
	, ARCo=L.ARCo
	, L.ARTrans
	, ARTransLine=L.ARLine
	, ARCheck=H.CheckNo
	, udSource ='ARReceipts_to_JC'
	, udConv='Y'
from bARTL L
	inner join bARTH H on L.ARCo=H.ARCo and L.Mth=H.Mth and L.ARTrans=H.ARTrans
	left join HQTC T on L.ARCo=T.Co and L.Mth=T.Mth and  T.TableName='bJCID' 
	left join JCCI as Item on L.ARCo=Item.JCCo and L.Contract=Item.Contract and L.Item=Item.Item
	left join (select JCCo, Contract, MinItem=min(isnull(JCCI.Item,@defaultItem))
				from JCCI 
				group by JCCo, Contract)
				as j
				on j.JCCo=L.ARCo and j.Contract=L.Contract
where L.ARCo=@toco 
	and H.ARTransType='P' and L.Contract<>'       .  ' and L.Contract is not null;


select @rowcount=@@rowcount

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bJCID enable trigger ALL;

return @@error
GO
