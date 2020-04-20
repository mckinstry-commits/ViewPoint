SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMProjectVal    Script Date: 8/28/99 9:33:06 AM ******/
   CREATE proc [dbo].[bspPMProjectVal]
   /***********************************************************
    * CREATED BY:	CJW 11/25/97
    * MODIFIED By:	CJW 11/25/97
    *				GF 07/24/2001 - Added Contract to output params
    *				GF 02/28/2002 - Added OurFirm to output params
    *				GF 10/29/2004 - issue #24309 added DefaultStdDaysDue, DefaultRFIDaysDue to output params
    *
    *
    * USAGE:
    * validates Projects from bJCJM
    * and returns the description
    * an error is returned if any of the following occurs
    * no job passed, no project found in JCJM
    *
    * INPUT PARAMETERS
    *   PMCo   		PM Co to validate against
    *   Project    	Project to validate
    *   StatusString	Comma deliminated string for status check.
    *
    * OUTPUT PARAMETERS
    *   @Status			Staus of Job
    *	  @lockedphases		Locked Phase Flag
    *	  @projectmanager	Project Manager
    *	  @taxcode			Tax Code
    *	  @retainagePCT		Retainage percent
    *	  @contract			JC Contract
    *	  @slcompgroup		SL compliance group
    *	  @pocompgroup		PO compliance group
    *	  @ourfirm			Project OurFirm
    *	 @stddaysdue		Project Document days due
    *	 @rfidaysdue		Project Document RFI days due
    *   @msg				error message if error occurs otherwise Description of Project
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@pmco bCompany = 0, @project bJob = null, @StatusString varchar(60) = null,
    @Status tinyint output, @lockedphases bYN output, @projectmanager int output,
    @taxcode bTaxCode output, @RetainagePCT bPct output, @contract bContract output,
    @slcompgroup varchar(10) output, @pocompgroup varchar(10) output, @ourfirm bFirm output,
    @stddaysdue smallint output, @rfidaysdue smallint output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @basetaxon varchar(1)
   
   select @rcode = 0
   
   if @pmco is null
       begin
    	select @msg = 'Missing PM Company!', @rcode = 1
    	goto bspexit
    	end
   
   if @project is null
    	begin
    	select @msg = 'Missing project!', @rcode = 1
    	goto bspexit
    	end
   
   select @msg = p.Description, @Status = p.JobStatus, @lockedphases=p.LockPhases,
   		@projectmanager=p.ProjectMgr, @basetaxon=p.BaseTaxOn, @taxcode=p.TaxCode,
   		@RetainagePCT = isnull(m.RetainagePCT,0), @contract=p.Contract, @slcompgroup=p.SLCompGroup,
   		@pocompgroup=p.POCompGroup, @ourfirm=p.OurFirm,
   		@stddaysdue=DefaultStdDaysDue, @rfidaysdue=DefaultRFIDaysDue
   from JCJM p with (nolock) join JCCM m with (nolock) on m.JCCo=p.JCCo and m.Contract=p.Contract
   where p.JCCo = @pmco and p.Job = @project
   if @@rowcount = 0
       begin
       select @msg = 'Project not on file!', @rcode = 1
       goto bspexit
       end
   
   -- Check to see if the status on this project is contained in the string passed in
   if charindex(convert(varchar,@Status), @StatusString) = 0
       begin
       select @msg = 'Invalid status on project!', @rcode = 1
       goto bspexit
       end
   
   -- if missing project our firm - get from PMCO
   if isnull(@ourfirm,0) = 0
   	begin
   	select @ourfirm=OurFirm from PMCO with (nolock) where PMCo=@pmco
   	end
   
   
   
   bspexit:
       if @rcode<>0 select @msg = isnull(@msg,'') 
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMProjectVal] TO [public]
GO
