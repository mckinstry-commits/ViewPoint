SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspJCVCOSTTYPEForAlloc]
   /***********************************************************
    * Created By:  GF 03/15/2001
    * Modified By: TV - 23061 added isnulls
    *
    * USAGE:
    * validates allocation cost type.
    * if phase is null, then validate to JCCT.
    * if phase is not null, then validate to JCPC.
    *
    * INPUT PARAMETERS
    *   PhaseGroup
    *   Phase Code
    *   CostType
    *
    * OUTPUT PARAMETERS
    *   @costtypeput   Numeric value for cost type
    *   @desc          Cost Type abbreviation
    *   @msg           error message if error occurs otherwise Description returned
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@phasegroup tinyint = null, @phase bPhase = null, @costtype varchar(10) = null,
    @costtypeout bJCCType = null output, @desc varchar(60) output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @validcnt int
   
   select @rcode = 0, @validcnt = 0, @msg = ''
   
   if @phasegroup is null
   	begin
   	select @msg = 'Missing Phase Group!', @rcode = 1
   	goto bspexit
   	end
   
   if @costtype is null
   	begin
   	select @msg = 'Missing Cost Type!', @rcode = 1
   	goto bspexit
   	end
   
   -- If @costtype is numeric then try to find
   if isnumeric(@costtype) = 1
       begin
   	select @costtypeout = CostType, @desc = Abbreviation, @msg = Description
   	from bJCCT with (nolock) 
   	where PhaseGroup = @phasegroup and CostType = convert(int,convert(float, @costtype))
       end
   
   -- if not numeric or not found try to find as Sort Name
   if @@rowcount = 0
       begin
       select @costtypeout = CostType, @desc = Abbreviation, @msg = Description
   	from bJCCT with (nolock) 
   	where PhaseGroup = @phasegroup and CostType=(select min(j.CostType) from bJCCT j
               where j.PhaseGroup=@phasegroup and j.Abbreviation like @costtype + '%')
       if @@rowcount = 0
   	   begin
   	   select @msg = 'JC Cost Type not on file!', @rcode = 1
   	   goto bspexit
   	   end
       end
   
   -- if phase then validate to JCPC
   if @phase is not null
       begin
   	if not exists(select top 1 1 from bJCPC with (nolock) where PhaseGroup=@phasegroup 
   					and Phase=@phase and CostType=@costtypeout)
           begin
           select @msg = 'JC Phase Cost Type not on file!', @rcode = 1
           goto bspexit
           end
       end
   
   
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCVCOSTTYPEForAlloc] TO [public]
GO
