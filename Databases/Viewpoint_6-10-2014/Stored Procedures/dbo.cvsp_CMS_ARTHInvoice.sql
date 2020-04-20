SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




CREATE proc [dbo].[cvsp_CMS_ARTHInvoice] (@fromco1 smallint, @fromco2 smallint, @fromco3 smallint, @toco smallint, 
		@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AR Invoices Header (ARTH) 
	Created:	9.2.09
	Created By:	JRE    
	Revisions:	1. 6/22/2012 BTC - Set Contract to null if JOBNUMBER='' 
				2. 10/3/2013 BTC - Added Job Cross Reference to get Contract number
**/
set @errmsg=''
set @rowcount=0

declare 
	@fromco_1 int = @fromco1,
	@fromco_2 int = @fromco2,
	@fromco_3 int = @fromco3,
	@VPtoco int		= @toco

-- get groups from HQCO
declare @CustGroup tinyint
select @CustGroup=CustGroup 
from bHQCO 
where HQCo=@VPtoco

--get defaults from ARCO
declare @JCCo tinyint
select @JCCo=JCCo 
from bARCO
where ARCo=@VPtoco;

--get defaults from Customer Defaults
--PayTerms
declare @defaultPayTerms varchar(5), @defaultRecType tinyint
select @defaultPayTerms=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@VPtoco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PayTerms' and a.TableName='bARTH';

--Receivable Type
select @defaultRecType=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@VPtoco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='RecType' and a.TableName='bARTH';

--Declare variables for functions
Declare @JobFormat varchar(30)
Set @JobFormat =  (Select InputMask from vDDDTc where Datatype = 'bJob');


alter table bARTH disable trigger all;

-- delete existing trans
BEGIN tran
delete from bARTH where ARCo=@VPtoco
	--and udConv = 'Y';
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY

  
insert bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, CustRef, RecType,
	JCCo, Contract, Invoice,  Source, TransDate, 
	DueDate, DiscDate, CheckDate, Description, CreditAmt, PayTerms, AppliedMth, AppliedTrans, Invoiced, Paid, Retainage, 
	DiscTaken, AmountDue, PayFullDate, EditTrans,  ExcludeFC, FinanceChg, udARTOPCID, PurgeFlag, udSource,udConv
	,udCGCTable,udCGCTableID)

select ARCo         = @VPtoco
	, Mth           = case max(C.JOURNALDATE) 
					  when 0 
					  then null 
					  else
				      convert(smalldatetime,(substring(convert(nvarchar(max),C.JOURNALDATE),1,4)
				                        +'/'+substring(convert(nvarchar(max),C.JOURNALDATE),5,2) 
				                        +'/'+ '01')) 
		              end
	, ARTrans       = Row_Number() Over(Partition by 
							   convert(smalldatetime,(substring(convert(nvarchar(max),C.JOURNALDATE),1,4)
								  				 +'/'+substring(convert(nvarchar(max),C.JOURNALDATE),5,2) 
												 +'/'+ '01'))
					  order by convert(smalldatetime,(substring(convert(nvarchar(max),C.JOURNALDATE),1,4)
							                     +'/'+substring(convert(nvarchar(max),C.JOURNALDATE),5,2) 
							                     +'/'+ '01')))
	, ARTransType   = case when max(C.CURRGLACCTFORADJ) <> 0 then 'A' else 'I' end
	, CustGroup     = @CustGroup
	, Customer      = max(Cust.NewCustomerID)     --max(CUSTOMERNUMBER)
	, CustRef       = max(C.REFERENCENO07)
	, RecType       = @defaultRecType
	, JCCo          = @JCCo
	, Contract      = xj.VPJobExt
					  --case when JOBNUMBER = '' then null else dbo.bfMuliPartFormat(RTRIM(JOBNUMBER),@JobFormat) end
	, Invoice       = CASE WHEN ltrim(rtrim(max(C.INVDESC))) = 'SERVICEALLIANCE' then right(SPACE(10)+ 'S' + RTRIM(C.INVOICENO) + substring(CAST(max(C.INVOICEDATE) AS varchar(10)),3,2),10) else SPACE(10-DATALENGTH(rtrim(C.INVOICENO)))+RTRIM(C.INVOICENO) end--INVOICENO 
	, Source        = 'AR Invoice'
	, TransDate     = convert(smalldatetime,(substring(convert(nvarchar(max),C.INVOICEDATE),1,4) +'/'
				                           + substring(convert(nvarchar(max),C.INVOICEDATE),5,2) +'/'
				                           + substring(convert(nvarchar(max),C.INVOICEDATE),7,2))) 
	, DueDate       = case max(C.DUEDATE) 
	                  when 0 
	                  then null 
	                  else
				         convert(smalldatetime,(substring(convert(nvarchar(max),max(C.DUEDATE)),1,4) +'/'+
				                                substring(convert(nvarchar(max),max(C.DUEDATE)),5,2) +'/'+
				                                substring(convert(nvarchar(max),max(C.DUEDATE)),7,2)))  
			          end
	, DiscDate      = convert(smalldatetime,(substring(convert(nvarchar(max),C.INVOICEDATE),1,4) +'/'
				                           + substring(convert(nvarchar(max),C.INVOICEDATE),5,2) +'/'
				                           + substring(convert(nvarchar(max),C.INVOICEDATE),7,2)))
	, CheckDate     = NULL
	, Description   = max(C.INVDESC)
	, CreditAmt     = isnull( 
							case 
							when max(C.CURRGLACCTFORADJ) <> 0 
							then sum(C.INVAMT) 
							else 0 
							end
							,0)
	, PayTerms      = @defaultPayTerms
	, AppliedMth    = null-- UPDATED below
	, AppliedTrans  = null  -- UPDATED below
	, Invoiced      = ISNULL(sum(C.INVAMT),0)
						--case when max(RETNINVOICE) = 'Y' then isnull(sum(INVAMT),0) else 
						--isnull(sum(INVAMT),0) + isnull(sum(RETAINEDAMT),0) end
	, Paid          = 0
	, Retainage     = isnull(sum(C.RETAINEDAMT),0) 
	, DiscTaken     = isnull(sum(C.DISCOUNTAMT),0)
	, AmountDue     = case
	                  when max(C.CURRGLACCTFORADJ) = 0 
	                  then isnull(sum(C.INVAMT),0) 
	                  else 
	                  0  
	                  end 
	, PayFullDate   = null 
	, EditTrans     = 'Y' 
	, ExcludeFC     = 'N'
	, FinanceChg    = 0
	, udARTOPCID    = C.ARTOPCID
	, PurgeFlag     = 'N'
	, udSource      = 'ARTHInvoice'
	, udConv        = 'Y'
	, udCGCTable    = 'ARTOPC'
	, udCGCTableID  = C.ARTOPCID
	
