SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspPRTemplateDelete]
   /************************************************************************
   * CREATED:	mh 8/9/2004    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Delete all or part of a PR Template.  
   *	Options are "All Crafts" or "Selected Craft". 
   *	"All Crafts" deletes the entire Template.  
   *	"Selected Craft" deletes a specified craft from
   *	a Template and all the Craft/Class Template items.    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *	@prco - Payroll Company.
   *	@template - Template to delete.
   *	@deleteopt - Delete Option - "A" - All Crafts, "S" - Selected Craft.
   *	@craft - If @deleteopt = "S" then Craft to delete.  Else null.
   *	@msg - Return message if error occurs.
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@prco bCompany, @template smallint, @deleteopt char(1), @craft bCraft, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0, @msg = 'Delete Successful.'
   
   	if @deleteopt = 'S'
   	begin
   		--Craft/Class
   		delete dbo.PRTP where PRCo = @prco and Template = @template and Craft = @craft
   	
   		delete dbo.PRTE where PRCo = @prco and Template = @template and Craft = @craft
   	
   		delete dbo.PRTF where PRCo = @prco and Template = @template and Craft = @craft
   	
   		delete dbo.PRTD where PRCo = @prco and Template = @template and Craft = @craft
   	
   		delete dbo.PRTC where PRCo = @prco and Template = @template and Craft = @craft
   	
   		--Craft
   		delete dbo.PRTR where PRCo = @prco and Template = @template and Craft = @craft
   	/*
   		delete PRTI where PRCo = @prco and Template = @template and EDLType = 'E' and Craft = @craft
   		delete PRTI where PRCo = @prco and Template = @template and EDLType <> 'E' and Craft = @craft
   	*/
   		delete dbo.PRTI where PRCo = @prco and Template = @template and Craft = @craft
   	
   		delete dbo.PRCT where PRCo = @prco and Template = @template and Craft = @craft
   	
   	end
   
   	else
   
   	begin
   	
   		--Craft/Class
   		delete dbo.PRTP where PRCo = @prco and Template = @template
   	
   		delete dbo.PRTE where PRCo = @prco and Template = @template
   	
   		delete dbo.PRTF where PRCo = @prco and Template = @template
   	
   		delete dbo.PRTD where PRCo = @prco and Template = @template
   	
   		delete dbo.PRTC where PRCo = @prco and Template = @template
   	
   		--Craft
   		delete dbo.PRTR where PRCo = @prco and Template = @template
   /*		
   		delete PRTI where PRCo = @prco and Template = @template and EDLType = 'E'
   		delete PRTI where PRCo = @prco and Template = @template and EDLType <> 'E'
   */
   		delete dbo.PRTI where PRCo = @prco and Template = @template
   
   		delete dbo.PRCT where PRCo = @prco and Template = @template
   
   		delete dbo.PRTM where PRCo = @prco and Template = @template
   
   	end 
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTemplateDelete] TO [public]
GO
