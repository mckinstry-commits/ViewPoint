SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[vspINLocValAP]
      /*************************************
     * CREATED BY:	MV 12/11/07 - #209702
     * Modified By: 
     *
     * validates IN Locations for APUnappInvItems and
	 *	returns the reviewer group
     *
     * Pass:
     *   INCo - Inventory Company
     *   Loc - Location to be Validated
     *
     *
     * Success returns:
	 *	 ReviewerGroup
     *   Description of Location
     *
     * Error returns:
     *	1 and error message
     **************************************/
     	(@INCo bCompany = null, @Loc bLoc = null, @activeopt bYN = 'N',
         @reviewergroup varchar(10)output, @msg varchar(100) output)
     as
     	set nocount on
     	declare @rcode int, @active bYN, @matlgroup bGroup, @category varchar(10)
        	select @rcode = 0
    
     if @INCo is null
     	begin
     	select @msg = 'Missing IN Company', @rcode = 1
     	goto vspexit
     	end
    
     if @Loc is null
     	begin
     	select @msg = 'Missing IN Location', @rcode = 1
     	goto vspexit
     	end
    
     select @active=Active, @msg = Description, @reviewergroup = ReviewerGroup
         from INLM where INCo = @INCo and Loc = @Loc
    
     if @@rowcount = 0
         begin
         select @msg='Not a valid Location', @rcode=1
         goto vspexit
         end
    
     if @activeopt = 'Y' and @active = 'N'
         begin
         select @msg = 'Not an active Location', @rcode=1
         goto vspexit
         end
    
     vspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINLocValAP] TO [public]
GO
