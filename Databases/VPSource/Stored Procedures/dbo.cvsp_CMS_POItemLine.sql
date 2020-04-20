
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_POItemLine] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**

=========================================================================
Copyright © 2012 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		PO Purchase Order Item Lines
	Created:	6/14/2012
	Created by:	BTC
	Revisions:	
			1. 10/10/12 BTC - Add ud field for ASQ02 & populate from POTMDT
			2. 10/04/13 BTC - Added JCJobs cross reference
*/

set @errmsg='';
set @rowcount=0;

--Defaults from HQCO
declare @VendorGroup tinyint, @MatlGroup tinyint, @TaxGroup tinyint, @PhaseGroup tinyint, @EMGroup tinyint
select @VendorGroup=VendorGroup,@MatlGroup=MatlGroup,
@TaxGroup=TaxGroup, @PhaseGroup=PhaseGroup, @EMGroup=EMGroup from bHQCO where HQCo=@toco;

--Declare Variables to use in fucntions
Declare @Job varchar(30)
Set @Job =  (Select InputMask from vDDDTc where Datatype = 'bJob')
Declare @Phase varchar(30)
Set @Phase =  (Select InputMask from vDDDTc where Datatype = 'bPhase');

--get defaults from APCO
declare @exppaytype tinyint, @jobpaytype tinyint, @subpaytype tinyint,@JCCo tinyint
select @exppaytype=ExpPayType, @jobpaytype=JobPayType, @subpaytype=SubPayType,
	@JCCo=JCCo 
from bAPCO where APCo=@toco;

--get defaults from Customer Defaults
--PayTerms
declare @defaultPayTerms varchar(5)
select @defaultPayTerms=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PayTerms' and a.TableName='bARTH';


----Add column to record ASQ02 if it doesn't already exist
--if not exists (select c.name from syscolumns c
--			join sysobjects o
--				on o.id=c.id
--			where o.name='vPOItemLine' and c.name='udCGC_ASQ02')
--begin
--	alter table vPOItemLine add udCGC_ASQ02 int
--end


ALTER Table bPOIT disable trigger all;
alter table vPOItemLine disable trigger all;


-- add new trans
BEGIN TRAN
BEGIN TRY


insert vPOItemLine
	(POITKeyID, POCo, PO, POItem, POItemLine, ItemType, PostToCo, JCCo, Job, PhaseGroup, Phase, JCCType,
		INCo, Loc, EMCo, EMGroup, Equip, CostCode, EMCType, TaxGroup, TaxType, TaxCode, TaxRate, GSTRate,
		GLCo, GLAcct, ReqDate, PayType, OrigUnits, OrigCost, OrigTax, CurUnits,	CurCost, CurTax, 
		RecvdUnits, RecvdCost, BOUnits, BOCost, InvUnits, InvCost, InvTax, InvMiscAmt, 
		RemUnits, RemCost, RemTax, JCCmtdTax, JCRemCmtdTax, TotalUnits, TotalCost, TotalTax, 
		PostedDate, JCMonth, PurgeYN, LineDelete, udCGC_ASQ02, udConv)
