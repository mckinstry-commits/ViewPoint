SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE proc [dbo].[cvsp_CMS_AR_Receipts] (@fromco1 smallint, @fromco2 smallint,@fromco3 smallint,@toco smallint,		 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as
/**	

=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AR Receipts (ARTH/ARTL) 
	Created :	09.18.09
	Created By:	JJH
	Revisions:	
		1. Prior SP wasn't separating multiple payments for a single invoice.
				This inserts the payments into a temp table then updates ARTH and ARTL with the info.
		2. Added link to Sequence03 and Sequence 05 between ARTL and CMS tables. 4/16/10
		3. 6/22/2012 BTC - Corrected CM Deposit to be right justified 10 characters
		4. 6/22/2012 BTC - Added ARTrans to Partition By on AR Line so that lines are numbered per ARTrans.
**/

set @errmsg=''
set @rowcount=0


-- get defaults from HQCO
declare @CustGroup smallint, @TaxGroup tinyint
select @CustGroup=CustGroup, @TaxGroup=TaxGroup
from bHQCO
where HQCo=@toco;
 
--get defaults from ARCO
declare @CMCo smallint, @JCCo smallint, @CMAcct int, @GLCo smallint
select @CMCo=CMCo, @JCCo=JCCo, @CMAcct=CMAcct, @GLCo=GLCo from bARCO
where ARCo=@toco;

alter table bARTH disable trigger all;
ALTER Table bARTL disable trigger all;

-- delete existing trans
-- Deleted in different procedure.

create table #ARReceipts
	(ARCo		tinyint				null,
	Mth			smalldatetime		null,
	ARTrans		int					null,
	ARLine		int					null,
	RecType		int					null,
	LineType	varchar(1)			null,
	LineDesc	varchar(30)			null,
	GLCo		tinyint				null,
	GLAcct		varchar(30)			null,
	TaxGroup	tinyint				null,
	TaxCode		varchar(10)			null,
	Amount		decimal(12,2)		null,
	Retainage	decimal(12,2)		null,
	TaxBasis	decimal(12,2)		null,
	TaxAmount	decimal(12,2)		null,
	ApplyMth	smalldatetime		null,
	ApplyTrans	int					null,
	ApplyLine	int					null,
	JCCo		tinyint				null,
	Contract	varchar(10)			null,
	Item		varchar(16)			null,
	ActDate		smalldatetime		null,
	HeaderDesc	varchar(20)			null,
	CustGroup	tinyint				null,
	Customer	int					null,
	InvDate		smalldatetime		null,
	CheckNo		varchar(20)			null,
	Source		varchar(20)			null,
	TransDate	smalldatetime		null,
	CheckDate	smalldatetime		null,
	CMCo		tinyint				null,
	CMAcct		int					null,
	CMDeposit	varchar(15)			null,
	CreditAmt	numeric(12,2)		null,
	udARTOPCID	bigint				null,
	udPAYARTOPCID	bigint			null,
	udPAYARTOPDID	bigint			null,
	udCheckNo		varchar(20)		null,
	CMSContract	varchar(20)			null,
	RETNINVOICE varchar(1)			null,
	udCGCTable varchar(10)			null,
	udCGCTableID decimal(12,0)		 null)


insert into #ARReceipts	

select @toco
	, D.udPaidMth
	, ARTrans=isnull(H.LastTrans,1)+ROW_NUMBER() Over (partition by @toco, D.udPaidMth
			ORDER BY @toco, D.udPaidMth, D.udARTOPCID, D.CUSTOMERNUMBER)
	, ARLine=ROW_NUMBER ( ) OVER (partition by @toco, D.udPaidMth
		order by @toco, D.udPaidMth, D.ARTOPDID )
	, RecType=1
	, LineType=L.LineType
	, Description=D.DESC20A
	, GLCo=@GLCo
	, GLAcct=newGLAcct
	, TaxGroup=@TaxGroup
	, TaxCode=L.TaxCode
	, Amount=(D.AAMPD)
	, Retainage=D.RETAINEDAMT 
	, TaxBasis=0
	, TaxAmount=case when L.TaxAmount<> 0 then D.AAMPD else 0 end
	, ApplyMth=L.ApplyMth
	, ApplyTrans=L.ApplyTrans
	, ApplyLine=L.ApplyLine
	, JCCo=L.JCCo
	, Contract=L.Contract
	, Item=L.Item
	, ActDate=convert(smalldatetime,(substring(convert(nvarchar(max),D.PAIDDATE),1,4)
		+'/'+substring(convert(nvarchar(max),D.PAIDDATE),5,2) 
		+'/'+substring(convert(nvarchar(max),D.PAIDDATE),7,2)))
	, HeaderDesc=C.INVDESC
	, @CustGroup
	, Customer=C.CUSTOMERNUMBER
	, InvDate=convert(smalldatetime,(substring(convert(nvarchar(max),C.INVOICEDATE),1,4)+'/'+
			substring(convert(nvarchar(max),C.INVOICEDATE),5,2) +'/'+substring(convert(nvarchar(max),C.INVOICEDATE),7,2)))
	, CheckNo=case when D.CHECKNUMBER=0 then convert(nvarchar(max),'WIRE')
		 + convert(nvarchar(max),Row_number() Over 
		 (partition by  C.CUSTOMERNUMBER order by C.CUSTOMERNUMBER, D.CHECKNUMBER, C.udPaidMth, C.ARTOPCID)) 
		  else convert(nvarchar(max),D.CHECKNUMBER) end 
	, Source='AR Receipt'
	, TransDate=convert(smalldatetime,(substring(convert(nvarchar(max),D.CASHRCPTSDATE/*C.PAIDDATE*/),1,4)+'/'
		  +substring(convert(nvarchar(max),D.CASHRCPTSDATE/*C.PAIDDATE*/),5,2) +'/'
		  +substring(convert(nvarchar(max),D.CASHRCPTSDATE/*C.PAIDDATE*/),7,2)))
	, CheckDate=convert(smalldatetime,(substring(convert(nvarchar(max),D.CASHRCPTSDATE/*C.PAIDDATE*/),1,4)+'/'
		  +substring(convert(nvarchar(max),D.CASHRCPTSDATE/*C.PAIDDATE*/),5,2) +'/'
		  +substring(convert(nvarchar(max),D.CASHRCPTSDATE/*C.PAIDDATE*/),7,2)))
	, CMCo =@CMCo
	, CMAcct =@CMAcct
	, CMDeposit=D.CASHRCPTSDATE/*C.PAIDDATE*/
	, CreditAmt=(D.AAMPD)
	, udARTOPCID=D.udARTOPCID
	, udPAYARTOPCID=(C.ARTOPCID)
	, udPAYARTOPDID=(D.ARTOPDID)
	, udCheckNo=C.CHECKNUMBER
	, CMSContract=D.CONTRACTNO
	, RETNINVOICE = C.RETNINVOICE
	, udCGCTable='ARTOPD'
	, udCGCTableID=D.ARTOPDID
	
from CV_CMS_SOURCE.dbo.ARTOPD D
	join CV_CMS_SOURCE.dbo.ARTOPC C ON D.COMPANYNUMBER=C.COMPANYNUMBER and C.ARTOPCID=D.udARTOPCID
	join bARTL L on L.ARCo=@toco and L.udARTOPDID=D.ARTOPDID and L.udSeqNo=D.SEQUENCENO03
			and L.udSeqNo05=D.SEQUENCENO05 --L.udRecCode=D.RECORDCODE
	left join Viewpoint.dbo.budxrefGLAcct ON Company=@toco and D.GENLEDGERACCT=oldGLAcct
	left join HQTC H on H.Co=@toco and  D.udPaidMth=H.Mth and H.TableName = 'bARTH'
where D.PAIDDATE <> 0
	and D.COMPANYNUMBER in (@fromco1,@fromco2,@fromco3)
order by D.CUSTOMERNUMBER, L.Contract, L.ApplyMth, L.ApplyTrans, L.ApplyLine

-- add new trans
BEGIN TRAN
BEGIN TRY

insert bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, JCCo, CheckNo, Source, 
TransDate, CheckDate, Description, CMCo, CMAcct, CMDeposit, CreditAmt,   
EditTrans, ExcludeFC, FinanceChg, udARTOPCID, udPAYARTOPCID, udPAYARTOPDID, udCheckNo, udCMSContract,udMiscPayYN, 
udSource,udConv,udCGCTable,udCGCTableID)

