SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================================
Copyright © 2012 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================================
 Title: Equipment Master (EMEM)
 Date:		April 2, 2009
 Created by:	VCS Technical Services - Andrew Bynum
 Revisions:	
	1. 8.30.10 JJH - Added default values to customer defaults and changed hard-coded values 
		to pull from cust defaults table 
	2. 03/19/2012 BBA - Added note below that there is still hardcoding that needs changed. 

IMPORTANT: THIS PROCEDURE STILL CONTAINS HARD-CODED VALUES SPECIFIC TO A CUSTOMER. MUST
REMOVE BEFORE USING.	

	ADA Notes:
	1. EM Categories not set up, xref remmed out.
	2. Job Null??? some Equip have jobs on them.
	
	
	
	

**/

CREATE proc [dbo].[cvsp_CMS_MASTER_EMEM] 
(@fromco smallint, @toco smallint,	@errmsg varchar(1000) output, @rowcount bigint output) 
as

set nocount on
set @errmsg=''
set @rowcount=0


--get values for functions
Declare @Job varchar(30)
Set @Job =  (Select InputMask from vDDDTc where Datatype = 'bJob')
Declare @Phase varchar(30)
Set @Phase =  (Select InputMask from vDDDTc where Datatype = 'bPhase');
declare @Equip varchar(10)
set @Equip = (select InputMask from vDDDTc where Datatype = 'bEquip');

--get defaults from HQCO
declare @VendorGroup smallint, @ShopGroup smallint,@CustGroup smallint
	,@MatlGroup smallint ,@EMGroup smallint, @PhaseGroup smallint
	
select @VendorGroup=VendorGroup, @ShopGroup=ShopGroup,@CustGroup=CustGroup,
	@MatlGroup =MatlGroup, @EMGroup = EMGroup, @PhaseGroup=PhaseGroup
 from bHQCO where HQCo=@toco


--get Customer defaults
declare @UpdateYN varchar(1),  @FuelCapUM varchar(3), @Capitalized char(1),
	@AttachPostRevenue char(1), @PostCostToComp char(1), @RevenueCode char(5)
select @UpdateYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UpdateYN' and a.TableName='bEMEM';

select @FuelCapUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='FuelCapUM' and a.TableName='bEMEM';

select @Capitalized=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Capitalized' and a.TableName='bEMEM';

select @AttachPostRevenue=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='AttachPostRevenue' and a.TableName='bEMEM';

select @PostCostToComp=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PostCostToComp' and a.TableName='bEMEM';

select @RevenueCode=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='RevenueCode' and a.TableName='bEMEM';

alter table bEMEM disable trigger all;

-- delete existing trans
begin tran
delete from bEMEM where EMCo=@toco
	--and udConv='Y';
commit tran;

-- add new trans
BEGIN TRY
begin tran

insert into bEMEM (
EMCo, Equipment, Location, Type, Department, Category, Manufacturer, Model, ModelYr, VINNumber, Description, 
Status, OdoReading, ReplacedOdoReading, HourReading, ReplacedHourReading, MatlGroup, FuelCapacity,
FuelUsed, EMGroup, JCCo, Job, PhaseGrp , WeightCapacity, VolumeCapacity,
 LicensePlateNo,-- LicensePlateExpDate,
PRCo, GrossVehicleWeight, TareWeight, NoAxles, OwnershipStatus, InServiceDate
, ExpLife, ReplCost, CurrentAppraisal, SoldDate
, SalePrice, PurchasePrice, PurchDate , APCo, VendorGroup, LeasePayment, LeaseResidualValue, ARCo, CustGroup, 
FuelType, UpdateYN, ShopGroup, PurchasedFrom, RevenueCode, UsageCostType, FuelCapUM, Capitalized, AttachPostRevenue,
PostCostToComp, OriginalEquipmentCode,udSource,udConv ,udCGCTable)


