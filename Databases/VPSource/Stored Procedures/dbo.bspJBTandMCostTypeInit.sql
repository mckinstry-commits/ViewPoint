SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspJBTandMCostTypeInit]
    /***********************************************************
     * CREATED BY:     05/12/00  bc
     * MODIFIED By : 1/18/01 kb
     *				kb 6/11/2 - issue #17616 added EarnLiabTypeOpt initialization
     *				kb 7/3/2 - issue #16191 modified to check EarnLiabTypeOpt in If Exists statement
     *
     * USAGE:  inserts all cost types from JCCT for the JBCo's PhaseGroup into JBTC for a specific sequence in JBTS
     *
     * INPUT PARAMETERS
     *   JBCo      JB Co to validate against
     *   Tempalte  JBTM Template
     *   Seq       JBTS sequence
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs otherwise Description of Contract
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
     @jbco bCompany, @template varchar(10), @seq int, @msg varchar(255) output
   
    as
    set nocount on
   
    	declare @rcode int, @phasegrp bGroup,
               @apyn bYN, @emyn bYN, @inyn bYN, @jcyn bYN, @msyn bYN, @pryn bYN,
               @catgy varchar(10), @lt bLiabilityType, @et bEarnType,
               @costtype bJCCType, @earnliabopt char(1)
   
    	select @rcode = 0, @catgy = null, @lt = null, @et = null
   
   
    if @jbco is null
    	begin
    	select @msg = 'Missing JC Company!', @rcode = 1
    	goto bspexit
    	end
   
    if @template is null
    	begin
    	select @msg = 'Missing template!', @rcode = 1
    	goto bspexit
    	end
   
    if @seq is null
    	begin
    	select @msg = 'Missing template sequence!', @rcode = 1
    	goto bspexit
    	end
   
    select @phasegrp = PhaseGroup
    from HQCO
    where HQCo = @jbco
   
    select @apyn = APYN, @emyn = EMYN, @inyn = INYN, @jcyn = JCYN, @msyn = MSYN, @pryn = PRYN,
           @catgy = Category, @lt = LiabilityType, @et = EarnType, @earnliabopt = EarnLiabTypeOpt
    from JBTS
    where JBCo = @jbco and Template = @template and Seq = @seq
   
    select @costtype = min(CostType) from JCCT where PhaseGroup = @phasegrp
    while @costtype is not null
       begin
       if not exists(select * from bJBTC where JBCo = @jbco and Template = @template
        and  ((APYN = 'Y' and @apyn = 'Y')
             or (INYN = 'Y' and @inyn = 'Y')
             or (PRYN = 'Y' and @pryn = 'Y')
             or (MSYN = 'Y' and @msyn = 'Y')
             or (EMYN = 'Y' and @emyn = 'Y')
             or (JCYN = 'Y' and @jcyn = 'Y'))
             and (Category = @catgy
             or (Category is null and @catgy is null))
   			and EarnLiabTypeOpt = @earnliabopt
             and (EarnType = @et or (EarnType is null and @et is null))
             and (LiabilityType = @lt or (LiabilityType is null and @lt is null))
             and CostType = @costtype)
                   begin
                    insert into JBTC (JBCo, Template, Seq, PhaseGroup, CostType, APYN, EMYN,
                      INYN, JCYN, MSYN, PRYN, Category, LiabilityType, EarnType,
   					EarnLiabTypeOpt)
                    select @jbco, @template, @seq, @phasegrp, @costtype, @apyn, @emyn,
                      @inyn, @jcyn, @msyn, @pryn, @catgy, @lt, @et, @earnliabopt
                   end
      select @costtype = min(CostType) from JCCT where PhaseGroup = @phasegrp
        and CostType > @costtype
      end
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTandMCostTypeInit] TO [public]
GO
