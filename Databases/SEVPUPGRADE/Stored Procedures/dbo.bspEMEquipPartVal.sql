SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspEMEquipPartVal    Script Date: 4/24/2002 2:16:54 PM ******/
CREATE        proc [dbo].[bspEMEquipPartVal]
/********************************************************
* CREATED BY: 	JM 4/13/01 Ref Issue 11586: Developed per Rob/Carol to validate material in EM forms
*						TV 05/04/05 - these do nothing and adtaully return garbage.
*		EMStdMaintGroupItems, EMWOEditItems, EMWOPartsPosting, EMCostAdj
*
* MODIFIED BY:	JM 5/30/01 - Added return param @category = HQMT.Category.
*		JM 5/31/01 - Added logic layer incorporating new input param @inloc.
*		JM 6/14/01 - Corrected TaxCode return so that input param overrides INLM.TaxCode.	
*		JM 8/6/01 - Ref Issue 13870 - Added param @taxcode_in to allow procedure to decide
*			whether to pull a tax code to return as @taxcode_out.
*		JM 3/14/02 - Changed INCo from local var to input param.
*		TV 02/11/04 - 23061 added isnulls	
*		TV 06/22/05 - 29028 was needed
*		TV 09/01/05 29697 - Unit Price is not calculated correctly, Price/100, when ECM C is used.
*		TRL 02/24/08 127133 - Add output paramter for @EMEP_HQMatl
*		GF 01/09/2013 TK-20669 change description declares to 60 from 30 characters
*
*		--Issue 133464
*
* USAGE:Validates against either EMEP or HQMT, returning Material, StdUM and Stocked per the following:
*
*	If PartNo exists in EMEP with HQMatl
*		If HQMatl valid in HQMT 
*			1 - If INLoc not specified, return HQMT.StdUM, HQMT.Stocked, HQMT.Price, EMEP.Desc
*			If INLoc specified: 
*				2 - If HQMatl exists in INMT, return HQMT.StdUM, 'Y', EMEP.Desc, StdPrice per bspEMEquipPartUnitPrice
*				3 - If HQMatl does not exist in INMT, return error
*		If HQMatl invalid in HQMT 
*			If INLoc not specified
*				4 - If EMCO.MatlValid = 'N', return EMEP.Desc, EMEP.UM, Stocked = 'N', Price = 0
*				5 - If EMCO.MatlValid = 'Y', return error
*			6 - If INLoc specified, return error
*	If PartNo exists in EMEP without HQMatl
*		If INLoc not specified
*			7 - If EMCO.MatlValid = 'N', return EMEP.Desc, EMEP.UM, Stocked = 'N', Price = 0
*			8 - If EMCO.MatlValid = 'Y', return error
*		9 - If INLoc specified, return error
*	If PartNo doesn't exist in EMEP and does exist in HQMT
*		10 - If INLoc not specified, return HQMT.StdUM, HQMT.Stocked, HQMT.Price, HQMT.Desc
*		If INLoc specified: 
*			11 - If HQMatl exists in INMT, return HQMT.StdUM, 'Y', HQMT.Desc, StdPrice per bspEMEquipPartUnitPrice
*			12 - If HQMatl does not exist in INMT, return error
*	If PartNo doesn't exist in EMEP or HQMT
*		If INLoc not specified
*			13 - If EMCO.MatlValid = 'N', return Desc=null, UM = null, Stocked = 'N', Price = 0
*			14 - If EMCO.MatlValid = 'Y', return error
*		15 - If INLoc specified, return error
*
*	From the standpoint of INLoc:
*	
*	INLoc not specified
*	1 - If PartNo exists in EMEP with HQMatl and HQMatl valid in HQMT, return HQMT.StdUM, HQMT.Stocked, HQMT.Price, EMEP.Desc
*	4 - If PartNo exists in EMEP with HQMatl and HQMatl invalid in HQMT and EMCO.MatlValid = 'N', return EMEP.Desc, EMEP.UM, Stocked = 'N', Price = 0
*	5 - If PartNo exists in EMEP with HQMatl and HQMatl invalid in HQMT and EMCO.MatlValid = 'Y', return error
*	7 - If PartNo exists in EMEP without HQMatl and EMCO.MatlValid = 'N', return EMEP.Desc, EMEP.UM, Stocked = 'N', Price = 0
*	8 - If PartNo exists in EMEP without HQMatl and EMCO.MatlValid = 'Y', return error
*	10 - If PartNo doesn't exist in EMEP and does exist in HQMT, return HQMT.StdUM, HQMT.Stocked, HQMT.Price, HQMT.Desc
*	13 - If PartNo doesn't exist in EMEP or HQMT and EMCO.MatlValid = 'N', return Desc=null, UM = null, Stocked = 'N', Price = 0
*	14 - If PartNo doesn't exist in EMEP or HQMT and EMCO.MatlValid = 'Y7', return error
*
*	INLoc specified 
*	2 - If PartNo exists in EMEP with HQMatl and HQMatl valid in HQMT and HQMatl exists in INMT, return HQMT.StdUM, 'Y', EMEP.Desc, 
*   StdPrice per bspEMEquipPartUnitPrice, INLM.TaxCode if HQMT.Taxable = 'Y' for EMEP.HQMatl
*	3 - If PartNo exists in EMEP with HQMatl and HQMatl valid in HQMT and HQMatl does not exist in INMT, return error
*	6 - If PartNo exists in EMEP with HQMatl and HQMatl invalid in HQMT, return error
*	9 - If PartNo exists in EMEP without HQMatl, return error
*	11 - If PartNo doesn't exist in EMEP and does exist in HQMT and HQMatl exists in INMT, return HQMT.StdUM, 'Y', HQMT.Desc, 
*   StdPrice per bspEMEquipPartUnitPrice, INLM.TaxCode if HQMT.Taxable = 'Y' for PartNo
*	12 - If PartNo doesn't exist in EMEP and does exist in HQMT and HQMatl does not exist in INMT, return error
*	15 - If PartNo doesn't exist in EMEP or HQMT, return error
*	
   
* INPUT PARAMETERS:
*   	EM Company
*   	Equipment
*   	HQ Material Group
*Material code to be validated against either EMEP or HQMT
*
* OUTPUT PARAMETERS:
*	Material from HQMT if applicable
*	StdUM from HQMT if applicable
*	Price from HQMT if applicable
*	Stocked from HQMT if applicable
*	Category form HQMT if applicable
*	Error Message, if one
*
* RETURN VALUE:
* 	0 Success
*	1 & message Failure
**********************************************************/
@emco bCompany = null,
@equipment bEquip = null,
@matlgroup bGroup = null,
@inco bCompany = null,
@inloc bLoc = null,
@partno varchar(30)=null,
@taxcode_in bTaxCode,
@EMEP_HQMatl bMatl=null output,
@stdum bUM=null output,
@price bUnitCost=null output,	
@stocked bYN=null output,
@category varchar(10)=null output,
@taxcode_out bTaxCode=null output,
@msg varchar(255) output
    
