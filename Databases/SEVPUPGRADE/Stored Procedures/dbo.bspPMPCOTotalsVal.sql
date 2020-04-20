SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
   CREATE proc [dbo].[bspPMPCOTotalsVal]
   /***********************************************************
    * Created By:	GF 01/12/2003
    * Modified By:
    *
    * USAGE:
    * Validates PM Pending Change Order number from PMPCOTotals form
    * 	no company passed
    *	no project passed
    *  no pco type passed
    *	no matching PCO found in PMOP
    *
    * INPUT PARAMETERS
    *   PMCO- JC Company to validate against
    *   PROJECT- project to validate against
    *   PCOTYPE - PCO Type to validate against
    *   PCO - Pending Change Order to validate
    *
    * OUTPUT PARAMETERS
    *   @issue - PCO issue if one assigned
    *	 @intext - PCO internal/external flag
    *   @msg - error message if error occurs otherwise Description of PCO in PMOP
    *
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure
    *****************************************************/
   (@pmco bCompany = null, @project bJob = null, @pcotype bDocType = null, @pco bPCO = null,
    @issue bIssue output, @intext char(1) output, @msg varchar(255) output)
   as
   set nocount on
   
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
   
   select @msg = Description, @issue = Issue, @intext = IntExt
   from PMOP with (nolock) where PMCo = @pmco and Project = @project and PCO=@pco and PCOType = @pcotype
   if @@rowcount = 0
   	begin
   	select @msg = 'PCO not on file!', @rcode = 1
   	goto bspexit
   	end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCOTotalsVal] TO [public]
GO
