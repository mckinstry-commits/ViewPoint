SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






create proc [dbo].[cvsp_CMS_ARTLZeroSums] (@fromco tinyint, @toco tinyint, 
		@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		ARTL Zero sums (ARTL) 
	Created:	9.2.09
	Created By:	JRE    
	Revisions:	1. None
**/
set @errmsg=''
set @rowcount=0


alter table bARTL disable trigger all;


-- delete existing trans
-- no deletes necessary

-- add new trans
BEGIN TRAN
BEGIN TRY

INSERT bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType,
       Description, GLCo, GLAcct, TaxGroup, TaxCode, Amount, 
      TaxBasis, TaxAmount, RetgPct, Retainage, DiscOffered, TaxDisc, 
      DiscTaken, ApplyMth, ApplyTrans, ApplyLine, JCCo, Contract, 
      Item, ActDate, PurgeFlag, FinanceChg, RetgTax,udSource,udConv)

select ARCo=ph.ARCo
	, Mth=ph.Mth
	, ARTrans=ph.ARTrans
	, ARLine=ROW_NUMBER ( ) OVER (partition by ph.ARCo, ph.Mth, ph.ARTrans
		  order by ph.ARCo, ph.Mth,    ph.ARTrans )
	, RecType=l.RecType
	, LineType=l.LineType
	, Description='Conversion'
	, l.GLCo
	, l.GLAcct
	, l.TaxGroup
	, l.TaxCode
	, Amount=sAmount*-1
	, TaxBasis=0
	, TaxAmount=sTaxAmount*-1
	, RetgPct=0
	, Retainage=sRetainage*-1
	, DiscOffered=0
	, TaxDisc=0
	, DiscTaken=0
	, l.ApplyMth
	, l.ApplyTrans
	, l.ApplyLine
	, l.JCCo
	, l.Contract
	, l.Item
	, ActDate=h.TransDate
	, PurgeFlag='N'
	, FinanceChg=0
	, RetgTax=0
	, udSource ='ARTLZeroSums'
	, udConv='Y'
from bARTL l
	join bARTH h on l.ARCo = h.ARCo AND l.Mth = h.Mth AND l.ARTrans = h.ARTrans
	join bARTH ph on h.ARCo=ph.ARCo and h.CustGroup=ph.CustGroup and h.Customer=ph.Customer
		  and ph.Description='Conversion Balance'
	join (select bARTL.ARCo, bARTL.ApplyMth, bARTL.ApplyTrans, bARTL.ApplyLine,
           sAmount=sum(bARTL.Amount), sTaxAmount=sum(bARTL.TaxAmount), 
           sRetainage=sum(bARTL.Retainage)
		from bARTL 
			join bARTH on bARTL.ARCo = bARTH.ARCo 
				and bARTL.Mth = bARTH.Mth and bARTL.ARTrans = bARTH.ARTrans
		where bARTL.ARCo=@toco
		group by bARTL.ARCo, bARTL.ApplyMth, bARTL.ApplyTrans, bARTL.ApplyLine
		having (sum( bARTL.Amount)<>0 or sum(bARTL.TaxAmount)<>0 or sum(bARTL.Retainage)<>0)) 
		as t 
		on t.ARCo=l.ARCo and t.ApplyTrans=l.ARTrans and t.ApplyMth=l.Mth
            and t.ApplyLine=l.ARLine
where ph.Description='Conversion Balance'
	and l.ARCo=@toco
order by ph.ARCo, ph.Customer, ph.Mth, ph.ARTrans;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bARTL enable trigger all;

return @@error



GO
