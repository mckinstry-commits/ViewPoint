
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspEMGroupGet    Script Date: 8/28/99 9:34:28 AM ******/
CREATE  proc [dbo].[bspEMGroupGetFuel]
/********************************************************
* CREATED BY: 	TV 12/29/05
* MODIFIED BY:  TV 01/04/05 - Added all default values get that were in front end code for 5.X
*				TJL 07/24/07 - Add check for Menu Company (HQCo) in EM Module Company Master
*				GF 04/08/2013 NS-42352 TFS-46313 added output parameter for shop group
*
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
 @GLOverride bYN output, @MatlValid bYN output, @MatlMiscGLAcct bGLAcct output, @INCo bCompany output, @MatlTax bYN OUTPUT
 ----TFS-46313
 ,@ShopGroup TINYINT output
 ,@msg varchar(255) output) 
as    
set nocount on

declare @rcode int

SET @rcode = 0


----TFS-46313 changed get information with shop group
if @emco IS NULL
	BEGIN
	SET @msg = 'Missing EM Company.'
	SET @rcode = 1
	GOTO bspexit
	END

---- get HQ and EM Company info
SELECT  @EMGroup = HQCO.EMGroup, @MatlGroup = HQCO.MatlGroup,
		@TaxGroup = HQCO.TaxGroup, @ShopGroup = HQCO.ShopGroup,
		@FuelCostCode = EMCO.FuelCostCode, @FuelCostType = EMCO.FuelCostType,
		@PartsCT = EMCO.PartsCT, @LaborCT = EMCO.LaborCT,
		@WOCostCodeChg = EMCO.WOCostCodeChg, @PRCo = EMCO.PRCo,
		@GLOverride = EMCO.GLOverride, @MatlValid = EMCO.MatlValid,
		@MatlMiscGLAcct = EMCO.MatlMiscGLAcct, @INCo = EMCO.INCo,
		@GLCo = EMCO.GLCo, @MatlTax = EMCO.MatlTax
FROM dbo.EMCO EMCO WITH (NOLOCK)
INNER JOIN dbo.HQCO HQCO WITH (NOLOCK) ON HQCO.HQCo = EMCO.EMCo
WHERE EMCO.EMCo = @emco
if @@ROWCOUNT = 0 
	BEGIN
	SET @msg = 'EM Company does not exist.'
	SET @rcode=1
	SET @EMGroup=0
	GOTO bspexit
	END

if @EMGroup IS NULL 
	BEGIN
	SET @msg = 'EM Group not setup for EMCo: ' + dbo.vfToString(@emco) + ' in HQ!'
	SET @rcode=1
	SET @EMGroup=0
	GOTO bspexit
	END 

If @MatlGroup IS NULL  
	BEGIN
	SET @msg = 'Material Group not setup for EMCo: ' + dbo.vfToString(@emco) + ' in HQ!'
	SET @rcode=1
	GOTO bspexit
	END

If @TaxGroup IS NULL 
	BEGIN
	SET @msg = 'Tax Group not setup for EMCo:' + dbo.vfToString(@emco) + ' in HQ!'
	SET @rcode=1
	GOTO bspexit
	END

If @MatlMiscGLAcct IS NULL 
	BEGIN
	SET @msg = 'Material Misc GL Account missing for this EMCo: ' + dbo.vfToString(@emco)
	SET @rcode=1
	GOTO bspexit
	END

IF @WOCostCodeChg IS NULL OR @GLOverride IS NULL OR @MatlValid IS NULL 
	BEGIN
	SET @msg =  'WO Allow Cost Code Change, GL Override, Material Valid flag missing in EMCO! Cannot load form.'
	SET @rcode = 1
	GOTO bspexit
	END
    

----get HQ group info
--select @EMGroup = EMGroup, 
--		@MatlGroup = MatlGroup,
--		@TaxGroup = TaxGroup
--from dbo.HQCO with (nolock)
--where HQCo = @emco

----get EM Company info
--select @FuelCostCode = FuelCostCode,
--		 @FuelCostType = FuelCostType,
--		 @PartsCT = PartsCT, 
--		 @LaborCT = LaborCT,
--		 @WOCostCodeChg = WOCostCodeChg,
--		 @PRCo = PRCo,
--		 @GLOverride = GLOverride,
--		 @MatlValid = MatlValid,
--		 @MatlMiscGLAcct = MatlMiscGLAcct,
--		 @INCo = INCo,
--		 @GLCo = GLCo,
--		 @MatlTax = MatlTax
--from dbo.EMCO with (nolock)
--where EMCo = @emco

--if @@rowcount = 0 
--   begin
--	select @msg = 'EM Company does not exist.', @rcode=1, @EMGroup=0
--	goto bspexit
--	end

--if @EMGroup is Null 
--	begin
--   select @msg = 'EM Group not setup for EM Co ' + isnull(convert(varchar(3),@emco),'') + ' in HQ!' , @rcode=1, @EMGroup=0
--	goto bspexit
--	end 

--If @MatlGroup is Null 
--	begin
--   select @msg = 'Material Group not setup for EM Co ' + isnull(convert(varchar(3),@emco),'') + ' in HQ!' , @rcode=1
--	goto bspexit
--	end

--If @TaxGroup is Null 
--	begin
--   select @msg = 'Unable to get TaxGroup for EM Company' + isnull(convert(varchar(3),@emco),'') + ' in HQ!' , @rcode=1
--	goto bspexit
--	end

--If @MatlMiscGLAcct is null
--	begin
--   select @msg = 'MatlMiscGLAcct missing for this EM Company!', @rcode=1
--	goto bspexit
--	end

--IF @WOCostCodeChg is null Or @GLOverride is null Or @MatlValid is null
--	begin
--	select @msg =  'WOAllowCostCodeChange, GLOverride, MatlValid or MatlMiscGLAcct missing in EMCO! Cannot load form.', @rcode = 1
--	goto bspexit
--	end



bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO

GRANT EXECUTE ON  [dbo].[bspEMGroupGetFuel] TO [public]
GO
