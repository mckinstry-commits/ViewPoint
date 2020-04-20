SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE proc [dbo].[cvsp_CMS_ARInvoices_to_JC] (@fromco smallint,@toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, modified,
transmitted or executed without written consent from VCS.
=========================================================================
	Title:		AR Invoice update to JC
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
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Item' and a.TableName='bJCCI';


ALTER Table bJCID disable trigger ALL; --leave on so JCCI and JCCM get updated

-- delete existing trans
BEGIN tran
delete from bJCID where JCCo=@toco and (BilledAmt<>0 or CurrentRetainAmt<>0)
	--and udConv = 'Y';
COMMIT TRAN;


-- add new trans
BEGIN TRAN
BEGIN TRY



insert bJCID (JCCo, Mth, ItemTrans, Contract, Item, JCTransType, TransSource, 
	Description, PostedDate, ActualDate, BilledAmt, ReceivedAmt, CurrentRetainAmt, 
	ReversalStatus, ARCo, ARTrans, ARTransLine, ARInvoice, BilledTax, udSource,udConv)

select 
	  JCCo             = L.ARCo
	, Mth              = L.Mth
	, ItemTrans        = isnull(T.LastTrans,0) + ROW_NUMBER() OVER (PARTITION BY L.ARCo, L.Mth 
			                                   ORDER BY L.ARCo, L.Mth, L.ARTrans,L.ARLine)
	, Contract         = L.Contract
	, Item             = (case when Item.Item is null then isnull(j.MinItem,@defaultItem) else Item.Item end)
	, JCTransType      = 'AR' 
	, TransSource      = 'AR Invoice' 
	, Description      = L.Description
	, PostedDate	   = L.ActDate
	, ActualDate	   = L.ActDate
	, BilledAmt        = isnull(L.Amount,0)
	, ReceivedAmt      = 0
	, CurrentRetainAmt = isnull(L.Retainage,0)
	, ReversalStatus   = 0
	, ARCo             = L.ARCo
	, ARTrans          = L.ARTrans
	, ARTransLine      = L.ARLine
	, ARInvoice        = H.Invoice
	, BilledTax        = isnull(L.TaxAmount,0)
	, udSource         = 'ARInvoices_to_JC'
	, udConv           = 'Y'

FROM bARTL L

JOIN bARTH H 
	ON  L.ARCo    = H.ARCo 
	AND L.Mth     = H.Mth 
	AND L.ARTrans = H.ARTrans

left join HQTC T 
	ON L.ARCo       = T.Co 
	AND L.Mth       = T.Mth 
	AND T.TableName = 'bJCID'


left join JCCI as Item 
	ON L.ARCo      = Item.JCCo 
	AND L.Contract = Item.Contract 
	AND L.Item     = Item.Item

left join (select JCCo
			 , Contract
			 , MinItem=min(isnull(JCCI.Item,@defaultItem))
		   FROM JCCI 
		   GROUP BY
			    JCCo
			  , Contract)
			AS j
			ON     j.JCCo  = L.ARCo 
			AND j.Contract = L.Contract
			
WHERE  L.ARCo=@toco
	AND H.ARTransType in ('I','A') 
	AND L.Contract<>'       .  '
	and L.ActDate is not null;  -- added 8/30/2013 basically to not convert test data.


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