as

set nocount on

----TK-20669
declare @rcode int, 
		@EMEP_Description_For_PartNo varchar(60),
    	@PartNo_Exists_EMEP bYN,
    	@PartNo_Exists_HQMT bYN,
    	@PartNo_Exists_INMT bYN,
    	@EMEP_HQMatl_Exists_HQMT bYN,
    	@EMEP_HQMatl_Exists_INMT bYN,
    	@EMEP_Refs_HQMatl bYN,
    	@HQMT_Description_For_PartNo varchar(60),
    	@HQMT_Description_For_EMEP_HQMatl varchar(60),
    	@INLoc_Specified bYN,
    	@INMT_Description_For_EMEP_HQMatl varchar(60),
    	@INMT_Description_For_PartNo varchar(60),
    	@EMCO_MatlValid char(1),
    	@msg1 varchar(255),
    	@numrows int,
    	@taxable bYN,
    	@perECM bECM
   
if @emco is null
begin
	select @msg = 'Missing EM Company', @rcode=1
    goto bspexit
end
    
if IsNull(@equipment,'') =''
begin
	select @msg='Missing Equipment', @rcode=1
    goto bspexit
end

if @matlgroup is null
begin
	select @msg='Missing HQ Material Group', @rcode=1
    goto bspexit
end

if IsNull(@partno,'')= ''
begin
   	select @msg='Missing Part No', @rcode=1
   	goto bspexit
end
    
select @rcode = 0, @numrows = 0, @perECM = 'E'
      
/*******************************************************************************************************************************************/
/* Get MatlValid flag in bEMCO. */
select @EMCO_MatlValid = IsNull(MatlValid,'N') from dbo.EMCO with (nolock) where EMCo = @emco

