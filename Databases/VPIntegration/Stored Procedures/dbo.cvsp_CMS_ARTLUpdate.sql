SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_ARTLUpdate] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**

=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Update ARTL Lines (ARTL)
	Created:	4/22/09
	Created by: JIME
	Revisions:	1. 04/22/09 if the sum of all the taxamounts on an invoice =0 then 0 out the tax basis - JIME
				2. 05/05/09 null taxcode if taxamout=0 and taxbasis=0 and taxcode<> null - JIME
**/


set @errmsg='';
set @rowcount=0;

alter table bARTL disable trigger all;
alter table bARTH disable trigger all;

-- add new trans
BEGIN TRAN
BEGIN TRY

--------------------------------------------------------
-- set the apply line

update bARTL set ApplyLine=ARLine 
where  ApplyMth=Mth and ApplyTrans=ARTrans and ARCo=@toco;

select @rowcount=@@rowcount

--Apply Line is 0 on adjustments
update bARTL set ApplyLine=CalcLine
from bARTL
join (select ARCo, Mth, ARTrans, CalcLine=MIN(ARLine) 
	from bARTL 
	where ApplyMth=Mth and ApplyTrans=ARTrans
	group by ARCo, Mth, ARTrans) 
	as C
	on C.ARCo=bARTL.ARCo and C.Mth=bARTL.ApplyMth and C.ARTrans=bARTL.ApplyTrans
where bARTL.ApplyLine=0 and bARTL.ARCo=@toco;

 WAITFOR DELAY '00:00:00.500';

-- adjustments may have the wrong receivable type
-- set all adjustments to the invoice Receivable type
update bARTL set RecType=bARTL_Inv.RecType
from bARTL 
	join bARTH on bARTL.ARCo=bARTH.ARCo and bARTL.Mth=bARTH.Mth and bARTL.ARTrans=bARTH.ARTrans 
	join bARTL bARTL_Inv on bARTL.ARCo=bARTL_Inv.ARCo and bARTL.ApplyMth=bARTL_Inv.Mth and bARTL.ApplyLine=bARTL_Inv.ARLine and 
		bARTL.ApplyTrans=bARTL_Inv.ARTrans
where bARTL.RecType<>bARTL_Inv.RecType and ARTransType<>'P' and bARTL.ARCo=@toco;


-- adjustments may have the wrong receivable type
-- set all adjustments to the invoice Receivable type
update bARTH set RecType=bARTL.RecType 
from bARTH 
	join bARTL on bARTL.ARCo=bARTH.ARCo and bARTL.Mth=bARTH.Mth and bARTL.ARTrans=bARTH.ARTrans 
where bARTL.RecType<>bARTH.RecType and ARTransType<>'P' and bARTH.ARCo=@toco;

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
