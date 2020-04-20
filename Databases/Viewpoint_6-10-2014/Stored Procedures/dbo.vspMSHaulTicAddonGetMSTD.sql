SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************/
CREATE  proc [dbo].[vspMSHaulTicAddonGetMSTD]
/***********************************************************
 * CREATED BY:	GF 09/27/2007 6.x
 * MODIFIED BY:	GF 03/18/2008 - issue #127082 international addresses
 *
 *
 *
 *
 *USAGE:
 *	for MSHaulAddon form - gets static information for form header 
 *
 *INPUT PARAMETERS:
 *	MSCo
 *	Mth
 *	BatchId
 *	MSTrans
 *
 *OUTPUT PARAMETERS:
 *	@errmsg      error message
 *
 *RETURN VALUE:
 *	0	success
 *	1	failure
 *****************************************************/ 
(@msco bCompany, @mth bMonth, @mstrans bTrans, @saledate bDate = null output, 
 @vendorgroup tinyint = null output, @matlvendor bVendor =null output, @saletype varchar(1) = null output, 
 @custgroup tinyint =null output, @customer int =null output, @custname varchar(30)=null output,
 @custjob varchar(20)=null output, @custpo varchar(20)=null output,
 @jcco bCompany = null output, @job bJob = null output, @jobdesc varchar(30) = null output,
 @phasegroup tinyint = null output, @inco bCompany = null output, @toloc varchar(10) = null output,    
 @tolocdesc varchar(30)=null output, @matlgroup tinyint = null output, @material bMatl = null output, 
 @um bUM = null output, @matlphase varchar(30)=null output, @matljcctype tinyint =null output,
 @wghtum varchar(3) =null output, @matlunits bUnits = null output, @unitprice bUnitCost = null output,
 @ecm varchar(1) = null output, @matltotal bDollar = null output, @haulertype varchar(1) = null output,
 @haulvendor bVendor = null output, @haulvendorname varchar(60) =null output, @truck varchar(10)=null output,
 @driver varchar(30)=null output, @emco bCompany = null output, @equip bEquip = null output,
 @equipdesc varchar(30)=null output, @emgroup bGroup = null output, @emcategory bCat = null output,
 @prco bCompany = null output, @employee int = null output, @trucktype varchar(10)=null output,
 @zone varchar(10)=null output,
 @haulcode bHaulCode = null output, @haulphase varchar(30) = null output, @hauljcctype tinyint =null output,
 @haulrate bUnitCost = null output, @haultotal bDollar = null output, @taxgroup bGroup = null output,
 @taxtype tinyint= null output, @shipaddress varchar(60)=null output, @city varchar(30)=null output,
 @state varchar(2)=null output, @zip varchar(12)=null output, @taxcode bTaxCode=null output,
 @matldesc varchar(30) = null output, @haulcodedesc varchar(30) = null output, @gross bUnits = null output,
 @tare bUnits = null output, @country varchar(2) = null output, @errmsg varchar(255) output)
as
---- set nocount on

declare @rcode int, @retcode int, @msg varchar(255), @fromloc bLoc

select @rcode = 0

---- validation for any null values
if @msco is null
	begin
	select @errmsg = 'Missing Company!', @rcode = 1
	goto bspexit
	end

if @mth is null
	begin
	select @errmsg = 'Missing Month!', @rcode = 1
	goto bspexit
	end

if @mstrans is null
	begin
	select @errmsg = 'Missing Batch Seq!', @rcode = 1
	goto bspexit
	end

---- get all possible values for the first column
select @saledate=MSTD.SaleDate, @vendorgroup=MSTD.VendorGroup, @matlvendor=MSTD.MatlVendor,
		@saletype=MSTD.SaleType, @custgroup=MSTD.CustGroup, @customer=MSTD.Customer, 
		@custname=ARCM.Name, @custjob = MSTD.CustJob, @custpo=MSTD.CustPO, 
		@jcco=MSTD.JCCo, @job=MSTD.Job, @jobdesc=JCJM.Description, 
		@phasegroup=MSTD.PhaseGroup, @inco=MSTD.INCo, @toloc=MSTD.ToLoc, @tolocdesc=INLM.Description,
		@matlgroup=MSTD.MatlGroup, @material=MSTD.Material, @um=MSTD.UM, @matlphase=MSTD.MatlPhase,
		@matljcctype=MSTD.MatlJCCType, @wghtum=MSTD.WghtUM, @matlunits= IsNull(MSTD.MatlUnits,0),
		@unitprice=IsNull(MSTD.UnitPrice,0), @ecm=MSTD.ECM, @matltotal=IsNull(MSTD.MatlTotal,0),
		@haulertype=MSTD.HaulerType, @haulvendor=MSTD.HaulVendor, @haulvendorname=APVM.Name,
		@truck=MSTD.Truck, @driver=MSTD.Driver, @emco=MSTD.EMCo, @equip=MSTD.Equipment,
		@equipdesc=EMEM.Description, @emgroup=MSTD.EMGroup, @emcategory=EMEM.Category,
		@prco=MSTD.PRCo, @employee=MSTD.Employee, @trucktype=MSTD.TruckType,
		@zone=MSTD.Zone, @haulcode=MSTD.HaulCode, @haulphase=MSTD.HaulPhase,
		@hauljcctype=MSTD.HaulJCCType, @haulrate=Isnull(MSTD.HaulRate,0), @haultotal=Isnull(MSTD.HaulTotal,0), 
		@taxgroup=MSTD.TaxGroup, @taxtype=MSTD.TaxType, @shipaddress=MSTD.ShipAddress,
		@city=MSTD.City, @state=MSTD.State, @zip=MSTD.Zip, @taxcode=MSTD.TaxCode,
		@fromloc=MSTD.FromLoc, @matldesc=HQMT.Description, @haulcodedesc=MSHC.Description,
		@gross=isnull(MSTD.GrossWght,0), @tare=isnull(MSTD.TareWght,0), @country=MSTD.Country
from dbo.MSTD with (nolock)
left join dbo.APVM with (nolock) on MSTD.VendorGroup = APVM.VendorGroup and MSTD.HaulVendor = APVM.Vendor
left join dbo.ARCM with (nolock) on MSTD.CustGroup = ARCM.CustGroup and MSTD.Customer = ARCM.Customer
left join dbo.INLM with (nolock) on MSTD.INCo = INLM.INCo and MSTD.ToLoc = INLM.Loc
left join dbo.JCJM with (nolock) on MSTD.JCCo = JCJM.JCCo and MSTD.Job = JCJM.Job
Left join dbo.EMEM with (nolock) on EMEM.EMCo=MSTD.EMCo and EMEM.Equipment=MSTD.Equipment
left join dbo.HQMT with (nolock) on HQMT.MatlGroup=MSTD.MatlGroup and HQMT.Material=MSTD.Material
left join dbo.MSHC with (nolock) on MSHC.MSCo=MSTD.MSCo and MSHC.HaulCode=MSTD.HaulCode
where MSTD.MSCo = @msco and MSTD.Mth = @mth and MSTD.MSTrans = @mstrans 
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to retrieve valid MSTD record.', @rcode = 1
	goto bspexit
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSHaulTicAddonGetMSTD] TO [public]
GO
