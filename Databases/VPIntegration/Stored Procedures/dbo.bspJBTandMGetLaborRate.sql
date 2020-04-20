SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMGetLaborRate    Script Date: 8/28/99 9:32:34 AM ******/
   CREATE proc [dbo].[bspJBTandMGetLaborRate]
   /***********************************************************
   * CREATED BY	: 	kb 5/10/00
   * MODIFIED BY:	kb 01/19/01 issue #12030
   * 		kb 5/7/2 - issue #17286
   *     	bc 6/13/2 - issue #17646
   *		kb 7/24/2 - issue #17323 - added more labor rate options
   *		TJL 05/14/03 - Issue #21273, Return LaborRate as Datatype bUnitCost (not bDollar)
   *		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
   *		TJL 01/20/04 - Issue #23431, Rework Labor Rate and Override Rate evaluation process and priority
   *		TJL 04/12/04 - Issue #24304, Overrides can be used even if Category is not setup in Rates Table
   *		TJL 06/11/04 - Issue #24809, Related to problem induced by Issue #24304. Set @laborrate = null
   *		TJL 01/10/05 - Issue #17896, Add EffectiveDate to JBTM and NewRate/NewSpecificPrice to JBLR, JBLO, JBER, JBMO
   *
   *
   * USED IN:
   *
   * USAGE:
   *
   * INPUT PARAMETERS
   *	@co
   *	@template
   *	@category
   *	@prco
   *	@employee
   *	@craft
   *	@class
   *	@shift
   *	@earntype
   *	@factor
   *
   * OUTPUT PARAMETERS
   *	@rateopt
   *	@laborrate
   *   @msg      error message if error occurs
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
   
   (@co bCompany, @template varchar(10), @category varchar(10),
   	@prco bCompany, @employee bEmployee, @craft bCraft, @class bClass, @shift tinyint,
   	@earntype bEarnType, @factor bRate, @actualdate bDate, @effectivedate bDate, 
   	@rateopt char(1) output, @laborrate bUnitCost output, @msg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @overriderate bUnitCost, @overriderateopt char(1),
       @rateoverrideyn bYN, @newlaborrate bUnitCost, @newoverriderate bUnitCost
   
   select @rcode = 0, @laborrate = null, @newlaborrate = null, @rateopt = null
   
   /* Should Labor Overrides be considered in this process. */
   select @rateoverrideyn = LaborOverrideYN 
   from JBTM with (nolock) 
   where JBCo = @co and Template = @template
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid billing template', @rcode = 1
   	goto bspexit
   	end
   
   /* Get Labor Rate values.  Most specific first, to least specific. 
      There are 8 combinations here. */
   select @laborrate = Rate, @newlaborrate = NewRate, @rateopt = RateOpt  
   from bJBLR with (nolock) 
   where JBCo = @co and Template = @template and LaborCategory = @category
   	and EarnType = @earntype
   	and Factor = @factor   
   	and Shift = @shift
   if @@rowcount <> 0 goto Overrides
   
   select @laborrate = Rate, @newlaborrate = NewRate, @rateopt = RateOpt  
   from bJBLR with (nolock) 
   where JBCo = @co and Template = @template and LaborCategory = @category
   	and EarnType = @earntype
       and Factor = @factor   
   	and Shift is null
   if @@rowcount <> 0 goto Overrides
   
   select @laborrate = Rate, @newlaborrate = NewRate, @rateopt = RateOpt  
   from bJBLR with (nolock) 
   where JBCo = @co and Template = @template and LaborCategory = @category
   	and EarnType = @earntype
   	and Factor is null   
   	and Shift = @shift
   if @@rowcount <> 0 goto Overrides
   
   select @laborrate = Rate, @newlaborrate = NewRate, @rateopt = RateOpt  
   from bJBLR with (nolock) 
   where JBCo = @co and Template = @template and LaborCategory = @category
   	and EarnType = @earntype
       and Factor is null   
   	and Shift is null
   if @@rowcount <> 0 goto Overrides
   
   select @laborrate = Rate, @newlaborrate = NewRate, @rateopt = RateOpt  
   from bJBLR with (nolock) 
   where JBCo = @co and Template = @template and LaborCategory = @category
   	and EarnType is null
       and Factor = @factor   
   	and Shift = @shift
    if @@rowcount <> 0 goto Overrides
   
   select @laborrate = Rate, @newlaborrate = NewRate, @rateopt = RateOpt  
   from bJBLR with (nolock) 
   where JBCo = @co and Template = @template and LaborCategory = @category
   	and EarnType is null
   	and Factor = @factor  
   	and Shift is null
   if @@rowcount <> 0 goto Overrides
   
   select @laborrate = Rate, @newlaborrate = NewRate, @rateopt = RateOpt  
   from bJBLR with (nolock) 
   where JBCo = @co and Template = @template and LaborCategory = @category
   	and EarnType is null
       and Factor is null  
   	and Shift = @shift
   if @@rowcount <> 0 goto Overrides
   
   select @laborrate = Rate, @newlaborrate = NewRate, @rateopt = RateOpt  
   from bJBLR with (nolock) 
   where JBCo = @co and Template = @template and LaborCategory = @category
   	and EarnType is null
   	and Factor is null   
   	and Shift is null
   if @@rowcount <> 0 goto Overrides
   
   
   /* Get Labor Rate Override values.  Most specific first, to least specific. 
      There are 64 combinations here. */
   Overrides:
   if @rateoverrideyn = 'Y'
   	begin
   	if not exists(select 1 from bJBLO with (nolock) 
   		where JBCo = @co and Template = @template and LaborCategory = @category
   			and Craft is not null and Class is not null and Employee is not null)
   		goto fiftysixtogo
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class = @class
   		and PRCo = @prco
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class = @class
   		and PRCo = @prco
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift is null
   	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class = @class
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class = @class
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor is null
   		and Shift is null
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class = @class
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType is null
   		and Factor = @factor
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft = @craft
        	and Class = @class
        	and PRCo = @prco
    		and Employee = @employee
        	and EarnType is null
        	and Factor = @factor
        	and Shift is null
   	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class = @class
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType is null
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft = @craft
        	and Class = @class
        	and PRCo = @prco
        	and Employee = @employee
        	and EarnType is null
        	and Factor is null
        	and Shift is null
      	if @@rowcount <> 0
        	begin
         	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
         	end
   
   fiftysixtogo:
   	if not exists(select 1 from bJBLO with (nolock)
   		where JBCo = @co and Template = @template and LaborCategory = @category
   			and Craft is not null and Class is not null and Employee is null)
   		goto fortyeighttogo 
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class = @class
   		and PRCo is null
   		and Employee is null
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class = @class
   		and PRCo is null
   		and Employee is null
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift is null
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class = @class
   		and PRCo is null
   		and Employee is null
   		and EarnType = @earntype
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
    	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft = @craft
        	and Class = @class
        	and PRCo is null
        	and Employee is null
        	and EarnType = @earntype
        	and Factor is null
        	and Shift is null
     	if @@rowcount <> 0
         	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
         	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft = @craft
        	and Class = @class
        	and PRCo is null
        	and Employee is null
        	and EarnType is null
        	and Factor = @factor
        	and Shift = @shift
    	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
        	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft = @craft
        	and Class = @class
        	and PRCo is null
        	and Employee is null
        	and EarnType is null
        	and Factor = @factor
        	and Shift is null
    	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
        	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class = @class
   		and PRCo is null
   		and Employee is null
   		and EarnType is null
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
     	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft = @craft
        	and Class = @class
        	and PRCo is null
        	and Employee is null
        	and EarnType is null
        	and Factor is null
        	and Shift is null
     	if @@rowcount <> 0
        	begin
          	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
         	end
   
   fortyeighttogo:
   	if not exists(select 1 from bJBLO with (nolock)
   		where JBCo = @co and Template = @template and LaborCategory = @category
   			and Craft is not null and Class is null and Employee is not null)
   		goto fortytogo
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class is null
   		and PRCo = @prco
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class is null
   		and PRCo = @prco
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift is null
   	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class is null
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class is null
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor is null
   		and Shift is null
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class is null
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType is null
   		and Factor = @factor
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft = @craft
        	and Class is null
        	and PRCo = @prco
    		and Employee = @employee
        	and EarnType is null
        	and Factor = @factor
        	and Shift is null
   	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class is null
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType is null
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft = @craft
        	and Class is null
        	and PRCo = @prco
        	and Employee = @employee
        	and EarnType is null
        	and Factor is null
        	and Shift is null
      	if @@rowcount <> 0
        	begin
         	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
         	end
   
   fortytogo:
   	if not exists(select 1 from bJBLO with (nolock)
   		where JBCo = @co and Template = @template and LaborCategory = @category
   			and Craft is not null and Class is null and Employee is null)
   		goto thirtytwotogo
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class is null
   		and PRCo is null
   		and Employee is null
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class is null
   		and PRCo is null
   		and Employee is null
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift is null
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class is null
   		and PRCo is null
   		and Employee is null
   		and EarnType = @earntype
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
    	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft = @craft
        	and Class is null
        	and PRCo is null
        	and Employee is null
        	and EarnType = @earntype
        	and Factor is null
        	and Shift is null
     	if @@rowcount <> 0
         	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
         	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft = @craft
        	and Class is null
        	and PRCo is null
        	and Employee is null
        	and EarnType is null
        	and Factor = @factor
        	and Shift = @shift
    	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
        	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft = @craft
        	and Class is null
        	and PRCo is null
        	and Employee is null
        	and EarnType is null
        	and Factor = @factor
        	and Shift is null
    	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
        	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft = @craft
   		and Class is null
   		and PRCo is null
   		and Employee is null
   		and EarnType is null
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
     	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft = @craft
        	and Class is null
        	and PRCo is null
        	and Employee is null
        	and EarnType is null
        	and Factor is null
        	and Shift is null
     	if @@rowcount <> 0
        	begin
          	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
         	end
   
   thirtytwotogo:
   	if not exists(select 1 from bJBLO with (nolock)
   		where JBCo = @co and Template = @template and LaborCategory = @category
   			and Craft is null and Class is not null and Employee is not null)
   		goto twentyfourtogo
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class = @class
   		and PRCo = @prco
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class = @class
   		and PRCo = @prco
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift is null
   	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class = @class
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class = @class
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor is null
   		and Shift is null
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class = @class
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType is null
   		and Factor = @factor
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft is null
        	and Class = @class
        	and PRCo = @prco
    		and Employee = @employee
        	and EarnType is null
        	and Factor = @factor
        	and Shift is null
   	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class = @class
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType is null
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft is null
        	and Class = @class
        	and PRCo = @prco
        	and Employee = @employee
        	and EarnType is null
        	and Factor is null
        	and Shift is null
      	if @@rowcount <> 0
        	begin
         	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
         	end
   
   twentyfourtogo:
   	if not exists(select 1 from bJBLO with (nolock)
   		where JBCo = @co and Template = @template and LaborCategory = @category
   			and Craft is null and Class is not null and Employee is null)
   		goto sixteentogo
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class = @class
   		and PRCo is null
   		and Employee is null
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class = @class
   		and PRCo is null
   		and Employee is null
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift is null
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class = @class
   		and PRCo is null
   		and Employee is null
   		and EarnType = @earntype
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
    	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft is null
        	and Class = @class
        	and PRCo is null
        	and Employee is null
        	and EarnType = @earntype
        	and Factor is null
        	and Shift is null
     	if @@rowcount <> 0
         	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
         	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft is null
        	and Class = @class
        	and PRCo is null
        	and Employee is null
        	and EarnType is null
        	and Factor = @factor
        	and Shift = @shift
    	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
        	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft is null
        	and Class = @class
        	and PRCo is null
        	and Employee is null
        	and EarnType is null
        	and Factor = @factor
        	and Shift is null
    	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
        	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class = @class
   		and PRCo is null
   		and Employee is null
   		and EarnType is null
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
     	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft is null
        	and Class = @class
        	and PRCo is null
        	and Employee is null
        	and EarnType is null
        	and Factor is null
        	and Shift is null
     	if @@rowcount <> 0
        	begin
          	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
         	end
   
   sixteentogo:
   	if not exists(select 1 from bJBLO with (nolock)
   		where JBCo = @co and Template = @template and LaborCategory = @category
   			and Craft is null and Class is null and Employee is not null)
   		goto eighttogo
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class is null
   		and PRCo = @prco
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class is null
   		and PRCo = @prco
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift is null
   	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class is null
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class is null
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType = @earntype
   		and Factor is null
   		and Shift is null
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class is null
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType is null
   		and Factor = @factor
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft is null
        	and Class is null
        	and PRCo = @prco
    		and Employee = @employee
        	and EarnType is null
        	and Factor = @factor
        	and Shift is null
   	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class is null
   		and PRCo = @prco 
   		and Employee = @employee
   		and EarnType is null
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft is null
        	and Class is null
        	and PRCo = @prco
        	and Employee = @employee
        	and EarnType is null
        	and Factor is null
        	and Shift is null
      	if @@rowcount <> 0
        	begin
         	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
         	end
   
   eighttogo:
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class is null
   		and PRCo is null
   		and Employee is null
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class is null
   		and PRCo is null
   		and Employee is null
   		and EarnType = @earntype
   		and Factor = @factor
   		and Shift is null
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class is null
   		and PRCo is null
   		and Employee is null
   		and EarnType = @earntype
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
    	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft is null
        	and Class is null
        	and PRCo is null
        	and Employee is null
        	and EarnType = @earntype
        	and Factor is null
        	and Shift is null
     	if @@rowcount <> 0
         	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
         	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft is null
        	and Class is null
        	and PRCo is null
        	and Employee is null
        	and EarnType is null
        	and Factor = @factor
        	and Shift = @shift
    	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
        	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft is null
        	and Class is null
        	and PRCo is null
        	and Employee is null
        	and EarnType is null
        	and Factor = @factor
        	and Shift is null
    	if @@rowcount <> 0
       	begin
        	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
        	goto bspexit
        	end
   
   	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt 
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
   		and Craft is null
   		and Class is null
   		and PRCo is null
   		and Employee is null
   		and EarnType is null
   		and Factor is null
   		and Shift = @shift
   	if @@rowcount <> 0
   		begin
   		select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
   		goto bspexit
   		end
   
     	select  @overriderate = Rate, @newoverriderate = NewRate, @overriderateopt = RateOpt  
   	from bJBLO with (nolock) 
   	where JBCo = @co and Template = @template and LaborCategory = @category
        	and Craft is null
        	and Class is null
        	and PRCo is null
        	and Employee is null
        	and EarnType is null
        	and Factor is null
        	and Shift is null
     	if @@rowcount <> 0
        	begin
          	select @laborrate = @overriderate, @newlaborrate = @newoverriderate, @rateopt = @overriderateopt
         	goto bspexit
         	end
   
   	end
   
   bspexit:
   
   /* Determine whether to use OldRate or NewRate */
   if isnull(@actualdate, '1900-01-01') >= isnull(@effectivedate, '1900-01-01') select @laborrate = isnull(@newlaborrate, @laborrate)
   /* Neither LaborRate nor Override were found. */
   if @laborrate is null select @rcode = 1, @msg = 'Labor rate not found'
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTandMGetLaborRate] TO [public]
GO
