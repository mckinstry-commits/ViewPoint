SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLAcctVal    Script Date: 8/28/99 9:34:39 AM ******/
   CREATE  proc [dbo].[vspGLAcctValForGST]
   /* CREATED BY:	MV 03/11/10 - #136500
	* validates GL Account
    * pass in GL Co# and GL Account and Tax Code
	* validates that this Taxcode isn't used as part of a multilevel tax code
    * returns GL Account description
    *	MODIFIED BY:	
   */
   	(@glco bCompany = 0, @glacct bGLAcct = null, @taxgroup bGroup,
	 @taxcode bTaxCode, @msg varchar(200) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @glco = 0
   	begin
   	select @msg = 'Missing GL Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @glacct is null
   	begin
   	select @msg = 'Missing GL Account!', @rcode = 1
   	goto bspexit
   	end

	-- validate that this taxcode isn't part of a multilevel taxcode
	if exists(select * from HQTL with (nolock) where TaxGroup=@taxgroup and TaxLink=@taxcode)
	begin
	   	select @msg = 'Error:Tax Code is part of a multilevel. GL Acct not allowed.', @rcode = 1
		goto bspexit 
	end
   
   select @msg = Description from bGLAC where GLCo = @glco and GLAcct = @glacct
   if @@rowcount = 0
	begin
   	select @msg = 'GL Account not on file!', @rcode = 1 
	end
	

   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspGLAcctValForGST] TO [public]
GO
