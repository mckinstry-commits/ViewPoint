
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_AP_OpenRetainage] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Open AP retainage Insert (APTH, APTL, APTD)
	Created:	10.13.09
	Created by: JJH    
	Revisions:	1. None
**/


set @errmsg=''
set @rowcount=0

--get defaults from HQCO
declare @VendorGroup tinyint, @PhaseGroup tinyint, @TaxGroup tinyint;
select @VendorGroup=VendorGroup, @PhaseGroup=PhaseGroup, @TaxGroup=TaxGroup from bHQCO where HQCo=@toco;


--get defaults from APCO
declare @CMCo tinyint, @retpaytype tinyint, @JCCo tinyint; 
select @CMCo=CMCo, @retpaytype=RetPayType, @JCCo=JCCo from bAPCO where APCo=@toco;

--get default GLCo, GL Acct from APPT
declare @GLCo tinyint, @GLAcct varchar(20);
select @GLCo=GLCo, @GLAcct=GLAcct from bAPPT where APCo=@toco and PayType=@retpaytype;

--get Customer defaults
--Default Due Date
declare @defaultDueDate smalldatetime
select @defaultDueDate=isnull(b.DefaultDate,a.DefaultDate) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DueDate' and a.TableName='bAPTH';

--UM
declare @defaultUM varchar(3)
select @defaultUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UM' and a.TableName='bAPTL';



ALTER Table bAPTH disable trigger all;
ALTER Table bAPTL disable trigger all;
ALTER Table bAPTD disable trigger all;


if  exists (select name from sysobjects where name='OpenRetg')
drop table OpenRetg;

create table OpenRetg
(APCo		tinyint			null,
APTrans		int				null,
Vendor		int				null,
SL			varchar(30)		null,
SLItem		int				null,
PO			varchar(10)		null,
POItem		int				null,
Job			varchar(10)		null,
Phase		varchar(20)		null,
JCCType		tinyint			null,
Remaining	decimal(12,2)	null,
udSource	varchar(15)		null,
udConv		varchar(1)		null);

--create unique clustered index iOpenRetg on OpenRetg(APCo, Vendor, SL, SLItem, Job);



------------------------------------ 

insert into OpenRetg
select h.APCo, APTrans=isnull(t.LastTrans,0) + ROW_NUMBER() OVER (order by h.APCo,h.Vendor),
h.Vendor, l.SL, l.SLItem, l.PO, l.POItem, l.Job, l.Phase, l.JCCType,Remaining=sum(l.Retainage) - isnull(InvRetg,0)
,udSource = 'AP_OpenRetain', udConv='Y'
from bAPTH h 
	join bAPTL l on h.APCo=l.APCo and h.Mth=l.Mth and h.APTrans=l.APTrans
	left join HQTC t on h.APCo=t.Co and t.Mth=convert(nvarchar(max),datepart(mm,getdate())) + '/01/' + convert(nvarchar(max),datepart(yy,getdate())) 
			and t.TableName='bAPTH'                
	left join (select a.APCo, a.Vendor, b.SL, b.SLItem, b.PO, b.POItem, b.Job, b.Phase, b.JCCType, InvRetg=sum(b.GrossAmt)
                from bAPTH a 
					join bAPTL b on a.APCo=b.APCo and a.Mth=b.Mth and a.APTrans=b.APTrans 
					left join bJCJM on b.JCCo=bJCJM.JCCo and b.Job=bJCJM.Job
					left join bJCCM on bJCJM.JCCo=bJCCM.JCCo and bJCJM.Contract=bJCCM.Contract
				where a.APCo=@toco and a.udRetgInvYN='Y' 
                group by a.APCo, a.Vendor, b.SL, b.SLItem, b.PO, b.POItem, b.Job, b.Phase, b.JCCType) 
				as i
                on h.APCo=i.APCo and h.Vendor=i.Vendor and isnull(l.SL,'')=isnull(i.SL,'') 
					and isnull(l.SLItem,0)=isnull(i.SLItem,0) 
					and isnull(l.PO,'')=isnull(i.PO,'') 
					and isnull(l.POItem,0)=isnull(i.POItem,0) 
					and l.Job=i.Job and l.Phase=i.Phase and l.JCCType=i.JCCType
	left join bJCJM on l.JCCo=bJCJM.JCCo and l.Job=bJCJM.Job
	left join bJCCM on bJCJM.JCCo=bJCCM.JCCo and bJCJM.Contract=bJCCM.Contract
where h.APCo=@toco
	and isnull(bJCJM.JobStatus, 1)=1
