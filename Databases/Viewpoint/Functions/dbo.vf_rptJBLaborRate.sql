SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION    [dbo].[vf_rptJBLaborRate]
	(@co bCompany, @template varchar(10), @category varchar(10),
   	@prco bCompany, @employee bEmployee, @craft bCraft, @class bClass, @shift tinyint,
   	@earntype bEarnType, @factor bRate, @actualdate bDate, @effectivedate bDate )

RETURNS char(12)--numeric(12,6)
AS
BEGIN


/*   (@co bCompany, @template varchar(10), @category varchar(10),
   	@prco bCompany, @employee bEmployee, @craft bCraft, @class bClass, @shift tinyint,
   	@earntype bEarnType, @factor bRate, @actualdate bDate, @effectivedate bDate, 
   	@rateopt char(1) output, @laborrate bUnitCost output, @msg varchar(255) output)
   
   as
   
   set nocount on*/
   
   declare @rateopt char(1), @laborrate bUnitCost, @overriderate bUnitCost, @overriderateopt char(1),
       @rateoverrideyn bYN, @newlaborrate bUnitCost, @newoverriderate bUnitCost, @RateAndOpt char(20)
   
   select @laborrate = null, @newlaborrate = null, @rateopt = null, @RateAndOpt=null
   
   /* Should Labor Overrides be considered in this process. */
   select @rateoverrideyn = LaborOverrideYN 
   from JBTM with (nolock) 
   where JBCo = @co and Template = @template
/*   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid billing template', @rcode = 1
   	goto bspexit
   	end*/
   
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
--   if @laborrate is null select @rcode = 1, @msg = 'Labor rate not found'
   
select @RateAndOpt=left(convert(varchar(10),@laborrate)+ '0000000000' ,10) + ' ' +@rateopt
--------------------------------------------------------------------------------------------------------------------------------------------------
   RETURN( @RateAndOpt)

END

GO
GRANT EXECUTE ON  [dbo].[vf_rptJBLaborRate] TO [public]
GO
