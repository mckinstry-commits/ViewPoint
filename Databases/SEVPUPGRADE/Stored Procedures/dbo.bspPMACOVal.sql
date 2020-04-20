SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
   CREATE proc [dbo].[bspPMACOVal]
   /***********************************************************
    * CREATED BY: CJW 12/18/97
    * MODIFIED BY: LM  2/11/98
    *              GF 07/30/2001
    *				GF 01/20/2003 - issue #16548 added PMOH.IntExt to output params for initialize items
    *				GF 01/21/2005 - issue #26891 added PMOH.ApprovalDate to output params
    *
    *
    *
    * USAGE:
    *   Validates PM Approved Change Order number
    *   An error is returned if any of the following occurs
    * 	no company passed
    *	no project passed
    *	no matching ACO found in PMOH
    *
    * INPUT PARAMETERS
    *   PMCO- JC Company to validate against
    *   PROJECT- project to validate against
    *   ACO - Approved Change Order to validate
    *
    * OUTPUT PARAMETERS
    *   @issue - default ACO issue
    *   @billgroup - default bill group
    *   @msg - error message if error occurs otherwise Description of ACO in PMOH
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure
    *****************************************************/
   (@pmco bCompany = null, @project bJob = null, @aco bACO = null, @issue bIssue output,
    @billgroup bBillingGroup output, @intext char(1) output, @app_date bDate output,
    @msg varchar(255) output)
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
   
   if @aco is null
   	begin
   	select @msg = 'Missing ACO!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @issue = Issue, @billgroup = BillGroup, @intext = IntExt,
   		@app_date = ApprovalDate
   from PMOH with (nolock) where PMCo = @pmco and Project = @project and ACO = @aco
   if @@rowcount = 0
   	begin
   	select @msg = 'ACO not on file!', @rcode = 1
   	goto bspexit
   	end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMACOVal] TO [public]
GO
