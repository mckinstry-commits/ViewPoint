SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_ARTHUpdateFromLines] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Update ARTH Header from Lines 
	Created:	April 7, 2009	
	Created By: Jim Emery
	Revisions:	none
**/


set @errmsg=''
set @rowcount=0


-- get defaults from HQCO
declare @VendorGroup smallint, @TaxGroup smallint,@CustGroup smallint
select @VendorGroup=VendorGroup, @CustGroup=CustGroup,@TaxGroup=TaxGroup 
from bHQCO where HQCo=@toco

--get customer defaults
declare @defaultOverrideMinAmtYN varchar(1)
select @defaultOverrideMinAmtYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName 
			and a.ColName=b.ColName
where a.Company=0 and a.ColName='@OverrideMinAmtYN' and a.TableName='xxxx';


alter table bARTH disable trigger all;;

-- delete existing trans
-- no deltes necessary

-- add new trans
BEGIN TRAN
BEGIN TRY

--Zero out transaction headers
update bARTH set Invoiced=0, Paid=0, Retainage=0, FinanceChg=0,DiscTaken=0, AmountDue=0,
     PayFullDate=null
from bARTH where ARCo=@toco;


--Update header fields based on lines
update bARTH set Invoiced=sInvoiced
	, Paid=sPaid
	, Retainage=sRetainage
	, DiscTaken=sDiscTaken
	, AmountDue=sInvoiced-sRetainage-sPaid
	, PayFullDate=case when sInvoiced-sRetainage-sPaid=0 then sPayFullDate else null end
from bARTH
   join (select sARCo=bARTL.ARCo, sApplyMth=bARTL.ApplyMth, sApplyTrans=bARTL.ApplyTrans,
				sInvoiced=sum(case when ARTransType in ('P','M') then 0 else Amount end),
				sPaid=-sum(case when ARTransType in ('P','M') then Amount else 0 end),
				sRetainage=sum(bARTL.Retainage),
				sDiscTaken=sum(bARTL.DiscTaken),
				sPayFullDate=max(bARTH.TransDate) 
		from bARTL with(nolock)
			join bARTH with(nolock) on bARTH.ARCo=bARTL.ARCo and bARTH.Mth=bARTL.Mth and bARTH.ARTrans=bARTL.ARTrans
		group by bARTL.ARCo, bARTL.ApplyMth, bARTL.ApplyTrans) 
		as s 
		on bARTH.ARCo=sARCo and bARTH.Mth=sApplyMth and bARTH.ARTrans=sApplyTrans
where bARTH.ARCo=@toco and bARTH.ARTransType in ('I','M','P','C','R','A');
    
update bARTH set PayFullDate=TransDate
from bARTH with(nolock)
where bARTH.ARCo=@toco and PayFullDate is null and AmountDue=0 and Retainage=0;

update bARTH
set RecType=mRecType
from bARTH
	join (select ARCo, Mth, ARTrans, mRecType=max(RecType) 
			from bARTL 
			where RecType<>1 and bARTL.ARCo=@toco
			group by ARCo, Mth, ARTrans) 
			as bARTL
			on bARTH.ARCo=bARTL.ARCo and bARTH.Mth=bARTL.Mth and bARTH.ARTrans=bARTL.ARTrans
where bARTH.ARCo=@toco and RecType<>mRecType;

update bARTL
set RecType=bARTH.RecType
from bARTL
	join bARTH on bARTH.ARCo=bARTL.ARCo and bARTH.Mth=bARTL.Mth and bARTH.ARTrans=bARTL.ARTrans
where bARTL.ARCo=@toco and bARTL.RecType<>bARTH.RecType;

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
