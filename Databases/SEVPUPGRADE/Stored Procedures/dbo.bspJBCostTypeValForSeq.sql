SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBCostTypeValForSeq]
    /***********************************************************
     * CREATED BY:     10/24/00 - kb
     * MODIFIED By : RM 02/28/01 - Changed Cost type to varchar(10)
     * USAGE:
     *
     * INPUT PARAMETERS
     *   JBCo      JB Co to validate against
     *
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs otherwise Description of Contract
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
     @jbco bCompany, @costtype varchar(10), @template varchar(10), @templateseq int,
     @costtypeout bJCCType output, @desc bDesc output, @catgy char(1) output, @msg varchar(255) output
   
    as
    set nocount on
   
    	declare @rcode int, @phasegrp bGroup, @apyn bYN, @pryn bYN, @inyn bYN,
       @emyn bYN, @msyn bYN, @jcyn bYN, @seqcategory varchar(10)
   
    	select @rcode = 0
   
   
    if @jbco is null
    	begin
    	select @msg = 'Missing JB Company!', @rcode = 1
    	goto bspexit
    	end
   
     select @phasegrp = PhaseGroup
     from HQCO
     where HQCo = @jbco
   
   
   /* If @costtype is numeric then try to find*/
   if isnumeric(@costtype) = 1
     begin
     select @costtypeout = CostType, @desc = Abbreviation, @catgy = JBCostTypeCategory, @msg = Description
     from JCCT
     where PhaseGroup = @phasegrp and CostType = convert(int,convert(float, @costtype))
     end
   
   /* if not numeric or not found try to find as Sort Name */
   if @@rowcount = 0
     begin
     select @costtypeout = CostType, @desc = Abbreviation, @msg = Description
     from JCCT
     where PhaseGroup = @phasegrp and
           CostType=(select min(j.CostType)
                     from bJCCT j
                     where j.PhaseGroup=@phasegrp and j.Abbreviation like @costtype + '%')
       if @@rowcount = 0
       	begin
       	select @msg = 'JC Cost Type not on file!', @rcode = 1
       	goto bspexit
       	end
   	end
   
       if not exists(select * from JBTC where JBCo = @jbco and Template = @template
         and Seq = @templateseq and CostType = @costtypeout)
           begin
           select @msg = 'Cost type is not setup for template seq ' +
             isnull(convert(varchar(10),@templateseq),'') + isnull(convert(varchar(10),@costtypeout),'')
             + @template, @rcode = 1
           goto bspexit
           end
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBCostTypeValForSeq] TO [public]
GO
