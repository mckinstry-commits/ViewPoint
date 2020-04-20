SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspHQCompCodeSubgridInfo]
/***********************************************************
* CREATED BY: JM   2/6/96
* MODIFIED By : MV 01/09/03 - #17821 allow compliance on all invoices 
*
* USAGE:
* Returns HQ Compliance Code info for display in subgrid on HQCG form.
* An error is returned if any of the following occurs:
* 	no compliance code passed
*	compliance code doesn't exist in HQCP (cannot add a Compliance
*		Group member that hasn't been setup as a Compliance Code)
*
* INPUT PARAMETERS
*   @compcode		Compliance Code to validate
*
* OUTPUT PARAMETERS
*   @desc			Code description
*   @comptype		Code Type
*   @verify			Verify flag
*   @msg			Code description or error message 
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
   (@compcode bCompCode = null, @desc bDesc output, @comptype char(1) output,
   	@verify bYN output,@allinvoiceyn bYN output, @msg varchar(60) output)

 as

 set nocount on
 declare @rcode int
 select @rcode = 0
   
 if @compcode is null
	begin
   	select @msg = 'Missing Compliance Code', @rcode = 1
   	goto bspexit
   	end
   
 select @desc = Description, @comptype = CompType, @verify = Verify,
   	@allinvoiceyn = AllInvoiceYN, @msg = Description
 from HQCP
 where CompCode = @compcode
 if @@rowcount = 0
   	begin
   	select @msg = 'Compliance Code not on file!', @rcode = 1
   	goto bspexit
   	end
   
 bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQCompCodeSubgridInfo] TO [public]
GO
