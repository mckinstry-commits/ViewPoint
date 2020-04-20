
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_ARTLInvoice] 
	(@fromco smallint, @toco smallint, @errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AR Invoices Lines (ARTL)
	Created on:	9.2.09	
	Author:     JRE
	Revision:	1. 04/22/09 if the sum of all the taxamounts on an invoice =0 then 0 out the tax basis - JRE
				2. 05/05/09 null taxcode if taxamout=0 and taxbasis=0 and taxcode<> null - JRE
				3. 05/19/09 set correc REC type on adjustments- JRE
				4. 10/03/13 Added Job Cross Reference for contract - BTC
*/


set @errmsg='';
set @rowcount=0;

-- get defaults from HQCO
DECLARE  @CustGroup tinyint
		, @TaxGroup tinyint
		
SELECT @CustGroup=CustGroup, 
       @TaxGroup=TaxGroup 
FROM bHQCO 
WHERE HQCo=@toco

--get customer defaults
--Pay Terms
DECLARE @defaultPayTerms varchar(5)

SELECT @defaultPayTerms=isnull(b.DefaultString,a.DefaultString) 

FROM Viewpoint.dbo.budCustomerDefaults a
	FULL outer join Viewpoint.dbo.budCustomerDefaults b 
		on b.Company    = @fromco 
		and a.TableName = b.TableName 
		and a.ColName   = b.ColName
	
WHERE	a.Company   = 0 
	and a.ColName   = 'PayTerms' 
	and a.TableName = 'bARTH';


--Receivable Type
DECLARE @defaultRecType tinyint

SELECT @defaultRecType=isnull(b.DefaultNumeric,a.DefaultNumeric)
 
FROM Viewpoint.dbo.budCustomerDefaults a
FULL outer join Viewpoint.dbo.budCustomerDefaults b 
	ON  b.Company   = @fromco 
	AND a.TableName = b.TableName 
	AND a.ColName   = b.ColName
	
WHERE   a.Company   = 0 
	AND a.ColName   = 'RecType' 
	AND a.TableName = 'bARTH';


--declare variables for use in functions
DECLARE @JobFormat varchar(30)
SET @JobFormat =  (Select InputMask from vDDDTc where Datatype = 'bJob');



alter table bARTL disable trigger all;

--delete trans
delete bARTL where ARCo=@toco
	and udConv = 'Y';





-- add new trans
BEGIN TRAN
BEGIN TRY

INSERT bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode, Amount, 
	TaxBasis, TaxAmount, RetgPct, Retainage, RetgTax, DiscOffered, TaxDisc, DiscTaken, ApplyMth, ApplyTrans, ApplyLine, 
	JCCo, Contract, Item, ActDate, PurgeFlag, FinanceChg, udARTOPDID, udSeqNo, udSeqNo05,udCVStoredProc,udItemsBilled,
	udSource,udConv,udCGCTable,udCGCTableID)


select ARCo		     = A.ARCo
	, Mth		     = A.Mth
	, ARTrans        = A.ARTrans
	, ARLine         = ROW_NUMBER ( ) OVER (partition by A.Mth, A.ARTrans
				        order by  A.Mth
							, A.ARTrans
							, A.ARCo
							, D.SEQUENCENO05
							, D.CUSTOMERNUMBER
							, D.JOBNUMBER
							, D.CONTRACTNO
							, D.SUBJOBNUMBER
							, D.ITEMNUMBER
							, D.JOURNALDATE
							, D.INVOICEDATE
							, D.INVOICENO
							, D.ARTOPDID)
	, RecType        = @defaultRecType
	, LineType       = case when D.udItem <> '0' THEN 'C' ELSE 'O' END
	, Description    = D.DESC20A
	, GLCo           = @toco
	, GLAcct         = newGLAcct 
	, TaxGroup       = @TaxGroup 
	, TaxCode        = NULL
	, Amount         = D.INVAMT + D.RETAINEDAMT 
	, TaxBasis       = 0  
	, TaxAmount      = 0
    , RetgPct        = 0
	, Retainage      = D.RETAINEDAMT 
	, RetgTax        = 0
	, DiscOffered    = 0
	, TaxDisc        = 0
	, DiscTaken      = D.DISCOUNTAMT   
	, ApplyMth       = A.AppliedMth 
	, ApplyTrans     = A.AppliedTrans
	, ApplyLine      = 0 
	, JCCo           = @toco 
	, Contract       = xj.VPJob--D.udContract
	, Item           = D.udItem
	, ActDate        = convert(smalldatetime,(substring(convert(nvarchar(max),D.TRANSACTIONDATE),1,4)
	                                    +'/'+ substring(convert(nvarchar(max),D.TRANSACTIONDATE),5,2) 
		                                +'/'+ substring(convert(nvarchar(max),D.TRANSACTIONDATE),7,2)))
	, PurgeFlag      = 'N'
	, FinanceChg     = 0
	, udARTOPDID     = ARTOPDID
	, udSeqNo        = D.SEQUENCENO03
	, udSeqNo05      = D.SEQUENCENO05
	, udCVStoredProc = 'cvsp_CMS_ARTLInvoice'
	, udItemsBilled  = case when D.INVAMT <>0 then D.QTYBILLED else 0 end
	, udSource       = 'ARTLInvoice'
	, udConv         = 'Y'
	, udCGCTable     = 'ARTOPD'
	, udCGCTableID   = D.ARTOPDID

FROM CV_CMS_SOURCE.dbo.ARTOPD D

JOIN CV_CMS_SOURCE.dbo.ARTOPC C 
	ON  D.COMPANYNUMBER  = C.COMPANYNUMBER 
	AND C.ARTOPCID       = D.udARTOPCID
    AND C.CUSTOMERNUMBER = D.CUSTOMERNUMBER 
    AND C.INVOICENO      = D.INVOICENO
    
INNER JOIN CV_CMS_SOURCE.dbo.cvspMcKCGCActiveJobsForConversion jobs 
	ON	jobs.COMPANYNUMBER = D.COMPANYNUMBER
	AND jobs.JOBNUMBER     = D.JOBNUMBER
	and jobs.SUBJOBNUMBER  = D.SUBJOBNUMBER
	
JOIN Viewpoint.dbo.budxrefJCJobs xj
	on xj.COMPANYNUMBER = D.COMPANYNUMBER and xj.DIVISIONNUMBER = D.DIVISIONNUMBER and xj.JOBNUMBER = D.JOBNUMBER
		and xj.SUBJOBNUMBER = D.SUBJOBNUMBER
	    
JOIN bARTH A 
	ON  A.ARCo           = @toco 
	AND D.udARTOPCID     = A.udARTOPCID
	
LEFT join Viewpoint.dbo.budxrefGLAcct 
    ON  @fromco          = Company 
    AND D.GENLEDGERACCT  = oldGLAcct
	
WHERE D.COMPANYNUMBER=@fromco

ORDER BY  A.ARCo
		, A.Mth
		, D.CUSTOMERNUMBER
		, D.INVOICEDATE;

select @rowcount=@@rowcount

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bARTL enable trigger all;


WAITFOR DELAY '00:00:00.500';

return @@error

GO