select
	  POITKeyID = it.KeyID
	, POCo=@toco
	, PO=d.PONUMBER
	, POItem=d.POITEMT
	, POItemLine = ROW_NUMBER () over (Partition by d.COMPANYNUMBER, d.PONUMBER, d.POITEMT order by SEQUENCENO02)
	, ItemType=case 
			when d.JOBNUMBER<>'' then 1
			when d.EQUIPMENTNUMBER<>'' then 4
			else 3 end
	, PostToCo = @toco
	, JCCo=@toco
	, Job=case 
			when d.JOBNUMBER='' then null 
			else xj.VPJob --dbo.bfMuliPartFormat(RTRIM(d.JOBNUMBER) + '.' + RTRIM(d.SUBJOBNUMBER),@Job) 
		  end
	, PhaseGroup=@PhaseGroup
	, Phase=xp.newPhase
	, JCCType=xt.CostType
	, INCo = @toco
	, Loc=null
	, EMCo = @toco
	, EMGroup=@EMGroup
	, Equip=case when d.EQUIPMENTNUMBER<>'' then rtrim(d.EQUIPMENTNUMBER) else null end
	, CostCode=case when d.EQUIPMENTNUMBER='' then null else isnull(xd.CostCode, '100') end
	, EMCType=xc.VPCostType
	, TaxGroup=@TaxGroup
	, TaxType=null	
	, TaxCode=null
	, TaxRate = 0
	, GSTRate = 0
	, GLCo=@toco
	, GLAcct=xg.newGLAcct
	, ReqDate=substring(convert(nvarchar(max),d.PODATE),5,2) + '/' +  substring(convert(nvarchar(max),d.PODATE),7,2) 
				+ '/' + substring(convert(nvarchar(max),d.PODATE),1,4)
	, PayType=case when d.JOBNUMBER<>'' then @jobpaytype else @exppaytype end
	, OrigUnits=case
			when it.UM='LS' then 0 else d.ORIGQTYORDERED end
	, OrigCost=case 
			when d.COSTDOLLARAMT<>0 then d.COSTDOLLARAMT
			when d.PRICECODE = 'C' then d.ORIGQTYORDERED / 100 * d.UNITCST
			when d.PRICECODE = 'M' then d.ORIGQTYORDERED / 1000 * d.UNITCST
			else d.ORIGQTYORDERED * d.UNITCST end
	, OrigTax=0
	, CurUnits=case
			when it.UM='LS' then 0 else d.QTYORDERED end
	, CurCost=case 
			when d.COSTDOLLARAMT<>0 then d.COSTDOLLARAMT
			when d.PRICECODE = 'C' then d.QTYORDERED / 100 * d.UNITCST
			when d.PRICECODE = 'M' then d.QTYORDERED / 1000 * d.UNITCST
			else d.QTYORDERED * d.UNITCST end
	, CurTax=0
	, RecvdUnits=case
			when it.UM='LS' then 0 else d.QTYRECIVED end
	, RecvdCost=case when d.QTYORDERED<>0 then 0 else d.DOLLARAMTRCVD end--VP doesn't store received cost if units exist
	, BOUnits=case
			when it.UM='LS' then 0 else d.QTYRECIVED end
	, BOCost=case when d.QTYORDERED<>0 then 0 else d.DOLLARAMTRCVD end--VP doesn't store received cost if units exist
	, InvUnits=d.QTYRECIVED
	, InvCost=d.DOLLARAMTRCVD
	, InvTax=0
	, InvMiscAmt = 0
	, RemUnits=0
	, RemCost=0
	, RemTax=0
	, JCCmtdTax = 0
	, JCRemCmtdTax = 0
	, TotalUnits=case
			when it.UM='LS' then 0 else d.QTYORDERED end
	, TotalCost=d.COSTDOLLARAMT
	, TotalTax=0
	, PostedDate=substring(convert(nvarchar(max),d.PODATE),5,2) + '/' +  substring(convert(nvarchar(max),d.PODATE),7,2) 
				+ '/' + substring(convert(nvarchar(max),d.PODATE),1,4)
	, JCMonth = d.udMth
	, PurgeYN = 'N'
	, LineDelete = 'N'
	, udCGC_ASQ02 = d.SEQUENCENO02
	, udConv = 'Y'
	
--select *
from CV_CMS_SOURCE.dbo.POTMDT d

join bPOIT it
	on it.PO=convert(nvarchar(30),d.PONUMBER) 
	and it.POItem=d.POITEMT 
	and it.POCo=@toco
	
left join Viewpoint.dbo.budxrefJCJobs xj
	on xj.COMPANYNUMBER = d.COMPANYNUMBER and xj.DIVISIONNUMBER = d.DIVISIONNUMBER and xj.JOBNUMBER = d.JOBNUMBER
		and xj.SUBJOBNUMBER = d.SUBJOBNUMBER
	
left join Viewpoint.dbo.budxrefPhase xp
	on xp.Company=d.COMPANYNUMBER 
	and d.JCDISTRIBTUION=xp.oldPhase
	
left join Viewpoint.dbo.budxrefCostType xt 
	on xt.Company=@fromco 
	and d.COSTTYPE=xt.CMSCostType
	
left join Viewpoint.dbo.budxrefEMCostType xc
	on xc.CMSCostType=d.TYPEOFCST
	
left join Viewpoint.dbo.budxrefEMCostCodes xd 
	on xd.CMSComponent=d.COMPONENTNO03
	
left join Viewpoint.dbo.budxrefGLAcct xg 
	on xg.Company=d.COMPANYNUMBER 
	and xg.oldGLAcct=d.GENLEDGERACCT
	
	
where d.COMPANYNUMBER=@fromco

select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


ALTER Table bPOIT enable trigger all;
alter table vPOItemLine enable trigger all;

return @@error


GO
