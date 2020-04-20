
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE proc [dbo].[cvsp_CMS_APTL] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**

=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AP Transaction Lines (APTL)
	Created:	10.12.09
	Created by:	JJH
	
	Notes:		CMS handles retainage differently. Instead of going back to original invoice and 
				taking retainage off of hold, they enter a brand new R type invoice where the RetgInv 
				in APPOPC is Y. But, the retainage has already been included in the invoiced amount and actual costs.
				In Viewpoint Gross Amount should include Retainage Amount. In CMS, it does not. 
				
	Rev:		1. 6/19/2012 BTC - @defaultGLAcct was limited to 3 characters.  Changed to 20.
				2. 10/25/2012 BTC - Adding in PO fields & linking to POIT
				3. 10/25/2012 BTC - Changed link to PMSL - linking to earliest sequence by Project, Vendor, 
					CGC Contract Number, and CGC Item Number
				4. 10/25/2012 BTC - Populating Tax fields
				5. 10/25/2012 BTC - Changed case statement to determine TransType so that records with no
					associated PO or SL are brought in as Job or Expense.  If they are brought in as PO or SL,
					it results in out of balance committed costs in Job Cost.
				6. 10/25/2012 BTC - There may be source records where the Phase and/or CostType on the APTOPD record
					does not match the Phase/Cost Type on the associated PO or SL.  I modified the APTL procedure
					to pull from POIT or SLIT in those cases.
				7. 10/25/2012 BTC - Modified to populate POItemLine field in APTL, needed to accurately post Invoiced amounts
					to vPOItemLine.
				8. 10/04/2013 BTC - Added JCJobs cross reference
*/


set @errmsg='';
set @rowcount=0;

--get defaults from HQCO
declare @PhaseGroup tinyint, @TaxGroup tinyint
select @PhaseGroup=PhaseGroup, @TaxGroup=TaxGroup from bHQCO where HQCo=@toco;

--get defaults from APCO
declare @exppaytype tinyint, @jobpaytype tinyint, @subpaytype tinyint,@JCCo tinyint
select @exppaytype=ExpPayType, @jobpaytype=JobPayType, @subpaytype=SubPayType,
	@JCCo=JCCo 
from bAPCO where APCo=@toco;


--get Customer defaults
--UM
declare @defaultUM varchar(3)
select @defaultUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UM' and a.TableName='bAPTL';

--Default GL Account
declare @defaultGLAcct varchar(20)
select @defaultGLAcct=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='GLAcct' and a.TableName='bAPTL';


--Declare Variables to use in fucntions
Declare @Job varchar(30)
Set @Job =  (Select InputMask from vDDDTc where Datatype = 'bJob')
Declare @Phase varchar(30)
Set @Phase =  (Select InputMask from vDDDTc where Datatype = 'bPhase');


ALTER Table bAPTL disable trigger all;

--delete trans
delete bAPTL where APCo=@toco
	--and udConv = 'Y';

-- add new trans
BEGIN TRAN
BEGIN TRY

select @rowcount=@@rowcount

insert bAPTL (APCo, Mth, APTrans, APLine, LineType, PO, POItem, ItemType, SL, SLItem, JCCo, Job, PhaseGroup, Phase, JCCType,
	GLCo, GLAcct, Description, UM, Units, UnitCost, ECM, PayType, GrossAmt, MiscAmt, MiscYN,
	TaxGroup, TaxCode, TaxType, TaxBasis, TaxAmt, Retainage, Discount, BurUnitCost, POPayTypeYN,POItemLine,
	udPaidAmt, udYSN, ud1099Type, udRCCD, udSource, udConv, udCGCTable, udCGCTableID)

