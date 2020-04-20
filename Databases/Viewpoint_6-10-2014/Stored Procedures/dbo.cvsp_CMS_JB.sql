SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------





CREATE proc [dbo].[cvsp_CMS_JB] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**

=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		JB Invoices (JBIN, JBIT, JBIS, JBCC, JBCX)
	Created:	10.28.09
	Created by:	JJH
	Rev:		1. Added code to pick up the items that have not been billed but the contract has billings on other items - JH
*/


set @errmsg='';
set @rowcount=0;

--get default from Customer Defaults
declare @defaultPayTerms varchar(1)
select @defaultPayTerms=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PayTerms' and a.TableName='bARTH';


ALTER table bJBIN disable trigger all; 
ALTER table bJBIT disable trigger all; 
ALTER table bJBIS disable trigger all; 
ALTER table bJBCX disable trigger all; 
ALTER Table bJBCC disable trigger all; 

--delete trans
delete bJBIN where JBCo=@toco;
delete bJBIT where JBCo=@toco;
delete bJBIS where JBCo=@toco;
delete bJBCX where JBCo=@toco;
delete bJBCC where JBCo=@toco;

-- add new trans
BEGIN TRAN
BEGIN TRY

select @rowcount=@@rowcount


--JBIN
begin tran
insert bJBIN (JBCo, BillMonth, BillNumber, Invoice, Contract,CustGroup, Customer,InvStatus, Application,RestrictBillGroupYN,RecType, 
DueDate, InvDate,PayTerms,BillAddress, BillAddress2, BillCity,BillState, BillZip,InvTotal, InvRetg,RetgRel,InvDisc,TaxBasis,InvTax,
InvDue,PrevAmt,PrevRetg,PrevRRel,PrevTax,PrevDue,ARGLCo,JCGLCo,CurrContract,PrevWC,WC,PrevSM,Installed,Purchased,SM,SMRetg,PrevSMRetg,
PrevWCRetg,WCRetg,PrevChgOrderAdds,PrevChgOrderDeds,ChgOrderAmt, AutoInitYN,BillOnCompleteYN, BillType,Purge,AuditYN,OverrideGLRevAcctYN, 
RevRelRetgYN, InvDescription,TMUpdateAddonYN,RetgTax,PrevRetgTax,RetgTaxRel,PrevRetgTaxRel, udSource,udConv)

select JBCo=l.ARCo
	,BillMonth=convert(varchar(5),datepart(mm,getdate())) + '/01/' + convert(varchar(5),datepart(yy,getdate()))
	,BillNumber=ROW_NUMBER() OVER (Order by l.Contract)
	,Invoice='    BEGBAL'
	,Contract=l.Contract
	,CustGroup=max(hq.CustGroup)
	,Customer=min(h.Customer)
	,InvStatus='N'
	,Application=1
	,RestrictBillGroupYN='N',RecType=1,DueDate=getdate(),InvDate=getdate()
	,PayTerms=@defaultPayTerms
	, BillAddress=min(c.BillAddress),
BillAddress2=min(c.BillAddress2), BillCity=min(c.BillCity), BillState=min(c.BillState), BillZip=min(c.BillZip),
InvTotal=sum(l.Amount) - sum(l.TaxAmount),InvRetg=sum(l.Retainage), RetgRel=0, InvDisc=0,TaxBasis=sum(l.TaxBasis), InvTax=sum(l.TaxAmount),
InvDue=sum(l.Amount) + sum(l.TaxAmount) - sum(l.Retainage),PrevAmt=0,PrevRetg=0,PrevRRel=0,PrevTax=0, PrevDue=0,
ARGLCo=l.ARCo, JCGLCo=max(l.JCCo),CurrContract=min(OrigContractAmt),PrevWC=0,WC=sum(l.Amount) - sum(l.TaxAmount),PrevSM=0,Installed=0,Purchased=0,SM=0,
SMRetg=0,PrevSMRetg=0,
PrevWCRetg=0,WCRetg=sum(l.Retainage),PrevChgOrderAdds=0,PrevChgOrderDeds=0,ChgOrderAmt=0/*will be updated by JBIS Trigger*/, AutoInitYN='N',
BillOnCompleteYN='N',BillType='P',Purge='N',AuditYN='N',OverrideGLRevAcctYN='N',RevRelRetgYN='N',InvDescription='Beginning Balances for JB Prog',
TMUpdateAddonYN='Y',RetgTax=0,PrevRetgTax=0,RetgTaxRel=0,PrevRetgTaxRel=0, udSource='JB',udConv='Y'
from bARTL l 
	join bHQCO hq on l.ARCo = hq.HQCo
	join bARTH h on l.ARCo=h.ARCo and l.Mth=h.Mth and l.ARTrans=h.ARTrans
	join bARCM c on h.CustGroup=c.CustGroup and h.Customer=c.Customer
	join bJCCM m on l.JCCo=m.JCCo and l.Contract=m.Contract
