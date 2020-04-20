SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMPCOUploadVal    Script Date: 8/28/99 9:33:05 AM ******/
   CREATE proc [dbo].[bspPMPCOUploadVal]
   (@pmco bCompany = 0, @project bJob = null, @pcotype bDocType =null,
    @pco varchar(10) = null, @msg varchar(255) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: GR 6/15/99
    *
    * USAGE:
    *   Validates PM Pending Change Order number
    *   An error is returned if any of the following occurs
    * 	no company passed
    *	no project passed
    *	no matching PCO found in PMOP
    *
    * INPUT PARAMETERS
    *   PMCO- JC Company to validate against 
   
    *   PROJECT- project to validate against
    *   PCO - Pending Change Order to validate
    *
    * OUTPUT PARAMETERS
    *   @msg - error message if error occurs otherwise Description of PCO in PMOP
   
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure
    *****************************************************/ 
   declare @rcode int
   
   select @rcode = 0
   
   if @pmco is null
   	begin
   	select @msg = 'Missing PM Company!', @rcode = 1
   	goto bspexit
   
   	end
   
   if @project is null
   	begin
   	select @msg = 'Missing Project!', @rcode = 1
   	goto bspexit
   	end
   if @pcotype is null
   	begin
   	select @msg = 'Missing PCO Type!', @rcode = 1
   	goto bspexit
   	end
   
   if @pco is null
   	begin
   	select @msg = 'Missing PCO!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   from PMOP with (nolock) 
   where PMCo = @pmco and Project = @project and PCO=@pco and PCOType = @pcotype
   if @@rowcount <> 0
   	begin
   	select @msg = 'Pending Change Order is already on file!', @rcode = 1
   	goto bspexit
   	end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCOUploadVal] TO [public]
GO
