SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



CREATE proc [dbo].[cvsp_CMS_POIT] 
	( @fromco1 smallint
	, @fromco2 smallint
	, @fromco3 smallint
	, @toco smallint
	, @errmsg varchar(1000) output
	, @rowcount bigint output
	) 
as


/**

=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		PO Purchase Order Items
	Created:	08.31.10
	Created by:	JJH
	Revisions:				
			1. 10/25/2012 BTC - Set RecvYN flag to default as 'N'.  Not
				converting receipt transactions.
			2. 10/25/2012 BTC - Added code to account for Price Codes C (per hundred)
				and M (per thousand)
			3. 10/25/2012 BTC - Used ORIGQTYORDERED columns for the OrigUnits
			4. 10/25/2012 BTC - Must disable vPOItemLine triggers and delete these
				records as well.  They will be added back in another procedure.
			5. 10/25/2012 BTC - Modified several fields to record nulls instead of
				blanks in Viewpoint data.
			6. 10/25/2012 BTC - Modified UM and all Units formulas to prevent PO Items 
				with 'LS' UM and with quantities.
			7. 10/04/2013 BTC - Added JCJobs Cross Reference
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
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PayTerms' and a.TableName='bARTH';


ALTER Table bPOIT disable trigger all;
alter table vPOItemLine disable trigger all;


--delete trans
begin tran
delete bPOIT where POCo=@toco
	and udConv = 'Y';
delete vPOItemLine where POCo=@toco
commit tran

-- add new trans
BEGIN TRY
BEGIN TRAN

	insert bPOIT 
		( POCo
		, PO
		, POItem
		, ItemType
		, MatlGroup
		, Material
		, Description
		, UM
		, RecvYN
		, PostToCo
		, Loc
		, JCCo
		, Job
		, PhaseGroup
		, Phase
		, JCCType
		, Equip
		, EMGroup
		, CostCode
		, EMCType
		, GLCo
		, GLAcct
		, ReqDate
		, TaxGroup
		, TaxCode
		, TaxType
		, OrigUnits
		, OrigUnitCost
		, OrigECM
		, OrigCost
		, OrigTax
		, CurUnits
		, CurUnitCost
		, CurECM
		, CurCost
		, CurTax
		, RecvdUnits
		, RecvdCost
		, BOUnits
		, BOCost
		, TotalUnits
		, TotalCost
		, TotalTax
		, InvUnits
		, InvCost
		, InvTax
		, RemUnits
		, RemCost
		, RemTax
		, PostedDate
		, AddedMth
		, PayType
		, EMCo
		, udSource
		, udConv
		, udCGCTable
		)
		
	select POCo			= @toco
		 , PO			= cast(i.COMPANYNUMBER as varchar(30)) + '-' + cast(i.PONUMBER as varchar(30))
		 , POItem		= i.POITEMT
		 , ItemType		= max(case 
								when i.JOBNUMBER<>'' then 1
	 							when EQUIPMENTNUMBER<>'' then 4 else 3 end)
		 , MatlGroup	= @MatlGroup
		 , Material		= max(case when i.PARTNUMBER<>'' then i.PARTNUMBER else null end)
		 , Description	= max(case when i.DESCRIPTION1<>'' then rtrim(i.DESCRIPTION1) else null end)
		 , UM			= case
							when max(i.AUM)='LS' and sum(i.QTYORDERED) not in (-1, 0, 1) then 'EA'
							when max(i.AUM)='' and (sum(i.QTYORDERED)<>0 or SUM(i.ORIGQTYORDERED)<>0 or SUM(i.QTYRECIVED)<>0) then 'EA'
							when MAX(xu.VPUM) is null and SUM(i.QTYORDERED)<>0 then 'EA'
							else max(ISNULL(xu.VPUM, 'LS')) end
		 , RecvYN		= 'N' --case when (sum(QTYRECIVED)<>0 or sum(DOLLARAMTRCVD)<>0) then 'Y' else 'N' end
		 , PostToCo		= @toco
		 , Loc			= null
		 , JCCo			= @toco
		 , Job			= max(case 
								when i.JOBNUMBER='' then null 
								else xj.VPJob end)--dbo.bfMuliPartFormat(RTRIM(i.JOBNUMBER) + '.' + RTRIM(i.SUBJOBNUMBER),@Job) 
		 , PhaseGroup	= @PhaseGroup
		 , Phase		= max(case when JCDISTRIBTUION='' then null else p.newPhase end)
		 , JCCType		= max(t.CostType)
		 , Equip		= max(case when i.EQUIPMENTNUMBER<>'' then rtrim(i.EQUIPMENTNUMBER) else null end)
		 , EMGroup		= @EMGroup
		 , CostCode		= case when max(i.EQUIPMENTNUMBER)='' then null else max(isnull(d.CostCode, '100')) end
		 , EMCType		= NULL --max(c.CostType)
		 , GLCo			= @toco
		 , GLAcct		= max(g.newGLAcct)
		 , ReqDate		= null--max(substring(convert(nvarchar(max),i.PODATE),5,2) + '/' +  substring(convert(nvarchar(max),i.PODATE),7,2) 
							-- + '/' + substring(convert(nvarchar(max),i.PODATE),1,4)) --McKinstry requested date to be blank.
		 , TaxGroup		= @TaxGroup
		 , TaxCode		= null
		 , TaxType		= null
		 , OrigUnits	= case
							when MAX(i.AUM)='LS' and SUM(i.QTYORDERED) in (-1, 0, 1) then 0
							else sum(i.ORIGQTYORDERED) end
		 , OrigUnitCost	= case
							when MAX(i.AUM)='LS' and SUM(i.QTYORDERED) in (-1, 0, 1) then 0
							else max(i.UNITCST) end
		 , OrigECM		= case 
							when sum(i.ORIGQTYORDERED)=0 then null
							when MAX(i.AUM)='LS' and SUM(i.QTYORDERED) in (-1, 0, 1) then null
							when max(i.PRICECODE) in ('C', 'M') then max(i.PRICECODE)
							else 'E' end
		 , OrigCost		= case 
							when sum(i.COSTDOLLARAMT)<>0 then sum(i.COSTDOLLARAMT)
							when MAX(i.PRICECODE) = 'C' then SUM(i.ORIGQTYORDERED) / 100 * MAX(i.UNITCST)
							when MAX(i.PRICECODE) = 'M' then SUM(i.ORIGQTYORDERED) / 1000 * MAX(i.UNITCST)
							else sum(i.ORIGQTYORDERED) * max(i.UNITCST) end
		 , OrigTax		= 0
		 , CurUnits		= case
							when MAX(i.AUM)='LS' and SUM(i.QTYORDERED) in (-1, 0,1) then 0
							else sum(i.QTYORDERED) end
		 , CurUnitCost	= case
							when MAX(i.AUM)='LS' and SUM(i.QTYORDERED) in (-1, 0, 1) then 0
							else max(i.UNITCST) end
		 , CurECM		= case 
							when sum(i.QTYORDERED)=0 then null
							when MAX(i.AUM)='LS' and SUM(i.QTYORDERED) in (-1,0,1) then null
							when max(i.PRICECODE) in ('C', 'M') then max(i.PRICECODE)
							else 'E' end
		 , CurCost		= case 
							when sum(COSTDOLLARAMT)<>0 then sum(COSTDOLLARAMT)
							else sum(QTYORDERED)*max(UNITCST) end
		 , CurTax		= 0
		 , RecvdUnits	= case
							when MAX(i.AUM)='LS' and SUM(i.QTYORDERED) in (-1, 0, 1) then 0
							else sum(i.QTYRECIVED) end
		 , RecvdCost	= case when sum(QTYORDERED)<>0 then 0 else sum(DOLLARAMTRCVD) end--VP doesn't store received cost if units exist
		 , BOUnits		= case
							when MAX(i.AUM)='LS' and SUM(i.QTYORDERED) in (-1, 0, 1) then 0
							else sum(i.QTYRECIVED) end
		 , BOCost		= case 
							when sum(QTYORDERED)<>0 then 0 
							else sum(DOLLARAMTRCVD) end--VP doesn't store received cost if units exist
		 , TotalUnits	= case
							when MAX(i.AUM)='LS' and SUM(i.QTYORDERED) in (-1, 0, 1) then 0
							else sum(i.QTYORDERED) end
		 , TotalCost	= sum(COSTDOLLARAMT)
		 , TotalTax		= 0
		 , InvUnits		= 0
		 , InvCost		= 0
		 , InvTax		= 0
		 , RemUnits		= 0
		 , RemCost		= case when sum(QTYORDERED) = 0 and sum(COSTDOLLARAMT) > sum(DOLLARAMTRCVD) then sum(COSTDOLLARAMT) - sum(DOLLARAMTRCVD) else 0 end
		 , RemTax		= 0
		 , PostedDate	= max(substring(convert(nvarchar(max),i.PODATE),5,2) + '/' +  substring(convert(nvarchar(max),i.PODATE),7,2) 
						+ '/' + substring(convert(nvarchar(max),i.PODATE),1,4))
		 , AddedMth		= max(substring(convert(nvarchar(max),i.PODATE),5,2) + '/01'
						+ '/' + substring(convert(nvarchar(max),i.PODATE),1,4))
		 , PayType		= max(case when i.JOBNUMBER<>'' then @jobpaytype 
								else @exppaytype end)
		 , EMCo			= @toco
		 , udSource		= 'POIT'
		 , udConv		= 'Y'
		 , udCGCTable	= 'POTMDT'
		
	  from CV_CMS_SOURCE.dbo.POTMDT i

	/* Custom View Bill O.(@McKinstry) made to bring over certain PO's, see view for notes CR 8/26/2013 */
		join MCK_MAPPING_DATA.dbo.vwCGCPurchaseOrdersForConversion PO 
		ON PO.ACONO = i.COMPANYNUMBER
		and PO.ADVNO = i.DIVISIONNUMBER
		and PO.APONO = i.PONUMBER

		left join Viewpoint.dbo.budxrefJCJobs xj
			on xj.COMPANYNUMBER = i.COMPANYNUMBER and xj.DIVISIONNUMBER = i.DIVISIONNUMBER and xj.JOBNUMBER = i.JOBNUMBER
				and xj.SUBJOBNUMBER = i.SUBJOBNUMBER
		left join Viewpoint.dbo.budxrefUM xu on xu.CGCUM=i.AUM 
		left join Viewpoint.dbo.budxrefPhase p on p.Company=@toco and i.JCDISTRIBTUION=p.oldPhase
		left join Viewpoint.dbo.budxrefCostType t on t.Company=@PhaseGroup and i.COSTTYPE=t.CMSCostType
		left join Viewpoint.dbo.budxrefEMCostType c on c.CMSCostType=i.TYPEOFCST
		left join Viewpoint.dbo.budxrefEMCostCodes d on d.CMSComponent=i.COMPONENTNO03
		join Viewpoint.dbo.budxrefGLAcct g on g.newCompany=@toco
				and g.oldGLAcct=i.GENLEDGERACCT
				
	where i.COMPANYNUMBER in (@fromco1,@fromco2,@fromco3)

		/* PO's missing GL Accounts */
		AND i.PONUMBER <> 97078680
	group by i.COMPANYNUMBER,i.PONUMBER, i.POITEMT;


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