where h.ARTransType<>'P' and m.ContractStatus<2
	and l.ARCo=@toco
group by l.ARCo, l.Contract;

select @rowcount=@@rowcount;

commit tran;

checkpoint;

--JBIT
begin tran
insert bJBIT (JBCo, BillMonth, BillNumber, Item, Description, UnitsBilled, AmtBilled, RetgBilled, RetgRel, Discount, TaxBasis, TaxAmount, 
AmountDue, PrevUnits, PrevAmt, PrevRetg, PrevRetgReleased, PrevTax, PrevDue, /*ARLine, ARRelRetgLine, ARRelRetgCrLine,*/ TaxGroup, 
TaxCode, CurrContract, ContractUnits, PrevWC, PrevWCUnits, WC, WCUnits, PrevSM, Installed, Purchased, SM, SMRetg, PrevSMRetg, 
PrevWCRetg, WCRetg, Contract, Purge, AuditYN, WCRetPct, ChangedYN, RetgTax,PrevRetgTax, RetgTaxRel, PrevRetgTaxRel,udSource,udConv)

select JBCo=l.ARCo, BillMonth=convert(varchar(5),datepart(mm,getdate())) + '/01/' + convert(varchar(5),datepart(yy,getdate())),
BillNumber=min(n.BillNumber),
Item=isnull(i.Item, '               1'), 
Description=min(m.Description), UnitsBilled=0, AmtBilled=sum(l.Amount) - sum(l.TaxAmount), 
RetgBilled=sum(l.Retainage),RetgRel=0, Discount=0, TaxBasis=sum(l.TaxBasis), TaxAmount=sum(l.TaxAmount), 
AmountDue=sum(l.Amount) /*+ sum(l.TaxAmount) */- sum(l.Retainage),
PrevUnits=case when MIN( i.UM )<>'LS' then SUM(isnull(l.udItemsBilled,0))else 0 end, 
PrevAmt=0, PrevRetg=0, PrevRetgReleased=0, 
PrevTax=0, PrevDue=0,TaxGroup=max(hq.TaxGroup), TaxCode=min(m.TaxCode), 
CurrContract=min(isnull(i.ContAmt,0)),
ContractUnits=0, PrevWC=0,
PrevWCUnits=case when MIN( i.UM )<>'LS' then SUM(isnull(l.udItemsBilled,0))else 0 end, 
WC=sum(l.Amount) - sum(l.TaxAmount), WCUnits=0, 
PrevSM=0, Installed=0, Purchased=0, SM=0, 
SMRetg=0,PrevSMRetg=0, PrevWCRetg=0,WCRetg=sum(l.Retainage),
Contract=l.Contract, Purge='N',AuditYN='N',WCRetPct=0, ChangedYN='N', RetgTax=0,
PrevRetgTax=0,RetgTaxRel=0,PrevRetgTaxRel=0, udSource='JB',udConv='Y'
from bARTL l 
	join bHQCO hq on l.ARCo = hq.HQCo
	join bARTH h on l.ARCo=h.ARCo and l.Mth=h.Mth and l.ARTrans=h.ARTrans
	join bARCM c on h.CustGroup=c.CustGroup and h.Customer=c.Customer
	join bJCCM m on l.JCCo=m.JCCo and l.Contract=m.Contract
	left join (select JCCo, Contract, Item, Descrip=min(Description), ItemTaxCode=min(TaxCode),
				UM= min(UM),ContAmt=sum(ContractAmt)/*sum(OrigContractAmt)--changed in issue #93 */
			from bJCCI 
			group by JCCo, Contract, Item) 
			as i 
			on l.ARCo=i.JCCo and l.Contract=i.Contract and isnull(l.Item,'      
         1')=i.Item
	join bJBIN n on l.ARCo=n.JBCo and l.Contract=n.Contract
where h.ARTransType<>'P' and m.ContractStatus<2
	and l.ARCo=@toco
group by l.ARCo, l.Contract, isnull(i.Item, '               1');

select @rowcount=@rowcount+@@rowcount;

commit tran;

--JBIT - items that do not have AR activity yet
begin tran
insert bJBIT (JBCo, BillMonth, BillNumber, Item, Description, UnitsBilled, AmtBilled, RetgBilled, RetgRel, Discount, TaxBasis, TaxAmount, 
AmountDue, PrevUnits, PrevAmt, PrevRetg, PrevRetgReleased, PrevTax, PrevDue, /*ARLine, ARRelRetgLine, ARRelRetgCrLine,*/ TaxGroup, 
TaxCode, CurrContract, ContractUnits, PrevWC, PrevWCUnits, WC, WCUnits, PrevSM, Installed, Purchased, SM, SMRetg, PrevSMRetg, 
PrevWCRetg, WCRetg, Contract, Purge, AuditYN, WCRetPct, ChangedYN, RetgTax,PrevRetgTax, RetgTaxRel, PrevRetgTaxRel,udSource,udConv)

select JBCo=i.JCCo, 
	BillMonth=convert(varchar(5),datepart(mm,getdate())) + '/01/' + convert(varchar(5),datepart(yy,getdate())),
	BillNumber=min(n.BillNumber),
	Item=i.Item,
	Description=min(m.Description), UnitsBilled=0, AmtBilled=0, 
	RetgBilled=0,RetgRel=0, Discount=0, TaxBasis=0, TaxAmount=0, 
	AmountDue=0,PrevUnits=0, PrevAmt=0, 
	PrevRetg=0, PrevRetgReleased=0, 
	PrevTax=0, PrevDue=0,TaxGroup=max(hq.TaxGroup), TaxCode=min(m.TaxCode), 
	CurrContract=min(isnull(i.OrigContractAmt,0)),
	ContractUnits=0, PrevWC=0,PrevWCUnits=0, WC=0, WCUnits=0, 
	PrevSM=0, Installed=0, Purchased=0, SM=0, 
	SMRetg=0,PrevSMRetg=0, PrevWCRetg=0,WCRetg=0,
	Contract=i.Contract, Purge='N',AuditYN='N',WCRetPct=0, ChangedYN='N', RetgTax=0,
	PrevRetgTax=0,RetgTaxRel=0,PrevRetgTaxRel=0, udSource='JB',udConv='Y'
from bJCCI i 
	join bHQCO hq on i.JCCo = hq.HQCo
	join bJCCM m on i.JCCo=m.JCCo and i.Contract=m.Contract
	join bJBIN n on i.JCCo=n.JBCo and i.Contract=n.Contract
	left join bJBIT t on i.JCCo=t.JBCo and i.Item=t.Item and i.Contract=t.Contract
where m.ContractStatus<2
	and i.JCCo=@toco
	--and i.BilledAmt=0 and i.ReceivedAmt=0 --and i.OrigContractAmt<>0
	and t.JBCo is null
group by i.JCCo, i.Contract, i.Item;

select @rowcount=@rowcount+@@rowcount;

commit tran;

--JBIS
begin tran
insert bJBIS(JBCo, BillMonth, BillNumber, Job,Item, ACO, ACOItem,Description, UnitsBilled, AmtBilled, RetgBilled, RetgRel, Discount, TaxBasis, TaxAmount, AmountDue, PrevUnits, 
PrevAmt, PrevRetg, PrevRetgReleased, PrevTax, PrevDue, TaxGroup, TaxCode, CurrContract, ContractUnits, PrevWC, PrevWCUnits, WC, WCUnits, PrevSM, 
Installed, Purchased, SM, SMRetg, PrevSMRetg, PrevWCRetg, WCRetg,  Contract, ChgOrderUnits, ChgOrderAmt, WCRetPct, Purge, AuditYN, RetgTax, PrevRetgTax, RetgTaxRel, PrevRetgTaxRel
,udSource,udConv)

select JBCo=l.ARCo,  BillMonth=convert(varchar(5),datepart(mm,getdate())) + '/01/' + 
	convert(varchar(5),datepart(yy,getdate())),
BillNumber=min(n.BillNumber),
Job='',Item=isnull(i.Item, '               1'), 
ACO='', ACOItem='', 
Description=min(Descrip),
UnitsBilled=0, AmtBilled=sum(l.Amount) - sum(l.TaxAmount),
RetgBilled=sum(l.Retainage),RetgRel=0,Discount=0,TaxBasis=sum(l.TaxBasis),
TaxAmount=sum(l.TaxAmount),AmountDue=sum(l.Amount) /*+ sum(l.TaxAmount) */- sum(l.Retainage),
PrevUnits=case when  MIN( i.UM ) <>'LS' then SUM(isnull(l.udItemsBilled,0))else 0 end,  
PrevAmt=0, PrevRetg=0, PrevRetgReleased=0, PrevTax=0, PrevDue=0,
TaxGroup=max(hq.TaxGroup), TaxCode=min(ItemTaxCode),CurrContract=min(isnull(ContAmt,0)),
ContractUnits=0, 
PrevWC=case when  MIN( i.UM ) <>'LS' then SUM(isnull(l.udItemsBilled,0))else 0 end, 
PrevWCUnits=0,WC=sum(l.Amount), WCUnits=0, PrevSM=0, Installed=0, 
Purchased=0, SM=0, SMRetg=0,PrevSMRetg=0, 
PrevWCRetg=0,WCRetg=sum(l.Retainage),
Contract=l.Contract,
ChgOrderUnits=0,ChgOrderAmt=0,
WCRetPct=0,Purge='N',
AuditYN='N',RetgTax=0,PrevRetgTax=0,RetgTaxRel=0,PrevRetgTaxRel=0, udSource='JB',udConv='Y'
from bARTL l 
	join bHQCO hq on l.ARCo = hq.HQCo
	join bARTH h on l.ARCo=h.ARCo and l.Mth=h.Mth and l.ARTrans=h.ARTrans
	join bARCM c on h.CustGroup=c.CustGroup and h.Customer=c.Customer
	join bJCCM m on l.JCCo=m.JCCo and l.Contract=m.Contract
	left join (select JCCo, Contract, Item, Descrip=min(Description), ItemTaxCode=min(TaxCode),
				UM=min(UM),ContAmt=sum(OrigContractAmt) 
			from bJCCI 
			group by JCCo, Contract, Item) 
			as i 
			on l.ARCo=i.JCCo and l.Contract=i.Contract and isnull(l.Item,'      
         1')=i.Item
	join bJBIN n on l.ARCo=n.JBCo and l.Contract=n.Contract
where h.ARTransType<>'P' and m.ContractStatus<2
	and l.ARCo=@toco
group by l.ARCo, l.Contract, isnull(i.Item, '               1');


select @rowcount=@rowcount+@@rowcount

commit tran;

--JBIS --items without activity
begin tran
insert bJBIS(JBCo, BillMonth, BillNumber, Job,Item, ACO, ACOItem,Description, UnitsBilled, AmtBilled, RetgBilled, RetgRel, Discount, TaxBasis, TaxAmount, AmountDue, PrevUnits, 
PrevAmt, PrevRetg, PrevRetgReleased, PrevTax, PrevDue, TaxGroup, TaxCode, CurrContract, ContractUnits, PrevWC, PrevWCUnits, WC, WCUnits, PrevSM, 
Installed, Purchased, SM, SMRetg, PrevSMRetg, PrevWCRetg, WCRetg,  Contract, ChgOrderUnits, ChgOrderAmt, WCRetPct, Purge, AuditYN, RetgTax, PrevRetgTax, RetgTaxRel, PrevRetgTaxRel
,udSource,udConv)

select JBCo=l.JCCo,  BillMonth=convert(varchar(5),datepart(mm,getdate())) + '/01/' + 
		convert(varchar(5),datepart(yy,getdate())),
	BillNumber=min(n.BillNumber),
	Job='',Item=l.Item,
	ACO='', ACOItem='', 
	Description=min(l.BillDescription),
	UnitsBilled=0, AmtBilled=0,
	RetgBilled=0,RetgRel=0,Discount=0,TaxBasis=0,
	TaxAmount=0,AmountDue=0,
	PrevUnits=0, PrevAmt=0, PrevRetg=0, PrevRetgReleased=0, PrevTax=0, PrevDue=0,
	TaxGroup=max(hq.TaxGroup), TaxCode=min(l.TaxCode),CurrContract=min(isnull(l.OrigContractAmt,0)),
	ContractUnits=0, 
	PrevWC=0,PrevWCUnits=0,WC=0, WCUnits=0, PrevSM=0, Installed=0, 
	Purchased=0, SM=0, SMRetg=0,PrevSMRetg=0, 
	PrevWCRetg=0,WCRetg=0,
	Contract=l.Contract,
	ChgOrderUnits=0,ChgOrderAmt=0,
	WCRetPct=0,Purge='N',
	AuditYN='N',RetgTax=0,PrevRetgTax=0,RetgTaxRel=0,PrevRetgTaxRel=0, udSource='JB',udConv='Y'
from bJCCI l 
	join bHQCO hq on l.JCCo = hq.HQCo
	join bJCCM m on l.JCCo=m.JCCo and l.Contract=m.Contract
	join bJBIN n on l.JCCo=n.JBCo and l.Contract=n.Contract
	left join bJBIS t on l.JCCo=t.JBCo and l.Item=t.Item and l.Contract=t.Contract
where m.ContractStatus<2
	and l.JCCo=@toco
	--and l.BilledAmt=0 and l.ReceivedAmt=0 --and l.OrigContractAmt<>0
	and t.JBCo is null
group by l.JCCo, l.Contract, l.Item;


select @rowcount=@rowcount+@@rowcount

commit tran;

begin tran
insert bJBIS(JBCo, BillMonth, BillNumber, Job,Item, ACO, ACOItem,Description, UnitsBilled, AmtBilled, RetgBilled, RetgRel, Discount, TaxBasis, TaxAmount, AmountDue, PrevUnits, 
PrevAmt, PrevRetg, PrevRetgReleased, PrevTax, PrevDue, TaxGroup, TaxCode, CurrContract, ContractUnits, PrevWC, PrevWCUnits, WC, WCUnits, PrevSM, 
Installed, Purchased, SM, SMRetg, PrevSMRetg, PrevWCRetg, WCRetg,  Contract, ChgOrderUnits, ChgOrderAmt, WCRetPct, Purge, AuditYN, RetgTax, PrevRetgTax, RetgTaxRel, PrevRetgTaxRel
,udSource,udConv)

--change orders
select JBCo=bJCCI.JCCo,    
	BillMonth=dateadd(m,-1,CAST(
			  convert(varchar(5),datepart(mm,getdate())) 
			+ '/01/' 
			+ convert(varchar(5),datepart(yy,getdate())) as smalldatetime)
				),
BillNumber=min(n.BillNumber),Job=bJCCI.Contract,Item=bJCCI.Item,ACO=c.ACO, ACOItem=c.ACOItem, 
Description=min(bJCCI.BillDescription),UnitsBilled=0, AmtBilled=0,
RetgBilled=0,RetgRel=0,Discount=0,TaxBasis=0,
TaxAmount=0,AmountDue=0,
PrevUnits=0, PrevAmt=0, PrevRetg=0, PrevRetgReleased=0, PrevTax=0, PrevDue=0,
TaxGroup=max(hq.TaxGroup), TaxCode=null,CurrContract=0,ContractUnits=0, 
PrevWC=0,PrevWCUnits=0,WC=0, WCUnits=0, PrevSM=0, Installed=0, 
Purchased=0, SM=0, SMRetg=0,PrevSMRetg=0, 
PrevWCRetg=0,WCRetg=0,
Contract=bJCCI.Contract,ChgOrderUnits=min(COUnits),ChgOrderAmt=min(COAmt),WCRetPct=0,Purge='N',
AuditYN='N',RetgTax=0,PrevRetgTax=0,RetgTaxRel=0,PrevRetgTaxRel=0, udSource='JB',udConv='Y'
from bJCCI 
	join bHQCO hq on bJCCI.JCCo = hq.HQCo
	join (select JCCo, ACO=ACO, ACOItem=ACOItem,Contract, Item,COUnits=sum(ContractUnits), 
				COAmt=sum(ContractAmt) 
				from JCOI 
				group by JCCo, ACO, ACOItem, Contract, Item) 
				as c
				on bJCCI.JCCo=c.JCCo and bJCCI.Contract=c.Contract and bJCCI.Item=c.Item
	join bJBIN n on bJCCI.JCCo=n.JBCo and bJCCI.Contract=n.Contract
where c.ACO is not null and c.ACO<>''
	and bJCCI.JCCo=@toco
group by bJCCI.JCCo, bJCCI.Contract, bJCCI.Item, c.ACO, c.ACOItem

select @rowcount=@rowcount+@@rowcount

commit tran;



--JBCX
begin tran
insert bJBCX (JBCo, BillMonth, BillNumber, Job, ACO,ACOItem,ChgOrderUnits, ChgOrderAmt, AuditYN, Purge, udSource,udConv)
select JBCo=c.JCCo, BillMonth=convert(varchar(5),datepart(mm,getdate())) + '/01/' + convert(varchar(5),datepart(yy,getdate())),
BillNumber=min(n.BillNumber),Job=c.Contract, ACO=c.ACO, ACOItem=c.ACOItem, ChgOrderUnits=sum(c.ContractUnits), ChgOrderAmt=sum(c.ContractAmt),
AuditYN='N',Purge='N', udSource='JB',udConv='Y'
from JCOI c 
	join bJBIN n on c.JCCo=n.JBCo and c.Contract=n.Contract
where c.JCCo=@toco
group by c.JCCo, c.Contract, c.ACO, c.ACOItem
commit tran;

--JBCC
begin tran
insert bJBCC (JBCo, BillMonth,BillNumber,Job,ACO,ChgOrderTot, AuditYN, Purge,udSource,udConv)
select JBCo, BillMonth, BillNumber, Job, ACO, sum(ChgOrderAmt), 'N','N','JB',udConv='Y'
from bJBCX 
where bJBCX.JBCo=@toco
group by JBCo, BillMonth, BillNumber, Job, ACO

select @rowcount=@rowcount+@@rowcount
commit tran;


--update JB Change Order Total
update bJBIN set ChgOrderAmt=c.Tot
from bJBIN
	join (select JBCo, BillMonth, BillNumber,
			Tot=sum(ChgOrderTot) 
		from bJBCC where JBCo=@toco
		group by JBCo, BillMonth, BillNumber)
		as c
		on c.JBCo=bJBIN.JBCo and c.BillMonth=bJBIN.BillMonth and c.BillNumber=bJBIN.BillNumber
where bJBIN.JBCo=@toco

select @rowcount=@rowcount+@@rowcount


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER table bJBIN enable trigger all; 
ALTER table bJBIT enable trigger all; 
ALTER table bJBIS enable trigger all; 
ALTER table bJBCX enable trigger all; 
ALTER Table bJBCC enable trigger all; 

return @@error



GO
