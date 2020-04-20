SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMGroupGet    Script Date: 8/28/99 9:34:28 AM ******/
CREATE  proc [dbo].[bspEMGroupGetFuel]
/********************************************************
* CREATED BY: 	TV 12/29/05
* MODIFIED BY:  TV 01/04/05 - Added all default values get that were in front end code for 5.X
*		TJL 07/24/07 - Add check for Menu Company (HQCo) in EM Module Company Master	
*				
* USAGE:
* 	Retrieves EMGroup and Material group from HQCompany
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
*	EMGroup from bHQCO
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/

(@emco bCompany = 0, @EMGroup tinyint output, @GLCo bCompany output,@MatlGroup tinyint output, @FuelCostType bEMCType output, @FuelCostCode bCostCode output,
 @TaxGroup bGroup output, @PartsCT bEMCType output, @LaborCT bEMCType output, @WOCostCodeChg bYN output, @PRCo bCompany output,
 @GLOverride bYN output, @MatlValid bYN output, @MatlMiscGLAcct bGLAcct output, @INCo bCompany output, @MatlTax bYN output, @msg varchar(60) output) 
as    
set nocount on

declare @rcode int

select @rcode = 0


if @emco is null
	begin
  		select @msg = 'Missing EM Company.', @rcode = 1
		goto bspexit
	end
else
	begin
	select top 1 1 
	from dbo.EMCO with (nolock)
	where EMCo = @emco
	if @@rowcount = 0
		begin
		select @msg = 'Company# ' + convert(varchar,@emco) + ' not setup in EM.', @rcode = 1
		goto bspexit
		end
	end

--get HQ group info
select @EMGroup = EMGroup, 
		@MatlGroup = MatlGroup,
		@TaxGroup = TaxGroup
from dbo.HQCO with (nolock)
where HQCo = @emco

--get EM Company info
select @FuelCostCode = FuelCostCode,
		 @FuelCostType = FuelCostType,
		 @PartsCT = PartsCT, 
		 @LaborCT = LaborCT,
		 @WOCostCodeChg = WOCostCodeChg,
		 @PRCo = PRCo,
		 @GLOverride = GLOverride,
		 @MatlValid = MatlValid,
		 @MatlMiscGLAcct = MatlMiscGLAcct,
		 @INCo = INCo,
		 @GLCo = GLCo,
		 @MatlTax = MatlTax
from dbo.EMCO with (nolock)
where EMCo = @emco

if @@rowcount = 0 
   begin
	select @msg = 'EM Company does not exist.', @rcode=1, @EMGroup=0
	goto bspexit
	end

if @EMGroup is Null 
	begin
   select @msg = 'EM Group not setup for EM Co ' + isnull(convert(varchar(3),@emco),'') + ' in HQ!' , @rcode=1, @EMGroup=0
	goto bspexit
	end 

If @MatlGroup is Null 
	begin
   select @msg = 'Material Group not setup for EM Co ' + isnull(convert(varchar(3),@emco),'') + ' in HQ!' , @rcode=1
	goto bspexit
	end

If @TaxGroup is Null 
	begin
   select @msg = 'Unable to get TaxGroup for EM Company' + isnull(convert(varchar(3),@emco),'') + ' in HQ!' , @rcode=1
	goto bspexit
	end

If @MatlMiscGLAcct is null
	begin
   select @msg = 'MatlMiscGLAcct missing for this EM Company!', @rcode=1
	goto bspexit
	end

/*If @INCo is null
	begin
   select @msg = 'IN Company missing for this EM Company!', @rcode=1
	goto bspexit
	end*/

IF @WOCostCodeChg is null Or @GLOverride is null Or @MatlValid is null
	begin
	select @msg =  'WOAllowCostCodeChange, GLOverride, MatlValid or MatlMiscGLAcct missing in EMCO! Cannot load form.', @rcode = 1
	goto bspexit
	end

bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMGroupGetFuel]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMGroupGetFuel] TO [public]
GO
