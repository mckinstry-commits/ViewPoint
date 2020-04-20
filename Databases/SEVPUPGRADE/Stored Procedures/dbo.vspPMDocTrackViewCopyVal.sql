SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMDocTrackViewCopyVal    Script Date: 12/03/08 9:33:07 AM ******/
   
   CREATE  proc [dbo].[vspPMDocTrackViewCopyVal]
    	(@CopyTo varchar(10), @msg varchar(255) output)
    as
    set nocount on
    /***********************************************************
     * CREATED BY:		GP 12/03/2008
     * MODIFIED By :
     *
     * USAGE:
     *	Validates the destination view to
	 *	make sure it doesn't already exist.
     *
     * INPUT PARAMETERS
	 *	@CopyTo		CopyTo view name
     *
     * OUTPUT PARAMETERS
     *  @msg		Error message
	 *
     * RETURN VALUE
     *   0			Success
     *   1			Failure
     *****************************************************/
    declare @rcode int
   
    set @rcode = 0

	if @CopyTo is null
    begin
    	select @msg = 'Missing Destination View Name!', @rcode = 1
       	goto vspexit
    end

	-- If view already exists, throw error.
	if exists(select top 1 1 from PMVM with(nolock) where ViewName = @CopyTo)
	begin
		select @msg = 'Destination view name already exists, please enter a new name.', @rcode = 1
		goto vspexit
	end


    vspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocTrackViewCopyVal] TO [public]
GO
