SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRGroupValWithInfo    Script Date: 8/28/99 9:33:21 AM ******/
   CREATE  proc [dbo].[bspPRGroupValWithInfo]
   /***********************************************************
    * CREATED BY: GG 02/24/98
    * MODIFIED By : EN 05/21/98
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				MV 04/27/11 - B-03012 - attach GL rpts to pay period.
    *
    * USAGE:
    * Validates PR Group from PRGR and returns additional information
    * 
    * INPUT PARAMETERS
    *   @prco	PR Company
    *   @prgroup	PR Group to validate
    *
    * OUTPUT PARAMETERS
    *   @cmco	CM Co# assigned to the PR Group
    *   @cmacct	CM Account assigned to the PR Group
    *   @msg      	error message if error occurs otherwise Description of PR Group
    *
    * RETURN VALUE
   
    *   0         success
    *   1         Failure
    *****************************************************/ 
   	(@prco bCompany = 0, @prgroup bGroup = null, @cmco bCompany output,
   	 @cmacct bCMAcct output, @AttachRptsYN bYN OUTPUT, @AttachTypeID BIGINT OUTPUT,
   	 @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @prgroup is null
   	begin
   	select @msg = 'Missing PR Group!', @rcode = 1
   	goto bspexit
   	end
   
   SELECT @msg = Description, @cmco = CMCo, @cmacct = CMAcct,
	@AttachRptsYN=AttachGLLedgerRpts, @AttachTypeID=AttachTypeID
   	FROM dbo.PRGR
   	WHERE PRCo = @prco AND PRGroup = @prgroup
   
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Group not on file!', @rcode = 1
   	goto bspexit
   	end
    bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRGroupValWithInfo] TO [public]
GO