select APCo=@toco
	, Mth=udMth
		--substring(convert(nvarchar(max),d.JOURNALDATE),5,2) + '/01/' +  substring(convert(nvarchar(max),d.JOURNALDATE),1,4)
	, APTrans=udAPTrans
		--convert(nvarchar(max),d.PAYMENTSELNO) + convert(nvarchar(max),d.RECORDCODE)
	, APLine=d.SEQUENCENO03
	, LineType= case
		--when d.CONTRACTNO<>0 then 7
		--when d.POITEMT<>0 then 6
		when sl.SLItem is not null then 7
		when it.POItem is not null then 6
		when d.JOBNUMBER<>'' then 1
		when d.EQUIPMENTCODE<>'' then 4
		else 3 end
	, PO = case when isnull(d.udPONumber,0)<>0 then d.udPONumber else null end
	, POItem = case when isnull(d.udPONumber,0)<>0 then d.POITEMT else null end
	, ItemType = it.ItemType
	, SL = sl.SL
	, SLItem = sl.SLItem
	, JCCo=@JCCo
	, Job=case 
		when d.JOBNUMBER='' then null 
		else xj.VPJob end -- dbo.bfMuliPartFormat(RTRIM(d.JOBNUMBER) + '.' + RTRIM(d.SUBJOBNUMBER),@Job) end
	, @PhaseGroup
	, Phase=case 
		when d.JOBNUMBER='' then null 
		when it.POItem is not null then it.Phase
		when sl.SLItem is not null then sl.Phase
		else xp.newPhase end
	, JCCType=case
		when d.JOBNUMBER='' then null
		when it.POItem is not null then it.JCCType
		when sl.SLItem is not null then sl.CostType
		else xt.CostType end
	, GLCo=@toco
	, GLAcct=isnull(newGLAcct,@defaultGLAcct)
	, Description=d.DESC20A
	, UM=case
		when isnull(d.udPONumber,0)<>0 and it.UM is not null 
		then it.UM
		when d.CONTRACTNO<>0 and sl.UM is not null 
		then sl.UM
		else /*ISNULL(xu.VPUM,*/ 
			case 
			when d.POQUANTITY<>0 
			then 'EA' 
			else 'LS' 
			end/*)*/ 
		end
	, Units=case
		when it.UM='LS' then 0
		when sl.UM='LS' then 0
		--when xu.VPUM='LS' then 0
		else d.POQUANTITY end
	, UnitCost=case
		when it.UM='LS' then 0
		when sl.UM='LS' then 0
		--when xu.VPUM='LS' then 0
		when d.POQUANTITY=0 then 0
		else d.GROSSAMT/d.POQUANTITY end
	, ECM = case
		when it.UM='LS' then null
		when sl.UM='LS' then null
		--when xu.VPUM='LS' then null
		when d.FUM='' and d.POQUANTITY=0 then null
		when d.PRICECODE in ('E', 'C', 'M') then d.PRICECODE
		else 'E' end
	, PayType=case when d.JOBNUMBER='' then @exppaytype 
				when d.JOBNUMBER<>'' and d.CONTRACTNO<>0 then @subpaytype 
				else @jobpaytype end
	, GrossAmt=d.GROSSAMT - d.TAXAMOUNT04
	, MiscAmt=0
	, MiscYN='N'
	, @TaxGroup
	, TaxCode=case
		when d.TAXAMOUNT04=0 and d.ACCRUEDTAXES=0 then null
		when d.STSLSTAXCD<>0 and d.LOCALSLSTAXCDE<>0 then CONVERT(nvarchar(max), d.STSLSTAXCD) 
			+ '-' + CONVERT(nvarchar(max), d.LOCALSLSTAXCDE)
		when d.STSLSTAXCD<>0 and d.LOCALSLSTAXCDE=0 then CONVERT(nvarchar(max), d.STSLSTAXCD)
		when d.STSLSTAXCD=0 and d.LOCALSLSTAXCDE<>0 then CONVERT(nvarchar(max), d.LOCALSLSTAXCDE)
		end
	, TaxType = case
		when d.TAXAMOUNT04<>0 then 1
		when d.ACCRUEDTAXES<>0 then 2
		else null end
	, TaxBasis=case when d.TAXAMOUNT04=0 and d.ACCRUEDTAXES=0 then 0 else d.GROSSAMT - d.TAXAMOUNT04 end
	, TaxAmt=case when d.TAXAMOUNT04<>0 then d.TAXAMOUNT04 else d.ACCRUEDTAXES end
	, Retainage=d.RETAINEDAMT
	, Discount=d.DISCOUNTAMT
	, BurUnitCost=0
	, POPayTypeYN='N'
	, POItemLine = case
		when it.POItem is not null then ISNULL(il.POItemLine, mil.MinPOItemLine)
		else null end
	, udPaidAmt=d.PARTPAYAMTTD
	, udYSN = d.PAYMENTSELNO
	, ud1099Type=case when ltrim(rtrim(d.FORM1099REQ))='' then null else d.FORM1099REQ end 
	, udRCCD=d.RECORDCODE
	, udSource ='APTL'
	, udConv='Y'
	, udCGCTable='APTOPD'
	, udCGCTableID=d.APTOPDID
	
