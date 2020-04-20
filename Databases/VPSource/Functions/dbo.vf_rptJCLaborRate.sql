SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION    [dbo].[vf_rptJCLaborRate]
	(@co bCompany, @template varchar(10), @category varchar(10),
   	@prco bCompany, @employee bEmployee, @craft bCraft, @class bClass, @shift tinyint,
   	@earntype bEarnType, @factor bRate, @actualdate bDate, @effectivedate bDate, @job bJob )

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
/*   if @rateoverrideyn = 'Y'
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
   		end;*/
   
   	  ;With LaborCat

	as

	(Select   JBLX.JBCo
			, JBLX.LaborCategory
			, JBLX.Craft
			, JBLX.Class
	  From JBLX		
	),

	RateOver

	as

	(Select   JBLO.JBCo
			, JBLO.Template
			, JBLO.LaborCategory
			, JBLO.PRCo
			, JBLO.Employee
			, isnull(JBLO.Craft,LaborCat.Craft) as Craft
			, isnull(JBLO.Class,LaborCat.Class) as Class
			, JBLO.EarnType
			, JBLO.Factor
			, JBLO.Shift
			, JBLO.NewRate
			, JBLO.Rate
			, JBLO.RateOpt
	  From JBLO
	  Left Join LaborCat on LaborCat.JBCo = JBLO.JBCo and LaborCat.LaborCategory=JBLO.LaborCategory 
					and isnull(LaborCat.Craft,'')=isnull(JBLO.Craft,LaborCat.Craft) and isnull(LaborCat.Class,'')=isnull(JBLO.Class,isnull(LaborCat.Class,''))
	)	



--	Select @laborrate = r.NewRate
	SELECT @overriderate = r.Rate, @newoverriderate = r.NewRate, @overriderateopt = r.RateOpt  

	From JCCD
	Join JCJM on JCJM.JCCo=JCCD.JCCo and JCJM.Job=JCCD.Job
	Join JCCM on JCCM.JCCo=JCJM.JCCo and JCCM.Contract=JCJM.Contract
	Join RateOver r on r.JBCo=JCCD.JCCo 
					and r.Template=JCCM.JBTemplate 
					and isnull(r.Craft,JCCD.Craft)=JCCD.Craft
					and isnull(r.Class,JCCD.Class)=JCCD.Class
					and isnull(r.EarnType,isnull(JCCD.EarnType,0))=isnull(JCCD.EarnType,0)
					and isnull(r.Factor,isnull(JCCD.EarnFactor,0))=isnull(JCCD.EarnFactor,0)
					and isnull(r.Shift,isnull(JCCD.Shift,0))=isnull(JCCD.Shift,0)
	Where JCCD.JCCo=@co and JCCD.Job=@job
   
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
GRANT EXECUTE ON  [dbo].[vf_rptJCLaborRate] TO [public]
GO