/* Define @INLoc_Specified */
if IsNull(@inloc,'') = ''
	begin
		select @INLoc_Specified = 'N'
	end
else 
	begin
		select @INLoc_Specified = 'Y'
	end 
    
/* See if @partno in EMEP - If there, get EMEP.Description and EMEP.HQMatl.*/
select @EMEP_Description_For_PartNo = Description, @EMEP_HQMatl = HQMatl 
from dbo.EMEP where EMCo = @emco and Equipment = @equipment and PartNo = @partno
select @numrows = @@rowcount

select @PartNo_Exists_EMEP = case @numrows when 0 then 'N' else 'Y' end
   
/* Define @EMEP_Refs_HQMatl */
if IsNull(@EMEP_HQMatl,'')=''
	begin
		select @EMEP_Refs_HQMatl = 'N' 
	end
else
	begin
		select @EMEP_Refs_HQMatl = 'Y'
	end
   
/* See if @partno in HQMT - If there, get HQMT.Description */
select @HQMT_Description_For_PartNo = Description 
from dbo.HQMT with (nolock) where MatlGroup = @matlgroup and Material = @partno
select @numrows = @@rowcount

select @PartNo_Exists_HQMT = case @numrows when 0 then 'N' else 'Y' end

/**Issue 127133 avoids error 8 message**/
If @PartNo_Exists_HQMT = 'Y' and IsNull(@EMEP_HQMatl,'') = ''
begin
	select @EMEP_HQMatl = @partno
end
   
/* See if @EMEP_HQMatl in HQMT - If there, get corresponding Desc */
select @HQMT_Description_For_EMEP_HQMatl = Description 
from dbo.HQMT with (nolock) where MatlGroup = @matlgroup and Material = @EMEP_HQMatl
select @numrows = @@rowcount

select @EMEP_HQMatl_Exists_HQMT = case @numrows when 0 then 'N' else 'Y' end
 
-- TV 05/04/05 - these do nothing and adtaully return garbage. No issue / nothing to test
/* See if EMEP.HQMatl in INMT 
select top 1 1 --@INMT_Description_For_EMEP_HQMatl 
from bINMT with (nolock) where INCo = @inco and Loc = @inloc and MatlGroup = @matlgroup and Material = @EMEP_HQMatl
select @numrows = @@rowcount
select @EMEP_HQMatl_Exists_INMT = case @numrows when 0 then 'N' else 'Y' end */
-- TV 06/22/05 - 29028 was needed
if exists (select top 1 1 from dbo.INMT with (nolock)
						  where INCo = @inco and Loc = @inloc and MatlGroup = @matlgroup and Material = @EMEP_HQMatl)
	begin
		select @EMEP_HQMatl_Exists_INMT = 'Y'
	end
else
	begin
   		select @EMEP_HQMatl_Exists_INMT = 'N'
   	end
/* See if PartNo in INMT  
select top 1 1 --@INMT_Description_For_PartNo 
from bINMT with (nolock) where INCo = @inco and Loc = @inloc and MatlGroup = @matlgroup and Material = @partno
select @numrows = @@rowcount
select @PartNo_Exists_INMT = case @numrows when 0 then 'N' else 'Y' end */
if exists (select top 1 1 from dbo.INMT with (nolock) 
						  where INCo = @inco and Loc = @inloc and MatlGroup = @matlgroup and Material = @partno)
   	begin
	   	select @PartNo_Exists_INMT = 'Y'
   	end
else
   	begin
   		select @PartNo_Exists_INMT = 'N'
   	end

/*******************************************************************************************************************************************/
/* 1 - If PartNo exists in EMEP with HQMatl and HQMatl valid in HQMT and INLoc not specified, return HQMT.StdUM, HQMT.Stocked, HQMT.Price, EMEP.Desc */
if @PartNo_Exists_EMEP = 'Y' and @EMEP_Refs_HQMatl = 'Y' and @EMEP_HQMatl_Exists_HQMT = 'Y' and @INLoc_Specified = 'N'
begin
	--Issue 133464
	select @stdum = UM  from dbo.EMEP with (nolock) 
	where EMCo = @emco and Equipment = @equipment and PartNo = @partno 
	and HQMatl = @EMEP_HQMatl and MatlGroup = @matlgroup
    
  	select @stdum = isnull(@stdum,StdUM), @stocked = Stocked, @price = Price, @category = Category, @msg = @EMEP_Description_For_PartNo, @perECM = PriceECM
  	from dbo.HQMT with (nolock)
  	
  	where MatlGroup = @matlgroup and Material = @EMEP_HQMatl
  	goto bspexit