from CV_CMS_SOURCE.dbo.APTOPD d 

--JOIN CV_CMS_SOURCE.dbo.APTOPC c
--	on c.COMPANYNUMBER = d.COMPANYNUMBER 
--	and c.VENDORNUMBER = d.VENDORNUMBER 
--	and c.PAYMENTSELNO = d.PAYMENTSELNO
--	and   c.RECORDCODE = d.RECORDCODE

left join Viewpoint.dbo.budxrefJCJobs xj
	on xj.COMPANYNUMBER = d.COMPANYNUMBER and xj.DIVISIONNUMBER = d.DIVISIONNUMBER and xj.JOBNUMBER = d.JOBNUMBER
		and xj.SUBJOBNUMBER = d.SUBJOBNUMBER
		
LEFT JOIN Viewpoint.dbo.budxrefCostType xt 
	on xt.Company  = @fromco 
	and d.COSTTYPE = xt.CMSCostType
	
LEFT JOIN Viewpoint.dbo.budxrefPhase xp 
	on        xp.Company = d.COMPANYNUMBER 
	and d.JCDISTRIBTUION = xp.oldPhase
	
LEFT JOIN bPOIT it
	on it.PO      = d.udPONumber
	and it.POItem = d.POITEMT 
	and it.POCo   = @toco
		
LEFT JOIN bPMSL sl
	on sl.Vendor            = d.udNewVendor 
	and sl.udSLContractNo   = d.CONTRACTNO 
	and sl.udCMSItem        = d.ITEMNUMBER 
	and left(sl.Project, 5) = rtrim(d.JOBNUMBER) 
	and sl.udCGCTable       = 'APTCNS' 
	and sl.PMCo             = @toco
	
LEFT JOIN Viewpoint.dbo.budxrefGLAcct g 
	on d.GENLEDGERACCT = g.oldGLAcct 
	and    g.Company   = @fromco
	
--LEFT JOIN budxrefUM xu
	--on xu.CGCUM=d.FUM
	
LEFT JOIN vPOItemLine il
	on           il.PO = d.udPONumber 
	and      il.POItem = d.POITEMT 
	and il.udCGC_ASQ02 = d.SEQUENCENO02 
	and        il.POCo = @toco
	
LEFT JOIN (select POCo
			, PO
			, POItem
			, MIN(POItemLine) 
			
			as MinPOItemLine 
			from vPOItemLine
			GROUP BY 
				POCo
				, PO
				, POItem) 
			 as mil
				on    mil.PO   = d.udPONumber 
				and mil.POItem = d.POITEMT 
				and mil.POCo   = @toco

WHERE d.COMPANYNUMBER=@fromco

and udAPTrans is not null  /* this can be removed after 8/30 refresh, I think my data pull from CGC 
								did not update both APTOPC and APTOPD with the same transactions, timing issue.*/



select @rowcount=@@rowcount;




COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bAPTL enable trigger ALL;

return @@error

GO
