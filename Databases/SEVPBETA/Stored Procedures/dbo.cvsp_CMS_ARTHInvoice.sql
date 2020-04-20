SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




CREATE proc [dbo].[cvsp_CMS_ARTHInvoice] (@fromco smallint, @toco smallint, 
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
**/
set @errmsg=''
set @rowcount=0


-- get groups from HQCO
declare @CustGroup tinyint
select @CustGroup=CustGroup 
from bHQCO 
where HQCo=@toco

--get defaults from ARCO
declare @JCCo tinyint
select @JCCo=JCCo 
from bARCO
where ARCo=@toco;

--get defaults from Customer Defaults
--PayTerms
declare @defaultPayTerms varchar(5), @defaultRecType tinyint
select @defaultPayTerms=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PayTerms' and a.TableName='bARTH';

--Receivable Type
select @defaultRecType=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='RecType' and a.TableName='bARTH';

--Declare variables for functions
Declare @JobFormat varchar(30)
Set @JobFormat =  (Select InputMask from vDDDTc where Datatype = 'bJob');


alter table bARTH disable trigger all;

-- delete existing trans
BEGIN tran
delete from bARTH where ARCo=@toco
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

select ARCo         = @toco
	, Mth           = case max(JOURNALDATE) 
					  when 0 
					  then null 
					  else
				      convert(smalldatetime,(substring(convert(nvarchar(max),JOURNALDATE),1,4)
				                        +'/'+substring(convert(nvarchar(max),JOURNALDATE),5,2) 
				                        +'/'+ '01')) 
		              end
	, ARTrans       = Row_Number() Over(Partition by 
							   convert(smalldatetime,(substring(convert(nvarchar(max),JOURNALDATE),1,4)
								  				 +'/'+substring(convert(nvarchar(max),JOURNALDATE),5,2) 
												 +'/'+ '01'))
					  order by convert(smalldatetime,(substring(convert(nvarchar(max),JOURNALDATE),1,4)
							                     +'/'+substring(convert(nvarchar(max),JOURNALDATE),5,2) 
							                     +'/'+ '01')))
	, ARTransType   = case when max(CURRGLACCTFORADJ) <> 0 then 'A' else 'I' end
	, CustGroup     = @CustGroup
	, Customer      = max(Cust.NewCustomerID)     --max(CUSTOMERNUMBER)
	, CustRef       = max(REFERENCENO07)
	, RecType       = @defaultRecType
	, JCCo          = @JCCo
	, Contract      = case
		              when JOBNUMBER = '' 
		              then null
		              else dbo.bfMuliPartFormat(RTRIM(JOBNUMBER),@JobFormat) 
		              end
	, Invoice       = SPACE(10-DATALENGTH(rtrim(INVOICENO)))+RTRIM(INVOICENO)--INVOICENO
	, Source        = 'AR Invoice'
	, TransDate     = convert(smalldatetime,(substring(convert(nvarchar(max),INVOICEDATE),1,4) +'/'
				                           + substring(convert(nvarchar(max),INVOICEDATE),5,2) +'/'
				                           + substring(convert(nvarchar(max),INVOICEDATE),7,2))) 
	, DueDate       = case max(DUEDATE) 
	                  when 0 
	                  then null 
	                  else
				         convert(smalldatetime,(substring(convert(nvarchar(max),max(DUEDATE)),1,4) +'/'+
				                                substring(convert(nvarchar(max),max(DUEDATE)),5,2) +'/'+
				                                substring(convert(nvarchar(max),max(DUEDATE)),7,2)))  
			          end
	, DiscDate      = convert(smalldatetime,(substring(convert(nvarchar(max),INVOICEDATE),1,4) +'/'
				                           + substring(convert(nvarchar(max),INVOICEDATE),5,2) +'/'
				                           + substring(convert(nvarchar(max),INVOICEDATE),7,2)))
	, CheckDate     = NULL
	, Description   = max(INVDESC)
	, CreditAmt     = isnull( 
							case 
							when max(CURRGLACCTFORADJ) <> 0 
							then sum(INVAMT) 
							else 0 
							end
							,0)
	, PayTerms      = @defaultPayTerms
	, AppliedMth    = NULL  -- UPDATED below
	, AppliedTrans  = NULL  -- UPDATED below
	, Invoiced      = ISNULL(sum(INVAMT),0)
						--case when max(RETNINVOICE) = 'Y' then isnull(sum(INVAMT),0) else 
						--isnull(sum(INVAMT),0) + isnull(sum(RETAINEDAMT),0) end
	, Paid          = 0
	, Retainage     = isnull(sum(RETAINEDAMT),0) 
	, DiscTaken     = isnull(sum(DISCOUNTAMT),0)
	, AmountDue     = case
	                  when max(CURRGLACCTFORADJ) = 0 
	                  then isnull(sum(INVAMT),0) 
	                  else 
	                  0  
	                  end 
	, PayFullDate   = null 
	, EditTrans     = 'Y' 
	, ExcludeFC     = 'N'
	, FinanceChg    = 0
	, udARTOPCID    = ARTOPCID
	, PurgeFlag     = 'N'
	, udSource      = 'ARTHInvoice'
	, udConv        = 'Y'
	, udCGCTable    = 'ARTOPC'
	, udCGCTableID  = ARTOPCID
	
FROM CV_CMS_SOURCE.dbo.ARTOPC C with (nolock)
JOIN Viewpoint.dbo.budxrefARCustomer Cust
	on Cust.Company        = @fromco
	and Cust.OldCustomerID = C.CUSTOMERNUMBER

WHERE COMPANYNUMBER=@fromco 
	  and (JOURNALDATE <> 0 or DUEDATE <> 0)
	  
GROUP BY  COMPANYNUMBER
		, JOBNUMBER
		, SUBJOBNUMBER
		, JOURNALDATE
		, INVOICEDATE
		, INVOICENO
		, ARTOPCID;

select @rowcount=@@rowcount;




-- set the applied trans for Invoices - invoice are applied to themselves
UPDATE bARTH 
SET AppliedTrans   = ARTrans
  , AppliedMth     = Mth 
  
WHERE ARTransType  = 'I' 
	and       ARCo = @toco;

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
	and bARTH.ARCo                    = @toco;

-- if there are any adjustment without a matching invoice
-- then make it an invoice
UPDATE bARTH 
SET   ARTransType  = 'I'
	, AppliedTrans = ARTrans
	, AppliedMth   = Mth 
	
FROM bARTH
 
WHERE bARTH.ARTransType = 'A' 
    and AppliedTrans is null 
    and ARCo            = @toco;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bARTH enable trigger all;

return @@error


GO
