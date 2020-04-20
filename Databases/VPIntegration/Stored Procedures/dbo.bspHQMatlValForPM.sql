SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQMatlValForPM    Script Date: 8/28/99 9:36:18 AM ******/
CREATE      proc [dbo].[bspHQMatlValForPM]
/********************************************************
* CREATED BY: 	cjw 6/3/97
* MODIFIED BY:	GF	08/11/2000
*				GF	01/05/2001	- Added check for base tax on by Job or Vendor
*				GF	02/20/2002	- Added Taxable flag to output parameters for (MO)
*				GF	04/29/2009	- issue #131939 material description expanded to 60-characters
*				CHS 11/16/2009	- issue #135565
*				GF 03/15/2011 - D-01397
*				JG	06/23/2011	- TK-06041 - Setting @PriceECM=CostECM when @purchaseum <> @stdum
*
* USAGE:
* 	Retrieves the Purchasing Price, Purchasing UM, and ECM for a Material from bHQMT
*
* INPUT PARAMETERS:
*	HQ Material Group
*	HQ Material
*
* OUTPUT PARAMETERS:
*	Unit price from HQMT
*	PriceUM, PriceECM, TaxCode
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@pmco bCompany=0, @matlgroup bGroup=0, @material bMatl=null, @project bJob=null, @vendorgroup bGroup = null, @vendor bVendor = null, 
@price bUnitCost output, @stdum bUM output, @PriceECM bECM=null output, @stdcost bUnitCost output, @purchaseum bUM output,
 @salesum bUM output, @phase bPhase output, @ct bJCCType output, @stocked bYN output,
 @taxcode bTaxCode = null output, @salescost bUnitCost output, @ecm bECM output,
 @taxable bYN output, @ValidMaterial CHAR(1) = 'N' OUTPUT, @msg varchar(255) output)
as
set nocount on
   
declare @rcode int, @matldesc bItemDesc, @basetaxon varchar(1)

select @rcode = 0, @phase = NULL, @taxable = 'Y', @stocked='N', @ValidMaterial = 'N', @ct = NULL
   
if @matlgroup= 0
	begin
	select @msg = 'Missing HQ Material Group', @rcode = 1
	goto bspexit
	end

if @material is null
	begin
	select @msg = 'Missing HQ Material', @rcode = 1
	goto bspexit
	end
   
    select @price=isnull(Cost,0), @PriceECM=CostECM, @stdum=StdUM, @stdcost=isnull(Cost,0),
           @purchaseum=PurchaseUM, @salesum=SalesUM, @ct=MatlJCCostType, @phase=MatlPhase,
           @stocked=Stocked, @taxable=Taxable, @matldesc=Description, @salescost=isnull(Cost,0)
    from bHQMT where MatlGroup=@matlgroup and Material=@material
    if @@rowcount = 0
        begin
        select @msg = 'Invalid Material Code', @rcode = 1
        goto bspexit
        END
        
SET @ValidMaterial = 'Y'
	
	--	#135565 - CHS
    --if @taxable = 'Y'
    --    begin
    --    select @basetaxon=BaseTaxOn, @taxcode=TaxCode
    --    from bJCJM where JCCo=@pmco and Job=@project
    --    if @basetaxon = 'V' and @vendor is not null
    --        begin
    --        select @taxcode=TaxCode
    --        from bAPVM where VendorGroup=@vendorgroup and Vendor=@vendor
    --        end
    --    end
    --else
    --    begin
    --    select @taxcode=null
    --    end
        
	if @taxable = 'Y'
        begin
        select @basetaxon=BaseTaxOn, @taxcode=TaxCode
        from bJCJM where JCCo=@pmco and Job=@project
        if @basetaxon = 'V' and @vendor is not null
            begin
            select @taxcode=TaxCode
            from bAPVM where VendorGroup=@vendorgroup and Vendor=@vendor
            end

        if @basetaxon = 'O' and @vendor is not null 
            begin
            select @taxcode=isnull(TaxCode, @taxcode)
            from bAPVM where VendorGroup=@vendorgroup and Vendor=@vendor
            end
        end

    else
        begin
        select @taxcode=null
        end
    
        
        
   
   -- Get the converted price if the UM is different
   if @purchaseum <> @stdum
       begin
       select @price=Cost, @PriceECM=CostECM from bHQMU
       where MatlGroup=@matlgroup and Material=@material and UM=@purchaseum
       
       IF @@ROWCOUNT = 0
			BEGIN
			
			SELECT @price = 0, @PriceECM = 'E'
			
			END
       
       end
   
   if @salesum <> @stdum
       begin
       select @salescost=Cost from bHQMU
       where MatlGroup=@matlgroup and Material=@material and UM=@salesum
       end
   
   select @msg = @matldesc, @ecm = @PriceECM
   
   bspexit:
    	if @rcode <> 0 select @msg = @msg
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQMatlValForPM] TO [public]
GO
