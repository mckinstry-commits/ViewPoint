SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[bspPRCraftTemplateRatesMove]
   /*******************************************************************************************************
   *	Created by:	RM 02/06/01
   *	Modified by: EN 12/04/03 - issue 23061  added isnull check, with (nolock), and dbo
   *
   *	Usage:
   *		This is used to replace all old craft template and craft class template
   *		values new values.
   *
   *
   *	Input:
   *		@PRCo - Payroll company
   *		@Craft - Craft
   		@Template - Craft Template
   *
   *	Output:
   *		@rcode
   *			Success = 0
   *			Failure = 1
   *
   **********************************************************************************************************/
   (@PRCo bCompany = null,@Craft bCraft, @Template smallint, @errmsg varchar(255) output)
   AS
   
   declare @rcode int
   declare @Separator varchar(30)
   select 	@rcode = 0
   select @Separator = char(013) + char (010)
   
   select @errmsg = 'An error has occurred'
   
   if not exists(select * from dbo.bPRCO with (nolock) where PRCo=@PRCo)
       begin
       select @errmsg = isnull(@errmsg,'') + @Separator +  'Invalid PR Company!'
       select @rcode = 1
       end
   
   if not exists(select * from dbo.bPRCM with (nolock) where Craft=@Craft and PRCo = @PRCo)
       begin
       select @errmsg = isnull(@errmsg,'') + @Separator +  'The combination of ' + convert(varchar(30),@PRCo) + ' and ' + convert(varchar(30),@Craft) + 'Does not exist!'
       select @rcode = 1
       end
   
   if not exists(select * from dbo.bPRCT with (nolock) where Template=@Template)
       begin
       select @errmsg = isnull(@errmsg,'') + @Separator + 'Invalid Craft Template!'
       select @rcode= 1
       end
   
   if @rcode <> 0
   begin
   	goto bspexit
   end
   
   /*Update table bPRTC*/
   UPDATE dbo.bPRTC
   set 		OldCapLimit = NewCapLimit
   where 		PRCo = @PRCo and Craft = @Craft and Template = @Template
   
   
   /*Update table bPRTP*/
   UPDATE dbo.bPRTP
   set 		OldRate = NewRate
   where 		PRCo = @PRCo and Craft = @Craft and Template = @Template
   
   
   /*Update table bPRTF*/
   UPDATE dbo.bPRTF
   set 		OldRate = NewRate
   where 		PRCo = @PRCo and Craft = @Craft and Template = @Template
   
   
   /*Update table bPRTE*/
   UPDATE dbo.bPRTE
   set 		OldRate = NewRate
   where 		PRCo = @PRCo and Craft = @Craft and Template = @Template
   
   
   /*Update table bPRTD*/
   UPDATE dbo.bPRTD
   set 		OldRate = NewRate
   where 		PRCo = @PRCo and Craft = @Craft and Template = @Template
   
   
   /*Update table bPRTI*/
   UPDATE dbo.bPRTI
   set 		OldRate = NewRate
   where 		PRCo = @PRCo and Craft = @Craft and Template = @Template
   
   
   
   
   bspexit:
   select @errmsg = isnull(@errmsg,'') --+ @Separator + '[bspPRCraftTemplateRatesMove]'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCraftTemplateRatesMove] TO [public]
GO
