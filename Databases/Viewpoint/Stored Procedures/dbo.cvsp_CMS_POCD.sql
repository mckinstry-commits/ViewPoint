
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



CREATE proc [dbo].[cvsp_CMS_POCD] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**

=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		PO Purchase Order Change Orders
	Created:	09.02.10
	Created by:	JJH
	Revisions:	
		1. 06/15/2012 BTC - Right justified (10 characters) the ChangeOrder field.
		2. 06/15/2012 BTC - Changed to pull UM from POIT
		3. 06/15/2012 BTC - Modified formulas to post zero units for LS POItems.
		4. 06/15/2012 BTC - Modified to populate Change to BO Units & Cost fields.			
*/

set @errmsg='';
set @rowcount=0;

ALTER Table bPOCD disable trigger all;

--delete trans
delete bPOCD where POCo=@toco
	and udConv = 'Y';


-- add new trans
BEGIN TRAN
BEGIN TRY


insert bPOCD 
	(POCo, Mth, POTrans, PO, POItem, ChangeOrder, ActDate, Description, UM, ChangeCurUnits, CurUnitCost, ECM,
		ChangeCurCost, ChangeBOUnits, ChangeBOCost, BatchId, PostedDate, Seq, ChgTotCost, PurgeYN, ChgToTax,
		POCONum, udSource, udConv, udCGCTable/*, udCGCTableID*/)

select 
	  POCo = @toco
	, Mth = c.udMth
	, POTrans = Row_Number() Over(Partition by c.udMth 
			order by c.PONUMBER, c.POITEMT, c.CPOCG, c.CHANGEORDDATE)
	, PO=c.PONUMBER
	, POItem=c.POITEMT
	, ChangeOrder=right(space(10) + convert(varchar(max),c.CPOCG), 10)
	, ActDate=substring(convert(nvarchar(max),c.CHANGEORDDATE),5,2) + '/' 
				+ substring(convert(nvarchar(max),c.CHANGEORDDATE),7,2) + '/'
				+ substring(convert(nvarchar(max),c.CHANGEORDDATE),1,4)
	, Description=c.DESCRIPTION1
	, UM=it.UM
	, ChangeCurUnits=case when it.UM='LS' then 0 else c.QTYORDERED end
	, CurUnitcost=case when it.UM='LS' then 0 else c.UNITCST end
	, ECM=case
			when it.UM='LS' then null 
			when c.PRICECODE in ('E','C','M') then c.PRICECODE
			else 'E' end
	, ChangeCurCost=c.COSTDOLLARAMT
	, ChangeBOUnits=case when it.UM='LS' then 0 else c.QTYORDERED end
	, ChangeBOCost=c.COSTDOLLARAMT
	, BatchID=0
	, PostedDate=substring(convert(nvarchar(max),c.CHANGEORDDATE),5,2) + '/'
			+ substring(convert(nvarchar(max),c.CHANGEORDDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),c.CHANGEORDDATE),1,4)
	, Seq=Row_Number() Over(Partition by c.PONUMBER, c.POITEMT order by c.CPOCG)
	, ChgTotCost=c.COSTDOLLARAMT
	, PurgeYN='Y'
	, ChgToTax=0
	, POCONum = ROW_NUMBER () over (Partition by c.PONUMBER, c.POITEMT order by c.CPOCG)
	, udSource ='POCD'
	, udConv='Y'
	, udCGCTable='POTCDT'
	--, udCGCTableID=c.udPOTCDTID
--select *
from CV_CMS_SOURCE.dbo.POTCDT c

join CV_CMS_SOURCE.dbo.POTMDT d
	on d.COMPANYNUMBER=c.COMPANYNUMBER 
	and d.PONUMBER=c.PONUMBER 
	and d.POITEMT=c.POITEMT 
	and d.SEQUENCENO02=c.SEQUENCENO02
	
join bPOIT it
	on it.PO=c.PONUMBER 
	and it.POItem=c.POITEMT 
	and it.POCo=@fromco
	
where c.COMPANYNUMBER=@fromco;

select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


ALTER Table bPOCD enable trigger all;

return @@error



GO
