SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRRateDefault    Script Date: 8/28/99 9:33:35 AM ******/
  CREATE    proc [dbo].[bspPRRateDefault]
  /***********************************************************
   * CREATED BY: kb
   * MODIFIED By : kb 3/1/99
   * MODIFIED BY : EN 8/20/99
   *               EN 9/12/00 - Fixed to also check PRCE/PRTE for variable eanings rate to use as override
   *                             Also fixed so that rate returned is pre-factored to resolve problem of
   *                             variable earnings rate being pre-factored.
   *               EN 10/5/00 - Not including template when check for rate in bPRTE.
   *		  EN 11/6/00 - issue 11276; wasn't prefactoring if just getting rate from bPREH.
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *				EN 9/16/05 - issue 29764  change variable rate to override class rate but then compare
   *									it to the employee rate times the factor and use the greater of the two
   *				EN 10/12/05 - issue 30019  moved code to read factor so that it's available for all
   *				mh 6/1/07 - recode issue 28073 - check for a reciprocal Craft for the Template.  
   *				mh 4/9/2008 - reversed above change for 28073.  See notes below.  Issue 12778.
   *
   * USAGE:
   *
   * INPUT PARAMETERS
   *
   * OUTPUT PARAMETERS
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
 
 
   	(@prco bCompany, @employee bEmployee, @postdate bDate, @craft bCraft,
   		@class bClass, @template smallint, @shift tinyint, @earncode bEDLCode, @rate bUnitCost output,
   		@msg varchar(100) output)
   as
 
 
   set nocount on
 
   declare @rcode int, @classrate bUnitCost, @emprate bUnitCost, @effectivedate bDate, @crafteffectivedate bDate,
     @vclassrate bUnitCost, @rowcnt1 int, @rowcnt2 int, @factor bRate, @jobcraft bCraft
 
   select @rcode = 0
 
   select @emprate=HrlyRate from PREH where PRCo=@prco and Employee=@employee
 
   select @rate=@emprate
----Issue 28073 - added for 6.0 mh 
-- Issue 127778 - This code is causing problems in Timecards.  The reciprocal craft is resolved prior
-- to bspPRRateDflt getting called.  Some users override the reciprocal override.  The following code
-- will flip it back to the reciprocal craft.  By the time this sp is called the assumption will be
-- that craft/class are correct for the employee and we are just going to pull rates.  mh 4/9/2008

--	if @template is not null
--	begin
--		exec bspPRJobCraftDflt @prco, @craft, @template, @jobcraft output, @msg
--
--		if @jobcraft is not null
--		begin
--			select @craft = @jobcraft
--			--6.x recode - validate Class against JobCraft.
--			if not exists(select 1 from PRCC where PRCo = @prco and Craft = @jobcraft and Class = @class)
--			begin
--				select @msg = @class + ' class does not exist for reciprocal craft ' + @jobcraft, @rcode = 1
--				goto bspexit
--			end
--		end
--	end
----end mh 

   select @crafteffectivedate=EffectiveDate from PRCM where PRCo=@prco and Craft=@craft
 
   select @effectivedate = @crafteffectivedate
 
   select @vclassrate = 0, @classrate = 0
 
   -- get factor
   select @factor = Factor
   from PREC
   where PRCo = @prco and EarnCode = @earncode
 
   if @template is not null
 	  	begin
 	    -- look up effective date override and class rate for template
 	  	select @effectivedate= case OverEffectDate when 'Y' then
 	  		isnull(EffectiveDate,@effectivedate) else null end from PRCT where
 	  		PRCo=@prco and Craft=@craft and Template=@template
 	
 	  	if @effectivedate is null select @effectivedate = @crafteffectivedate
 	
 	    select @vclassrate = Case when @postdate >= @effectivedate then NewRate else OldRate end
 	    from PRTE
 	    where PRCo=@prco and Craft=@craft and Class=@class and Template=@template and Shift=@shift and EarnCode=@earncode
 	
 	    select @rowcnt1 = @@rowcount
 	
 	  	select @classrate = Case when @postdate >= @effectivedate then NewRate else OldRate end
 	  	from PRTP
 	    where PRCo=@prco and Craft=@craft and Class=@class and Template=@template and Shift=@shift
 	
 	    select @rowcnt2 = @@rowcount
 	
 	  	if @rowcnt1 + @rowcnt2 <> 0 goto gotclassrate
 	
 		-- Template not found for this Craft/Class; Rates will be based on Employee or Craft/Class tables
 		select @vclassrate = 0, @classrate = 0
 	
 	  	end
 
     select @vclassrate = Case when @postdate >= @effectivedate then NewRate else OldRate end
     from PRCE
     where PRCo=@prco and Craft=@craft and Class=@class and Shift=@shift and EarnCode=@earncode
 
     select @rowcnt1 = @@rowcount
 
   	select @classrate= Case when @postdate >= @effectivedate then NewRate else OldRate end
   		from PRCP where PRCo=@prco and Craft=@craft and Class=@class and Shift=@shift
 
     select @rowcnt2 = @@rowcount
 
   	if @rowcnt1 + @rowcnt2 = 0
   		begin
   		goto prefactorrate
   		end
 
   gotclassrate:
     -- use override if variable rate found
 	--#29764 modified to compare variable rate to factored emprate rather than just using variable rate to override all others
     if @vclassrate is not null and @vclassrate <> 0
 
         begin
 		select @rate = @rate * @factor --@rate was set equal to @emprate above..this prefactors @rate and prepares for @vclassrate comparison
 		if @vclassrate > @rate select @rate = @vclassrate
         goto bspexit
         end
 
     -- otherwise compare rate and classrate and use the highest of the two
     if @emprate < @classrate select @rate = @classrate
 
   prefactorrate:
     -- calculate rate x factor
     select @rate = @rate * @factor
 
 
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRRateDefault] TO [public]
GO