end
/*******************************************************************************************************************************************/
/* 2 - If PartNo exists in EMEP with HQMatl and HQMatl valid in HQMT and INLoc specified and HQMatl exists in INMT, return HQMT.StdUM, 'Y', EMEP.Desc, StdPrice per bspEMEquipPartUnitPrice */
if @PartNo_Exists_EMEP = 'Y'  and @EMEP_Refs_HQMatl = 'Y' and @EMEP_HQMatl_Exists_HQMT = 'Y' and @INLoc_Specified = 'Y' and @EMEP_HQMatl_Exists_INMT = 'Y'
begin
	--Issue 133464
	select @stdum = UM  from dbo.EMEP with (nolock) 
	where EMCo = @emco and Equipment = @equipment and PartNo = @partno 
	and HQMatl = @EMEP_HQMatl and MatlGroup = @matlgroup
	
	/* Get @stdum, @stocked, @category */
    select @stdum = isnull(@stdum,StdUM), @stocked = 'Y',  @category = Category, @msg = @EMEP_Description_For_PartNo, @taxable = Taxable
    from dbo.HQMT with (nolock) where MatlGroup = @matlgroup and Material = @EMEP_HQMatl
    /* Get TaxCode from INLM if Taxable in HQMT */
    if @taxable = 'Y' and IsNull(@taxcode_in,'')=''
	begin
    	select @taxcode_out = TaxCode from dbo.INLM with (nolock) where INCo = @inco and Loc = @inloc
	end
	/* Get @price */
	exec @rcode = bspEMEquipPartUnitPrice @matlgroup, @inco, @inloc, @EMEP_HQMatl, @price output, @msg1 output 
    if @rcode <> 0
    begin
		select @msg = @msg1, @rcode = 1
    	goto bspexit
    end
	goto bspexit
end
/*******************************************************************************************************************************************/
/* 3 - If PartNo exists in EMEP with HQMatl and HQMatl valid in HQMT and INLoc specified and HQMatl does not exist in INMT, return error */
if @PartNo_Exists_EMEP = 'Y' and @EMEP_Refs_HQMatl = 'Y' and @EMEP_HQMatl_Exists_HQMT = 'Y' and @INLoc_Specified = 'Y' and @EMEP_HQMatl_Exists_INMT = 'N'
begin
	--select @msg='3-Matl ' + isnull(@partno,'') + ' in EMEP but EMEP.HQMatl invalid in INMT with INLoc specified!', @rcode=1
	select @msg='3-Part Code: ' + isnull(@partno,'') + ' in Equipment Parts but HQ Material: ' + @EMEP_HQMatl + 
	' invalid for IN Co: ' + convert(varchar(3),@inco) + ' and Inv Loc: ' + @inloc + '!', @rcode=1
    goto bspexit
end
/*******************************************************************************************************************************************/
/*4 - If PartNo exists in EMEP with HQMatl and HQMatl invalid in HQMT and INLoc not specified and EMCO.MatlValid = 'N', return EMEP.Desc, EMEP.UM, Stocked = 'N', Price = 0 */
if @PartNo_Exists_EMEP = 'Y' and  @EMEP_Refs_HQMatl = 'Y'  and @EMEP_HQMatl_Exists_HQMT = 'N' and @INLoc_Specified = 'N' and  @EMCO_MatlValid = 'N'
begin
	select @msg = Description, @stdum = UM, @stocked = 'N', @price = 0, @msg = @EMEP_Description_For_PartNo 
    from dbo.EMEP with (nolock) where EMCo = @emco and Equipment = @equipment and PartNo = @partno
    goto bspexit
end
/*******************************************************************************************************************************************/
/* 5 - If PartNo exists in EMEP with HQMatl and HQMatl invalid in HQMT and INLoc not specified and EMCO.MatlValid = 'Y', return error */
if @PartNo_Exists_EMEP = 'Y' and @EMEP_Refs_HQMatl = 'Y' and @EMEP_HQMatl_Exists_HQMT = 'N' and @INLoc_Specified = 'N' and  @EMCO_MatlValid = 'Y'
begin
	--select @msg='5-Matl ' + isnull(@partno,'') + ' in EMEP but EMEP.HQMatl invalid in HQMT and EMCO.MatlValid=Y!', @rcode=1
	select @msg='5-Part Code: ' + isnull(@partno,'') + ' in Equipment Parts but HQ Materiall: '+ @EMEP_HQMatl +' invalid in HQ Materials (EM Company Parameters requires valid Materials!).', @rcode=1
    goto bspexit