select ARCo
	, Mth
	, max(ARTrans)
	, ARTransType='P'
	, CustGroup
	, Customer
	, max(JCCo)
	, CheckNo
	, max(Source)
	, TransDate
	, max(CheckDate)
	, max(HeaderDesc)
	, max(CMCo)
	, max(CMAcct)
	, RIGHT(space(10) + convert(varchar(max), max(CMDeposit)), 10)
	, sum(CreditAmt)
	, EditTrans='Y'
	, ExcludeFC='N'
	, FinanceChg=0
	, max(udARTOPCID)
	, max(udPAYARTOPCID)
	, max(udPAYARTOPDID)
	, max(udCheckNo)
	, udCMSContract=CMSContract
	, udMiscPayYN=case when (CMSContract=0 or CMSContract=' ') then 'Y' else 'N' end
	, udSource ='AR_Receipts'
	, udConv='Y'
	, max(udCGCTable)
	,max(udCGCTableID)
from #ARReceipts 
group by ARCo, Mth,CustGroup, Customer, CheckNo, TransDate, CMSContract
order by ARCo, Mth, Customer;




INSERT bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode, Amount, 
TaxBasis, TaxAmount, RetgPct, Retainage, DiscOffered, TaxDisc, DiscTaken, ApplyMth, ApplyTrans, ApplyLine, 
JCCo, Contract, Item, ActDate, PurgeFlag, FinanceChg, RetgTax, udSource,udConv,udCGCTable,udCGCTableID)