group by h.APCo, t.LastTrans, h.Vendor, l.SL, l.SLItem, l.PO, l.POItem, l.Job, l.Phase, l.JCCType, isnull(InvRetg,0)
having sum(l.Retainage) - isnull(InvRetg,0)<>0;


select * from OpenRetg


-- add new trans
BEGIN TRAN
BEGIN TRY
---------------------------------------------------


/* Insert Open Retainage Invoices*/
--APTH Open Retainage Invoices
insert bAPTH(APCo, Mth, APTrans, VendorGroup, Vendor, APRef, InvDate, DueDate, 
		InvTotal,PayMethod, CMCo, CMAcct,
		PrePaidYN, OpenYN,BatchId,InPayControl,SeparatePayYN,ChkRev,udRetgInvYN, 
		V1099YN, Purge, Description, PayOverrideYN,udSource,udConv)
select APCo=@toco
	,Mth = convert(nvarchar(max),datepart(mm,getdate())) + '/01/' + convert(nvarchar(max),datepart(yy,getdate()))
	,APTrans = APTrans
	,VendorGroup = @VendorGroup
	,Vendor = OpenRetg.Vendor
	,APRef = 'ORtg-' + convert(varchar(max),OpenRetg.Vendor)
	,InvDate = getdate()
	,DueDate = @defaultDueDate
	,InvTotal = Remaining
	,PayMethod ='C'
	,CMCo = @CMCo
	,CMAcct = null
	,PrePaidYN = 'N'
	,OpenYN = 'Y'
	,BatchId = 0
	,InPayControl = 'N'
	,SeparatePayYN = 'N'
	,ChkRev = 'N'
	,udRetgInvYN = 'Y'
	,V1099YN = 'N'
	,Purge = 'N'
	,Description = 'Open Retainage'
	,PayOverrideYN = 'N'
	,udSource = udSource
	, udConv
from OpenRetg

select @rowcount=@@rowcount;

--APTL Open Retainage Invoices

insert bAPTL (APCo, Mth, APTrans, APLine, LineType, PO, POItem, 
	SL, SLItem,JCCo, Job, PhaseGroup, Phase, JCCType,GLCo, GLAcct,
	Description, UM, Units, UnitCost, PayType,GrossAmt, MiscAmt, MiscYN,
	TaxGroup, TaxCode, TaxType, TaxBasis, TaxAmt,Retainage,
	Discount,BurUnitCost, POPayTypeYN,udSource,udConv)
select APCo = APCo
	, Mth=convert(nvarchar(max),datepart(mm,getdate())) + '/01/' + convert(nvarchar(max),datepart(yy,getdate()))
	, APTrans = APTrans
	, APLine=1
	, LineType=case when SL is not null then 7 when PO is not null then 6 else 1 end
	, PO
	, POItem
	, SL
	, SLItem
	, @JCCo
	, Job
	, @PhaseGroup
	, Phase
	, JCCType
	, GLCo = @GLCo
	, GLAcct=@GLAcct
	, Description='Open Retainage'
	, @defaultUM
	, Units=0
	, UnitCost=0
	, PayType=@retpaytype
	, GrossAmt=Remaining
	, MiscAmt=0
	, MiscYN='N'
	, @TaxGroup
	, TaxCode=null
	, TaxType=null
	, TaxBasis=0
	, TaxAmt=0
	, Retainage=Remaining
	, Discount=0
	, BurUnitCost=0
	, POPayTypeYN=case when PO is not null then 'Y' else 'N' end
	, udSource
	, udConv
from OpenRetg;


select @rowcount=@rowcount+@@rowcount;

--APTD Open Retainage Invoices

insert bAPTD (APCo, Mth, APTrans, APLine, APSeq,PayType, Amount, DiscOffer,DiscTaken,
	DueDate, Status, CMCo, udRetgHistory,udSource,udConv)
select APCo
	, Mth=convert(nvarchar(max),datepart(mm,getdate())) + '/01/' + convert(nvarchar(max),datepart(yy,getdate()))
	, APTrans
	, APLine=1
	, APSeq=1
	, PayType=@retpaytype
	, Amount=Remaining
	, DiscOffer=0
	, DiscTaken=0
	, DueDate=@defaultDueDate
	, Status=2
	, CMCo = null
	, udRetgHistory='N'
	, udSource 
	, udConv
from OpenRetg
	join bHQCO hq on  hq.HQCo=@toco;

select @rowcount=@rowcount+@@rowcount;


--------------------End open insert retainage invoices--------------------- 

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


ALTER Table bAPTH enable trigger all;
ALTER Table bAPTL enable trigger all;
ALTER Table bAPTD enable trigger all;

return @@error








GO
