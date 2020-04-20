SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCraftRatesMove    Script Date: 8/28/99 9:35:42 AM ******/
   CREATE  procedure [dbo].[bspPRCraftRatesMove]
   /************************************************************
    * CREATED BY: 	 EN 10/23/00
    * MODIFIED By :	RM 02/07/01 
   *			Changes to include Error handling
    *				EN 12/04/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * USAGE:
    * Replaces all old rates in Craft and Craft/Classes with new rates.
    *
    * INPUT PARAMETERS
    *   @prco      PR Co
    *   @craft     Craft code
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    ************************************************************/
   	@prco bCompany, @craft bCraft, @errmsg varchar(255) output
   as
   set nocount on
   
   declare @rcode int
   declare @Separator varchar(30)
   select 	@rcode = 0
   select @Separator = char(013) + char (010)
   
   select @errmsg = 'An error has occurred'
   
   if not exists(select * from dbo.bPRCO with (nolock) where PRCo=@prco)
       begin
       select @errmsg = isnull(@errmsg,'') + @Separator +  'Invalid PR Company!'
       select @rcode = 1
       end
   
   if not exists(select * from dbo.bPRCM with (nolock) where Craft=@craft and PRCo = @prco)
       begin
       select @errmsg = isnull(@errmsg,'') + @Separator +  'The combination of Company - ' + convert(varchar(30),@prco) + ' and Craft - ' + convert(varchar(30),@craft) + ' Does not exist!'
       select @rcode = 1
       end
   
   if @rcode <> 0
   begin
   	goto bspexit
   end
   
   /* copy old to new rates in bPRCI */
   update dbo.bPRCI
   set OldRate = NewRate
   where PRCo = @prco and Craft = @craft
   
   /* copy old to new rates in bPRCC */
   update dbo.bPRCC
   set OldCapLimit = NewCapLimit
   where PRCo = @prco and Craft = @craft
   
   /* copy old to new rates in bPRCP */
   update dbo.bPRCP
   set OldRate = NewRate
   where PRCo = @prco and Craft = @craft
   
   /* copy old to new rates in bPRCF */
   update dbo.bPRCF
   set OldRate = NewRate
   where PRCo = @prco and Craft = @craft
   
   /* copy old to new rates in bPRCE */
   update dbo.bPRCE
   set OldRate = NewRate
   where PRCo = @prco and Craft = @craft
   
   /* copy old to new rates in bPRCD */
   update dbo.bPRCD
   set OldRate = NewRate
   where PRCo = @prco and Craft = @craft
   
	exec @rcode = vspPRCraftMoveRateTempChk @prco, @craft, @errmsg output
   
   bspexit:
   	select @errmsg = isnull(@errmsg,'') --+ @Separator + '[bspPRCraftRatesMove]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCraftRatesMove] TO [public]
GO