FROM CV_CMS_SOURCE.dbo.ARTOPC C with (nolock)
JOIN Viewpoint.dbo.budxrefARCustomer Cust
	on Cust.Company        = @CustGroup
	and Cust.OldCustomerID = C.CUSTOMERNUMBER

--JOIN [MCK_MAPPING_DATA ].[dbo].[McKCGCActiveJobsForConversion2] aj
--	on	aj.GCONO = C.COMPANYNUMBER 
--	and	aj.GDVNO = C.DIVISIONNUMBER 
--	and	aj.GJBNO = C.JOBNUMBER
--	and	aj.GSJNO = C.SUBJOBNUMBER
	
JOIN Viewpoint.dbo.budxrefJCJobs xj
	on	xj.COMPANYNUMBER = C.COMPANYNUMBER 
	and	xj.DIVISIONNUMBER = C.DIVISIONNUMBER 
	and	xj.JOBNUMBER = C.JOBNUMBER
	and	xj.SUBJOBNUMBER = C.SUBJOBNUMBER
	and xj.VPJob is not null
WHERE C.COMPANYNUMBER in (@fromco_1,@fromco_2,@fromco_3) 
	  and (C.JOURNALDATE <> 0 or C.DUEDATE <> 0)
	  
GROUP BY  xj.VPJobExt
		, C.JOURNALDATE
		, C.INVOICEDATE
		, C.INVOICENO
		, C.ARTOPCID;

select @rowcount=@@rowcount;




-- set the applied trans for Invoices - invoice are applied to themselves
UPDATE bARTH 
SET AppliedTrans   = ARTrans
  , AppliedMth     = Mth 
  
WHERE ARTransType  = 'I' 
	and       ARCo = @VPtoco;

-- set the applied trans for Adjustments - adjustments are applied to invoices
UPDATE bARTH 
SET AppliedTrans   = INV.ARTrans
      , AppliedMth = INV.Mth 
      
FROM bARTH 
JOIN bARTH INV 
	on INV.ARCo      = bARTH.ARCo 
	and INV.Customer = bARTH.Customer
	and INV.Contract = bARTH.Contract
	and INV.Invoice  = bARTH.Invoice 
	and INV.Mth      = bARTH.Mth
		
WHERE INV.ARTransType                 = 'I' 
	and bARTH.ARTransType             = 'A' 
	and isnull(bARTH.AppliedTrans,'')<>isnull(INV.ARTrans,'')  
	and bARTH.ARCo                    = @VPtoco;

-- if there are any adjustment without a matching invoice
-- then make it an invoice
UPDATE bARTH 
SET   ARTransType  = 'I'
	, AppliedTrans = ARTrans
	, AppliedMth   = Mth 
	
FROM bARTH
 
WHERE bARTH.ARTransType = 'A' 
    and AppliedTrans is null 
    and ARCo            = @VPtoco;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bARTH enable trigger all;

return @@error









GO
