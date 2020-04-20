SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRLicCodeVal]
   /************************************************************************
   * CREATED:	mh 8/17/2004    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Validate a license code against HRRE
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@co bCompany, @country char(2), @state varchar(4), @liccodetype char(1), @liccode varchar(10), @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @state is null
   	begin
   		select @msg = 'Missing License State', @rcode = 1
   		goto bspexit
   	end
   	else
   	begin
   		--exec @rcode = bspHQStateVal @state, @msg output
		exec @rcode = vspHQCountryStateVal @co, @country, @state, @msg output
   		if @rcode = 1
   			goto bspexit
   	end
   
   
   	if @liccodetype is null
   	begin
   		select @msg = 'Missing License Code Type', @rcode = 1
   		goto bspexit
   	end
   	else
   	begin
   		if @liccodetype not in ('C', 'R', 'E')
   		begin
   			select @msg = 'License code type must be ''C'', ''R'', or ''E''', @rcode = 1
   			goto bspexit
   		end
   	end
   
   	if @liccode is null
   	begin
   		select @msg = 'Missing License Code', @rcode = 1
   		goto bspexit
   	end
   	else
   	begin
   		if not exists(select 1 from dbo.HRRE with (nolock) where State = @state and 
   		LicCodeType = @liccodetype and LicCode = @liccode)
   		begin
   			select @msg = 'License Code does not exist in HRRE - HR License Endorsement/Restrictions', @rcode = 1
   			goto bspexit
   		end
   		else
   		begin
   			select @msg = LicDesc from dbo.HRRE with (nolock) where State = @state and 
   			LicCodeType = @liccodetype and LicCode = @liccode
   		end
   	end 
   
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRLicCodeVal] TO [public]
GO
