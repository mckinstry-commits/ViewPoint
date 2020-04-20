SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRAddonRateGet    Script Date: 8/28/99 9:33:17 AM ******/
   
   CREATE  proc [dbo].[bspPRAddonRateGet]
/***********************************************************
* CREATED BY: EN 10/14/99
* MODIFIED BY: EN 10/14/99
*				EN 10/7/02 - issue 18877 change double quotes to single
*				CHS	02/15/2011	- #142620 deal with divide by zero    
*
* USAGE:
* Get Addon Rate for specified craft/class.  Called from PRTimeCards form.
*
* INPUT PARAMETERS
*   @PRCo   	    PR Company
*   @EarnCode      Posted Earnings Code
*   @Craft         Craft Code
*   @Class         Class Code
*   @Template      Template
*   @PTDate        Posted to date
*
* OUTPUT PARAMETERS
*   @AddonRate     Addon Rate
*   @msg           error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
******************************************************************/
   (@PRCo bCompany = 0, @EarnCode bEDLCode = null, @Craft bCraft = null, @Class bClass = null,
    @Template smallint = null, @PTDate bDate, @AddonRate bUnitCost output, @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int, @subjtoaddons bYN, @openAddon tinyint, @addon bEDLCode, @earnfactor bRate,
       @effectdate bDate, @oldrate bUnitCost, @newrate bUnitCost, @factor bRate
   
   select @rcode = 0
   
   select @AddonRate = 0
   
   if @Craft is null goto bspexit
   
   /* validate company */
   if @PRCo is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   /* validate earnings code */
   if @EarnCode is null
   	begin
   	select @msg = 'Missing PR Earnings Code!', @rcode = 1
   	goto bspexit
   	end
   /* validate class code */
   if @Class is null
   	begin
   	select @msg = 'Missing Class Code!', @rcode = 1
   	goto bspexit
   	end
   /* validate posted to date */
   if @PTDate is null
   	begin
   	select @msg = 'Missing Posted To Date!', @rcode = 1
   	goto bspexit
   	end
   /* earnings subject to addons? */
   select @subjtoaddons=SubjToAddOns
       from PREC
       where PRCo=@PRCo and EarnCode=@EarnCode
   if @@rowcount = 0
       begin
       select @msg = 'PR Earnings Code not on file!', @rcode = 1
       goto bspexit
       end
   if @subjtoaddons = 'N' goto bspexit
   
   /* Calculate Addon Rate */
   
   /* get Craft Effective Date with possible override by Template */
   select @effectdate = EffectiveDate from bPRCM where PRCo = @PRCo and Craft = @Craft
   select @effectdate = EffectiveDate from bPRCT where PRCo = @PRCo and Craft = @Craft
   	and Template = @Template and OverEffectDate = 'Y'
   
   /* create cursor with both std and override Addons */
   declare bcAddon cursor for
   select EarnCode = EDLCode
   from bPRCI where PRCo = @PRCo and Craft = @Craft and EDLType = 'E'
   union
   select EarnCode
   from bPRCF where PRCo = @PRCo and Craft = @Craft and Class = @Class
   union
   select EarnCode = EDLCode
   from bPRTI where PRCo = @PRCo and Craft = @Craft and Template = @Template and EDLType = 'E'
   union
   select EarnCode
   from bPRTF where PRCo = @PRCo and Craft = @Craft and Class = @Class and Template = @Template
   order by EarnCode
   
   /* open Addon cursor */
   open bcAddon
   select @openAddon = 1
   
   /* loop through Addon cursor */
   next_Addon:
   	fetch next from bcAddon into @addon
   	if @@fetch_status = -1 goto end_Addon
   	if @@fetch_status <> 0 goto next_Addon
   
     	/* get Addon Earnings Code info - skip if not found or not hourly */
   	select @earnfactor = Factor
       from bPREC
       where PRCo = @PRCo and EarnCode = @addon and Method='H'
   	if @@rowcount = 0 goto next_Addon
   
   	/* get Craft, Class Addon Rates with possible override by Template */
   	select @oldrate = 0, @newrate = 0
   	select @oldrate = OldRate, @newrate = NewRate, @factor = Factor from bPRCI
           where PRCo = @PRCo and Craft = @Craft and EDLType = 'E' and EDLCode = @addon
   	select @oldrate = OldRate, @newrate = NewRate, @factor = Factor from bPRCF
           where PRCo = @PRCo and Craft = @Craft and Class = @Class and EarnCode = @addon
   	select @oldrate = OldRate, @newrate = NewRate, @factor = Factor from bPRTI
           where PRCo = @PRCo and Craft = @Craft and Template = @Template and EDLType = 'E' and EDLCode = @addon
   	select @oldrate = OldRate, @newrate = NewRate, @factor = Factor from bPRTF
           where PRCo = @PRCo and Craft = @Craft and Class = @Class and Template = @Template and EarnCode = @addon
   
       /* determine correct factor to use */
       if @factor = 0 select @factor = @earnfactor
       
		-- CHS	02/15/2011	- #142620 deal with divide by zero  
		     --  /* compute rate */
       --if @effectdate > @PTDate
       --    select @AddonRate = @AddonRate + (@oldrate / @factor)
       --else
       --    select @AddonRate = @AddonRate + (@newrate / @factor)
		
       /* compute rate */
       if @effectdate > @PTDate
           select @AddonRate = case when @factor = 0.00 then @AddonRate + 0.00 else @AddonRate + (@oldrate / @factor) end
       else
           select @AddonRate = case when @factor = 0.00 then @AddonRate + 0.00 else @AddonRate + (@newrate / @factor) end
   
       goto next_Addon
   
   end_Addon:
   	close bcAddon
   	deallocate bcAddon
   	select @openAddon = 0
   
   
   bspexit:
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRAddonRateGet] TO [public]
GO