end
/*******************************************************************************************************************************************/
/* 6 - If PartNo exists in EMEP with HQMatl and HQMatl invalid in HQMT and INLoc specified, return error */
if @PartNo_Exists_EMEP = 'Y' and @EMEP_Refs_HQMatl = 'Y' and @EMEP_HQMatl_Exists_HQMT = 'N' and @INLoc_Specified = 'Y'
begin
	--select @msg='6-Matl ' + isnull(@partno,'') + ' in EMEP but EMEP.HQMatl invalid in HQMT and INLoc specified!', @rcode=1
	select @msg='6-Part Code: ' + isnull(@partno,'') + ' in Equipment Parts but HQ Material: ' + @EMEP_HQMatl +' invalid in HQ Materials and Inv Loc specified!', @rcode=1
	goto bspexit
end
/*******************************************************************************************************************************************/
/* 7 - If PartNo exists in EMEP without HQMatl and INLoc not specified and EMCO.MatlValid = 'N', return EMEP.Desc, EMEP.UM, Stocked = 'N', Price = 0 */
if @PartNo_Exists_EMEP = 'Y' and @EMEP_Refs_HQMatl = 'N' and @INLoc_Specified = 'N' and @EMCO_MatlValid = 'N'
begin
	select @msg = Description, @stdum = UM, @stocked = 'N', @price = 0, @msg = @EMEP_Description_For_PartNo 
    from dbo.EMEP with (nolock) where EMCo = @emco and Equipment = @equipment and PartNo = @partno
    goto bspexit
end
/*******************************************************************************************************************************************/
/* 8 - If PartNo exists in EMEP without HQMatl and INLoc not specified and EMCO.MatlValid = 'Y', return error */
if @PartNo_Exists_EMEP = 'Y' and @EMEP_Refs_HQMatl = 'N' and @INLoc_Specified = 'N' and @EMCO_MatlValid = 'Y'
begin
	--select @msg='8-Matl ' + isnull(@partno,'') + ' in EMEP but EMEP.HQMatl = null and EMCO.MatlValid=Y!', @rcode=1
	select @msg='8-Part Code: ' + isnull(@partno,'') + ' in Equipment Parts but HQ Material is blank (EM Company Parameters requires valid Materials!).', @rcode=1
	goto bspexit
end
/*******************************************************************************************************************************************/
/* 9 - If PartNo exists in EMEP without HQMatl and INLoc specified, return error */
if @PartNo_Exists_EMEP = 'Y' and @EMEP_Refs_HQMatl = 'N' and @INLoc_Specified = 'Y'
begin
	--select @msg='9-Matl ' + isnull(@partno,'') + ' in EMEP but EMEP.HQMatl = null and INLoc specified!', @rcode=1
	select @msg='9-Part Code ' + isnull(@partno,'') + ' in Equipment Parts but HQ Material is blank and INLoc specified!', @rcode=1
    goto bspexit
end
/*******************************************************************************************************************************************/
/* 10 - If PartNo doesn't exist in EMEP and does exist in HQMT and INLoc not specified, return HQMT.StdUM, HQMT.Stocked, HQMT.Price, HQMT.Desc */
if @PartNo_Exists_EMEP = 'N' and @PartNo_Exists_HQMT = 'Y' and @INLoc_Specified = 'N'
begin
	select @msg = Description, @stdum = StdUM, @stocked = Stocked, @price = Price, @category = Category, @msg = @HQMT_Description_For_PartNo, @perECM = PriceECM
    from dbo.HQMT with (nolock) where MatlGroup = @matlgroup and Material = @partno
    goto bspexit