select 	EMCo					= @toco
		,Equipment				= dbo.bfMuliPartFormat(ltrim(rtrim(t.EQUIPMENTNUMBER)) ,@Equip)
		,Location				= 'HOME' --WAREHOUSELOC   /* CR 7/1/2013 Howard wants all fleet vehicles set to HOME.*/
		,Type					= 'E'         --MITCL
		,Department				= case 
									when DEPARTMENTNO >0 
									then 4350 
									else 1 
									end 
		,Category				= CASE RETIREDASSET WHEN 'Y' THEN '999' ELSE ITEMCLASS END
		,Manufacturer			= 'NEED'--null  --left(MD25B,20)
		,Model					= MODELNO
		,ModelYr				= MODELYR
		,VINNumber				= SERIALNUMBER
		,Description			= DESC25A
		,Status					= CASE EQUIPSTATCDE
									WHEN 4 THEN 'A'
									WHEN 5 THEN 'I'
									WHEN 6 THEN 'D'
								 END
		,OdoReading				= 0
		,ReplacedOdoReading		= 0
		,HourReading			= 0
		,ReplacedHourReading	= 0
		,MatlGroup				= @MatlGroup
		,FuelCapacity			= 0
		,FuelUsed				= 0
		,EMGroup				= @toco
		,JCCo					= @toco
		,Job					= null--dbo.bfMuliPartFormat(ltrim(rtrim(MJBNO)) + '.' + ltrim(RTRIM(MSJNO)),@Job)
		,PhaseGrp				= @PhaseGroup
		,WeightCapacity			= 0
		,VolumeCapacity			= 0
		,LicensePlateNo			= VEHLICNO
		--,LicensePlateExpDate = CASE WHEN EXPIRATIONDATE = 0 THEN NULL ELSE convert(datetime,left(EXPIRATIONDATE,8),101) END
		,PRCo					= @toco
		,GrossVehicleWeight		= 0 --convert(bigint,dbo.ExtractInteger(DESC25C))
		,TareWeight				= 0
		,NoAxles				= 0
		,OwnershipStatus		= OWNERSHIPTYPE
		,InServiceDate			= CASE
									 WHEN STARTDATE = 0 
									 THEN NULL 
									 ELSE
									substring(convert(nvarchar(max),STARTDATE),5,2) + '/' + 
									substring(convert(nvarchar(max),STARTDATE),7,2) + '/' + 
									substring(convert(nvarchar(max),STARTDATE),1,4)
									END
		,ExpLife				= 0
		,ReplCost				= left(REPLACEMENTCST,9)
		,CurrentAppraisal		= left(CURRMARKETVAL,9)
		,SoldDate				= CASE 
									WHEN DISPOSALDATE = 0 
									THEN NULL 
									ELSE
									substring(convert(nvarchar(max),DISPOSALDATE),5,2) + '/' + 
									substring(convert(nvarchar(max),DISPOSALDATE),7,2) + '/' + 
									substring(convert(nvarchar(max),DISPOSALDATE),1,4)
									END
		,SalePrice				= left(DISPOSALAMT,9)
		,PurchasePrice			= left(ACQUISITIONCOST,9)
		,PurchDate				= CASE 
									WHEN ANTICCSTDATE = 0 
									THEN NULL 
									ELSE convert(datetime,left(ANTICCSTDATE,8),101) 
									END
		,APCo					= @toco
		,VendorGroup			= @VendorGroup
		,LeasePayment			= 0
		,LeaseResidualValue     = 0
		,ARCo                   = @toco
		,CustGroup              = @CustGroup
		,FuelType               = 0
		,UpdateYN               = @UpdateYN
		,ShopGroup              = @ShopGroup
		,PurchasedFrom          = NULL
		,RevenueCode            = @RevenueCode
		,UsageCostType          = 3
		,FuelCapUM              = @FuelCapUM
		,Capitalized            = @Capitalized
		,AttachPostRevenue      = @AttachPostRevenue
		,PostCostToComp         = @PostCostToComp
		,OriginalEquipmentCode  = RTRIM(t.EQUIPMENTNUMBER)
		,udSource               = 'MASTER_EMEM'
		,udConv                 = 'Y'
		,udCGCTable             = 'EQTMST'
		
from CV_CMS_SOURCE.dbo.EQTMST t

/************************************************************  
		McKinstry wants only Fleet vehicles 
		email from Howard(dated 7/25 11:39 AM) to use GL Account 178000000000000
		the GL account is in EQPDNM
*************************************************************/

	join CV_CMS_SOURCE.dbo.EQTDNM m 
		on m.COMPANYNUMBER    = t.COMPANYNUMBER
		and m.EQUIPMENTNUMBER = t.EQUIPMENTNUMBER
		
--left join Viewpoint.dbo.budxrefEMCat c 
	--on t.COMPANYNUMBER = @fromco and  t.MITCL = c.EQTClass


where t.COMPANYNUMBER = @fromco
	and m.ASSETGLACCT = 178000000000000
;
	

select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=ERROR_PROCEDURE()+' '+convert(varchar(10),ERROR_LINE())+' '+ERROR_MESSAGE()
if @@trancount>0 rollback tran
END CATCH;

ALTER Table bEMEM enable trigger all;

return @@error

GO
