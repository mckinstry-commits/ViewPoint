SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/**
=========================================================================
Copyright © 2012 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		ARTH Insert for Zero sums on AR Aging
	Created on:	9.2.09
	Created by:		VCS Technical Services - JRE
	Revisions:		
	1. 4/19/10 JRE - Added a check to make sure this only zeroed out invoices where the amount
		less reatainage equaled zero AND the total tainage was less than zero. 
		It was clearing out customer balances that only had retainage since the 
		amount and retainage columns netted to zero. 
		I'm leaving as part of the standard code for now but it may need to be 
		re-evaluated for the next customer.
	
**/


CREATE proc [dbo].[cvsp_CMS_ARTHZeroSums] 
(@fromco smallint, @toco smallint, @errmsg varchar(1000) output, @rowcount bigint output) 

as

set @errmsg=''
set @rowcount=0

--get defaults from ARCO
declare @CMCo tinyint, @CMAcct int
select @CMCo=CMCo, @CMAcct=CMAcct from bARCO
where ARCo=@toco;


alter table bARTH disable trigger all;
alter table bARTL disable trigger all;

-- delete existing trans
-- deletes handled elsewhere


-- add new trans
BEGIN TRAN
BEGIN TRY

-- add headers


insert bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, JCCo, CheckNo, Source, 
	TransDate, CheckDate, Description, CMCo, CMAcct, CMDeposit, CreditAmt,   
	EditTrans, ExcludeFC, FinanceChg,udSource,udConv)

select th.ARCo
	, Mth=th.cMaxMth 
	, ARTrans=isnull(H.LastTrans,1)+isnull(H.LastTrans,1)+ROW_NUMBER() 
				Over (ORDER BY th.ARCo, th.cMaxMth, th.Customer)
	, ARTransType='P'
	, CustGroup=th.CustGroup
	, Customer=th.Customer
	, JCCo=th.JCCo
	, CheckNo='Conversion'
	, Source='AR Receipt'
	, TransDate=th.TransDate
	, CheckDate=th.TransDate
	, Description='Conversion Balance'
	, CMCo=@CMCo
	, CMAcct=@CMAcct
	, CMDeposit='Conv'+CONVERT(varchar(6),th.Customer)
	, CreditAmt=0
	, EditTrans='N'
	, ExcludeFC='Y'
	, FinanceChg=0
	, udSource ='ARTHZeroSums'
	, udConv='Y'
from 
	(	select distinct l.ARCo, c.cMaxMth, 
		  CustGroup=t.sCustGroup, Customer=t.sCustomer, JCCo=l.ARCo,
		  TransDate=c.cMaxTransDate, c.cMaxTransDate
		from bARTL l
		  join (select sARCo=bARTL.ARCo, sCustGroup=bARTH.CustGroup, sCustomer=bARTH.Customer,
				   sMth=bARTL.Mth, sARTrans=bARTL.ARTrans,
				   sAmount=sum(bARTL.Amount), sTaxAmount=sum(bARTL.TaxAmount), 
				   sRetainage=sum(bARTL.Retainage)
				from bARTL 
					join bARTH on bARTL.ARCo=bARTH.ARCo and bARTL.Mth=bARTH.Mth and bARTL.ARTrans=bARTH.ARTrans
				where bARTL.ARCo=@toco 
				group by bARTL.ARCo, bARTH.CustGroup, bARTH.Customer, bARTL.Mth, bARTL.ARTrans
				having sum(bARTL.Amount)<>0 or sum(bARTL.TaxAmount)<>0 or sum(bARTL.Retainage)<>0
				) as t 
				on t.sARCo=l.ARCo and t.sARTrans=l.ARTrans and t.sMth=l.Mth
			left join(select cARCo=bARTL.ARCo, cCustomer=bARTH.Customer, cMaxMth=max(bARTL.Mth),
					cMaxTransDate=max(bARTH.TransDate),
					cAmount=sum(bARTL.Amount), cTaxAmount=sum(bARTL.TaxAmount), 
					cRetainage=sum(bARTL.Retainage)
				from bARTL 
					join bARTH on bARTL.ARCo=bARTH.ARCo and bARTL.Mth=bARTH.Mth and bARTL.ARTrans=bARTH.ARTrans
				where bARTL.ARCo=@toco
				group by bARTL.ARCo, bARTH.Customer
--				having sum(bARTL.Amount-bARTL.Retainage)=0) --original code 
				having sum(bARTL.Amount-bARTL.Retainage)=0 and sum(bARTL.Retainage)<=0) --added additional check on retg 4/19
				as c 
				on c.cARCo=t.sARCo and c.cCustomer=t.sCustomer
		) as th
      left join bHQTC H 
		on th.ARCo=H.Co and th.cMaxMth=H.Mth and H.TableName='bARTH'
where th.ARCo=@toco and cMaxMth is not null
order by th.ARCo, th.Customer, th.cMaxMth;


select @rowcount=@@rowcount
COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bARTH enable trigger all;
alter table bARTL enable trigger all;

return @@error




GO
