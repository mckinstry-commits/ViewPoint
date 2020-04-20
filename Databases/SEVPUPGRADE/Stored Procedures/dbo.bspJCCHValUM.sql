SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[bspJCCHValUM]
   /*-----------------------------------------------------------------
    *	This stored procedure validates changes to the UM in PMPhaseDetail.
    *   Changes to UM are allowed if there are no actual units in JCCD or
    *	actual units or commited units in JCCP
    *
    *  Created By:  MV 05/08/01
    *				 TV - 23061 added isnulls
    *----------------------------------------------------------------*/
   (@JCCo bCompany, @Job bJob, @Phase bPhase, @CostType bJCCType, @PhaseGroup tinyint,
    @UM bUM = null, @oldum bUM = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @validcnt int, @rcode int
   
   select @rcode = 0
   
   -- Validate the UM
   if @UM is null
   	begin
   	select @msg = 'Missing Unit of Measure', @rcode = 1
   	goto bspexit
       end
   
   select @validcnt = count (*) from bHQUM where UM = @UM
   if @validcnt = 0
       begin
       select @msg = 'Not a valid Unit of Measure', @rcode = 1
       goto bspexit
       end
   
   -- get Old UM from JCCH
   select @oldum=UM from bJCCH
   where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType
   if @@rowcount = 0 goto bspexit
   
   --If changing the UM, check actual units in detail.
   If @oldum <> @UM
   begin
       --To change the UM in JCCH, ActualUnits in bJCCD must all be = 0
       select @validcnt=count(*) from  bJCCD where JCCo=@JCCo and Job=@Job
           and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType and ActualUnits <> 0
       if @validcnt > 0
           begin
           select @msg = 'Actual Units exist in JC Detail , UM may not be changed',@rcode = 1
           goto bspexit
           end
   
       --To change the UM in JCCH, ActualUnits in bJCCP must all be = 0
       select @validcnt=count(*) from  bJCCP where JCCo=@JCCo and Job=@Job
           and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType and ActualUnits <> 0
       if @validcnt > 0
           begin
           select @msg = 'Actual Units exist in JC Cost by Period , UM may not be changed',@rcode = 1
           goto bspexit
           end
   
       --To change the UM in JCCH, Commited Units in bJCCP must all be = 0
       select @validcnt=count(*) from bJCCP where JCCo=@JCCo and Job=@Job
           and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType and TotalCmtdUnits <> 0
       if @validcnt > 0
           begin
           select @msg = 'Committed Units exist in JC Cost by Period, UM may not be changed',@rcode = 1
           goto bspexit
           end
   end
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCHValUM] TO [public]
GO
