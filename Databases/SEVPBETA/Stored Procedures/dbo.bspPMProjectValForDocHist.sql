SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspPMProjectValForDocHist]
    /***********************************************************
     * CREATED BY:   GF 06/17/2002
     * MODIFIED By : 
     *
     * USAGE:
     * validates Projects from bJCJM and returns the description
     * an error is returned if any of the following occurs
     * no job passed, no project found in JCJM or no document history
     * for job.
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
     *   @msg				error message if error occurs otherwise Description of Project
     *
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
   (@pmco bCompany = 0, @project bJob = null, @statusstring varchar(60) = null,
    @status tinyint output, @lockedphases bYN output, @projectmanager int output,
    @taxcode bTaxCode output, @RetainagePCT bPct output, @contract bContract output,
    @slcompgroup varchar(10) output, @pocompgroup varchar(10) output, @ourfirm bFirm output,
    @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @validcnt int, @basetaxon varchar(1)
   
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
   
   select @msg = p.Description, @status = p.JobStatus, @lockedphases=p.LockPhases,
    	   @projectmanager=p.ProjectMgr, @basetaxon=p.BaseTaxOn, @taxcode=p.TaxCode,
          @RetainagePCT = isnull(m.RetainagePCT,0), @contract=p.Contract, @slcompgroup=p.SLCompGroup,
          @pocompgroup=p.POCompGroup, @ourfirm=p.OurFirm
   from JCJM p with (nolock) join JCCM m with (nolock) on m.JCCo=p.JCCo and m.Contract=p.Contract
   where p.JCCo = @pmco and p.Job = @project
   if @@rowcount = 0
       begin
       select @msg = 'Project not on file!', @rcode = 1
       goto bspexit
       end
   
   -- Check to see if the status on this project is contained in the string passed in
   if charindex(convert(varchar,@status), @statusstring) = 0
       begin
       select @msg = 'Invalid status on project!', @rcode = 1
       goto bspexit
       end
   
   -- check to see if issues exist in bPMDH
   select @validcnt = count(*) from bPMDH with (nolock) where PMCo=@pmco and Project=@project
   if @validcnt = 0
   	begin
       select @msg = 'No document history exists for the project!', @rcode = 1
       goto bspexit
       end
   
   -- if missing project our firm - get from PMCO
   if isnull(@ourfirm,0) = 0
   	begin
   	select @ourfirm=OurFirm from bPMCO with (nolock) where PMCo=@pmco
   	end
   
   
   
   bspexit:
       if @rcode<>0 select @msg = isnull(@msg,'')
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMProjectValForDocHist] TO [public]
GO
