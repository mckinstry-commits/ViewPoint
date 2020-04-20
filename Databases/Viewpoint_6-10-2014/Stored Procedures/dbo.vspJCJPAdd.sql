SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROC [dbo].[vspJCJPAdd]
/****************************************
 * Created By:	DANF 06/27/2005
 * Modified By:	GF 11/28/2008 - issue #131100 expanded phase description
 *
 *
 *
 * Called from JC Setup New Phase(JCJPESTID) to add new job phases.
 *
 *
 * Pass:
 * JCCo				JC Company
 * Job				JC Job
 * Phasegroup  		JC Phase Group
 * Phase			JC Phase
 * Desc				JCJP Description	
 * Contract			JC Contract
 * Item				JC Contract Item
 * ProjMinPct		JCJP Proj Min Pct
 * ActiveYN			JCJP Active Flag
 *
 *
 * Returns:
 * Error Code and Message.
 *
 *
 **************************************/
   (@JCCo bCompany, @Job bJob, @PhaseGroup tinyint, @Phase bPhase, 
	@Desc bItemDesc, @Contract bContract, @Item bContractItem, @ProjMinPct bPct,
	@ActiveYN bYN, @msg varchar(255) output)
  as
  set nocount on
  
  declare @rcode integer
  
  select @rcode = 0
  
  begin
  
  if not exists (select top 1 1 from dbo.bJCCO with (nolock) where  JCCo=@JCCo)
  	begin
  	select @msg = 'Company not set up!', @rcode = 1
  	goto bspexit
  	end
  
  if not exists (select top 1 1 from dbo.bJCJM with (nolock) where JCCo=@JCCo and Job=@Job)
  	begin
  	select @msg = 'Job is missing for the Job Master!', @rcode = 1
  	goto bspexit
  	end
  
  if not exists (select top 1 1 from dbo.bHQGP with (nolock) where Grp=@PhaseGroup)
  	begin
  	select @msg = 'Phase Group not set up in Head Quarters!', @rcode = 1
  	goto bspexit
  	end
  

  if not exists (select top 1 1 from dbo.bJCCM with (nolock) where JCCo=@JCCo and Contract=@Contract)
  	begin
  	select @msg = 'Contract is missing for the Contract Master!', @rcode = 1
  	goto bspexit
  	end

  if not exists (select top 1 1 from dbo.bJCCI with (nolock) where JCCo=@JCCo and Contract=@Contract and Item = @Item)
  	begin
  	select @msg = 'Contract item is missing for the Contract', @rcode = 1
  	goto bspexit
  	end

insert dbo.bJCJP (JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN)
VALUES (@JCCo, @Job, @PhaseGroup, @Phase, @Desc, @Contract, @Item, @ProjMinPct, @ActiveYN)
IF @@ERROR <> 0
  	begin
  	select @msg = 'Error inserting Job Phase record!', @rcode = 1
  	goto bspexit
  	end


  
  bspexit:
  	if @rcode <> 0 
		select @msg = isnull(@msg,'')
	else
		select @msg = ''
	return @rcode
  
  end

GO
GRANT EXECUTE ON  [dbo].[vspJCJPAdd] TO [public]
GO
