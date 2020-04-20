SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQTaxCodeSubgridInfo    Script Date: 8/28/99 9:32:48 AM ******/
   CREATE  proc [dbo].[bspHQTaxCodeSubgridInfo]
   	(@taxgroup bGroup = null, @taxcode bTaxCode = null, @desc bDesc output,
   	 @oldrate bRate output, @newrate bRate output, @msg varchar(60) output)
   as
   /***********************************************************
    * CREATED BY: JM   1/7/96
    * MODIFIED By : GG 04/29/97
	*				MV 02/01/10 = #136500 - validate GST for multilevel
	*				MV 10/19/11 - TK-09243 multilevel with GST net retention 
    *
    * USAGE:
    * Returns HQ Tax Code info for display in subgrid.
    * An error is returned if any of the following occurs:
    * 	no tax code passed
    *	tax code doesn't exist in HQTX (cannot add a TaxGroup member
    *		that hasn't been setup as a TaxCode)
    *
    * INPUT PARAMETERS
    *   TaxGroup  assigned in bHQCO
    *   TaxCode   Tax code to validate
    *
    * OUTPUT PARAMETERS
    *   @desc	HQTX.Description
    *   @oldrate	HQTX.OldRate
    *   @newrate	HQTX.NewRate
    *   @msg       error message if error occurs otherwise description of tax code
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/ 
   
   	set nocount on
   	declare @rcode int
		--@ValueAdd bYN,                      
		--@GST bYN,                 
		--@ExpenseTax bYN,                   
		--@DbtRetgGLAcct bGLAcct,                 
		--@CrdRetgGSTGLAcct bGLAcct 
   	select @rcode = 0
   
   if @taxgroup is null
   	begin
   	select @msg = 'Missing Tax Group', @rcode = 1
   	goto bspexit
   	end
   if @taxcode is null
   	begin
   	select @msg = 'Missing Tax code', @rcode = 1
   	goto bspexit
   	end
   
   select @desc = Description, 
   
   	@oldrate = OldRate,
   	@newrate = NewRate,
	--@ValueAdd = ValueAdd,                      
	--@GST = GST,                 
	--@ExpenseTax = ExpenseTax,                   
	--@DbtRetgGLAcct = DbtRetgGLAcct,                 
	--@CrdRetgGSTGLAcct = CrdRetgGSTGLAcct, 
   	@msg = Description
   	from HQTX
   	where TaxGroup = @taxgroup and TaxCode = @taxcode
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Tax Code not on file!', @rcode = 1
   	goto bspexit
   	end

	--validate GST tax code
	--if (@ValueAdd = 'Y' and @GST = 'Y' and @ExpenseTax = 'Y') and 
 -- 		(@CrdRetgGSTGLAcct is not null and @DbtRetgGLAcct is not null)
	--begin
	--select @msg = 'This GST tax code cannot be used as a multilevel!', @rcode = 1
 --  	goto bspexit
	--end                 
             
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQTaxCodeSubgridInfo] TO [public]
GO
