SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMCommonInfoGet    Script Date: 8/28/99 9:34:28 AM ******/
CREATE  proc [dbo].[bspEMCommonInfoGet]
/********************************************************
* CREATED BY: 	DANF 07/17/07
* MODIFIED BY:  DANSO 04/28/2008 - ISSUE 127783 - Removed "@PartsCT is null" check
*				
* USAGE:
* 	Retrieves EM Information for EM Cost Ajustments
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

(@emco				bCompany = 0, 
@EMGroup			tinyint output, 
@TaxGroup			bGroup output,
@MatlGroup			tinyint output, 
@PartsCT			bEMCType output, 
@WOCostCodeChg		bYN output,
@GLOverride			bYN output,
@INCo				bCompany output,
@LaborCT			bEMCType output, 
@PRCo				bCompany output,
@MatlValid			bYN output, 
@MatlMiscGLAcct		bGLAcct output, 
@MatlTax			bYN output, 
@GLCo				bCompany output,
@FuelCostType		bEMCType output, 
@FuelCostCode		bCostCode output,
@LaborCostCodeChg	bYN output,
@DeprCostCode		bCostCode output,
@DeprCostType		bEMCType output,
@WOPostFinal		char(1) output,
@msg				varchar(60) output) 
as    
set nocount on

declare @rcode int

select @rcode = 0

if @emco = 0
	begin
	select @msg = 'Missing EM Company#!', @rcode = 1
	goto bspexit
	end

--get HQ group info
select @EMGroup = EMGroup, 
		@MatlGroup = MatlGroup,
		@TaxGroup = TaxGroup
from bHQCO with (nolock)
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
		 @MatlTax = MatlTax,
		 @LaborCostCodeChg=LaborCostCodeChg,
		 @DeprCostCode = DeprCostCode, 
		 @DeprCostType =DeprCostType,
		 @WOPostFinal = WOPostFinal
from EMCO with (nolock)
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

If @WOCostCodeChg is null Or @GLOverride is null Or @MatlValid is null
	begin
	select @msg =  'WOAllowCostCodeChange, GLOverride, MatlValid is missing in EMCO! Cannot load form.', @rcode = 1
	goto bspexit
	end

bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')	
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCommonInfoGet] TO [public]
GO