select r.ARCo
	, r.Mth
	, (t.ARTrans)
	, ARLine=ROW_NUMBER ( ) OVER (partition by r.ARCo, r.Mth, t.ARTrans	order by r.Item )
	, RecType=1
	, LineType=r.LineType
	, Description=(r.LineDesc)
	, GLCo=r.ARCo
	, GLAcct=(r.GLAcct)
	, TaxGroup=(r.TaxGroup)
	, TaxCode=(r.TaxCode)
	, Amount= (r.Amount*-1)
	, TaxBasis=0 --L.TaxBasis
	, TaxAmount=(case when r.TaxAmount<> 0 then r.Amount*-1 else 0 end)
	, 0 as RetgPct
	, Retainage=0--case when RETNINVOICE = 'Y' then 0 else r.Retainage*-1 end
	, 0 as DiscOffered
	, 0 as TaxDisc
	, 0 as DiscTaken
	, ApplyMth=r.ApplyMth
	, ApplyTrans=r.ApplyTrans
	, ApplyLine=r.ApplyLine
	, JCCo=r.JCCo
	, Contract=r.Contract
	, Item=r.Item
	, r.ActDate
	, PurgeFlag='Y'
	, FinanceChg=0
	, RetgTax=0
	, udSource ='AR_Receipts'
	, udConv='Y'
	, udCGCTable
	, udCGCTableID
from #ARReceipts r
	join (select ARCo, Mth, ARTrans=max(ARTrans), CustGroup, Customer,
			CheckNo, TransDate
			from #ARReceipts 
			group by ARCo, Mth, CustGroup, Customer,CheckNo, TransDate) 
			as t 
			on t.ARCo=r.ARCo and t.Mth=r.Mth and t.CustGroup=r.CustGroup
				and t.Customer=r.Customer
				and t.CheckNo=r.CheckNo 
				and t.TransDate=r.TransDate

order by r.ARCo, r.Mth, r.Customer;





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