end
/*******************************************************************************************************************************************/
/* 11 - If PartNo doesn't exist in EMEP and does exist in HQMT and INLoc specified and HQMatl exists in INMT, return HQMT.StdUM, 'Y', HQMT.Desc, StdPrice per bspEMEquipPartUnitPrice */
if @PartNo_Exists_EMEP = 'N' and @PartNo_Exists_HQMT = 'Y' and @INLoc_Specified = 'Y' and @PartNo_Exists_INMT = 'Y'
begin
	/* Get @stdum, @stocked, @category */
    select @stdum = StdUM, @stocked = 'Y',  @msg = Description, @category = Category, @taxable = Taxable
    from dbo.HQMT with (nolock) where MatlGroup = @matlgroup and Material = @partno
    /* Get TaxCode from INLM if Taxable in HQMT */
    if @taxable = 'Y' and IsNull(@taxcode_in,'')=''
	begin
    	select @taxcode_out = TaxCode from dbo.INLM with (nolock) where INCo = @inco and Loc = @inloc
	end
    /* Get @price */
    exec @rcode = bspEMEquipPartUnitPrice @matlgroup, @inco, @inloc, @partno, @price output, @msg1 output 
    if @rcode <> 0
    begin
		select @msg = @msg1, @rcode = 1
    	goto bspexit
    end
    goto bspexit
end
/*******************************************************************************************************************************************/
/* 12 - If PartNo doesn't exist in EMEP and does exist in HQMT and INLoc specified and HQMatl does not exist in INMT, return error */
if @PartNo_Exists_EMEP = 'N' and @PartNo_Exists_HQMT = 'Y' and @INLoc_Specified = 'Y' and @PartNo_Exists_INMT = 'N'
begin
	--select @msg='12-Matl ' + isnull(@partno,'') + ' not in EMEP but in HQMT but not valid in INMT and INLoc specified!', @rcode=1
	select @msg='12-Part Code: ' + isnull(@partno,'') + ' not in Equipment Parts but in HQ Materials but not valid in ' + 
	'for IN Co: ' + convert(varchar(3),@inco) + ' and Inv Loc: ' + @inloc +'!', @rcode=1
	goto bspexit
end
/*******************************************************************************************************************************************/
/* 13 - If PartNo doesn't exist in EMEP or HQMT and INLoc not specified and EMCO.MatlValid = 'N', return Desc=null, UM = null, Stocked = 'N', Price = 0 */
if @PartNo_Exists_EMEP = 'N' and @PartNo_Exists_HQMT = 'N' and @INLoc_Specified = 'N' and @EMCO_MatlValid = 'N'
begin
	select @msg = null, @stdum = null, @stocked = 'N', @price = 0, @msg = null
    goto bspexit
end
/*******************************************************************************************************************************************/
/* 14 - If PartNo doesn't exist in EMEP or HQMT and INLoc not specified and EMCO.MatlValid = 'Y', return error */
if @PartNo_Exists_EMEP = 'N' and @PartNo_Exists_HQMT = 'N' and @INLoc_Specified = 'N' and @EMCO_MatlValid = 'Y'
begin
	--select @msg='14-Matl ' + isnull(@partno,'') + ' not in EMEP or HQMT and EMCO.MatlValid=Y!', @rcode=1
	select @msg='14-Part Code: ' + isnull(@partno,'') + ' not in Equipment Parts or HQ Materials and EM Company Parameters requires valid Materials!', @rcode=1
    goto bspexit
end
/*******************************************************************************************************************************************/
/* 15 - If PartNo doesn't exist in EMEP or HQMT and INLoc specified, return error */
if @PartNo_Exists_EMEP = 'N' and @PartNo_Exists_HQMT = 'N' and @INLoc_Specified = 'Y'
begin
	--select @msg='15-Matl ' + isnull(@partno,'') + ' not in EMEP or HQMT!', @rcode=1
	select @msg='15-Part Code: ' + isnull(@partno,'') + ' not in Equipment Parts or HQ Materials!', @rcode=1
    goto bspexit
end
/*******************************************************************************************************************************************/
bspexit:

/*Issue 127133*/
If @PartNo_Exists_HQMT = 'Y' or  @EMEP_HQMatl_Exists_HQMT =  'Y' 
begin
	If IsNull(@EMEP_HQMatl,'') = ''
	begin
		select @EMEP_HQMatl = @partno
	end
end
/*Issue 127133*/

--TV 09/01/05 29697 - Unit Price is not calculated correctly, Price/100, when ECM C is used.
if @perECM <> 'E'
begin
	select @price = case @perECM when 'C' then (@price/100)
   								 when 'M' then (@price/1000)
   								 end
end
   
if @rcode<>0 
begin 
 select @msg= isnull(@msg,'') + '  Matl Group: ' + convert(varchar(3),@matlgroup)
end
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspEMEquipPartVal] TO [public]
GO
