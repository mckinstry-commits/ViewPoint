SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMCategoryVal    Script Date: 2/27/2002 11:29:37 AM ******/
   /****** Object:  Stored Procedure dbo.bspEMCategoryVal    Script Date: 8/28/99 9:32:40 AM ******/
   CREATE    proc [dbo].[bspEMCategoryVal]
   
   /******************************************************
    * Created By:  patm  09/03/98
    * Modified By:  bc   08/09/99
    *				TV 02/11/04 - 23061 added isnulls
    * Usage:
    * Validates Category from EMCM.
    *
    *
    * Input Parameters
   
    *	EMCo		Need company to validate the Category
    * 	Category
    *
    * Output Parameters
    *	JobFlag
    *	@msg	  Error message.
    * Return Value
    *  0	success
    *  1	failure
    ***************************************************/
   
   (@emco bCompany, @Category bCat, @jobflag bYN = null output, @msg varchar(60) output)
   
   as
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   select @msg = ''
   
   
    if @emco is null
      begin
      select @msg= 'Missing company.', @rcode = 1
      goto bspexit
      end
   
     if @Category is null
    	begin
    	select @msg= 'Missing Category', @rcode = 1
    	goto bspexit
    	end
   
    /* added first and last options for EMAutoUsage.  should not have any effect on another form's validation of the catgy
       unless the user names a category 'first' or 'last' */
    if @Category = 'First'
      begin
      select @msg = 'First category in EM Company ' + isnull(convert(varchar(3),@emco),'')
      goto bspexit
      end
   
    if @Category = 'Last'
      begin
      select @msg = 'Last category in EM Company ' + isnull(convert(varchar(3),@emco),'')
      goto bspexit
      end
    
   
    select @msg= Description, @jobflag = JobFlag
    	from EMCM
    	where EMCo = @emco and Category = @Category
   
    if @@rowcount = 0
    	begin
    	select @msg = 'Category is not set up.', @rcode = 1
    	goto bspexit
    	end
   
   bspexit:
   	if @rcode <> 0 select @msg = isnull(@msg,'')	--+ ' bspEMCategoryVal'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCategoryVal] TO [public]
GO
