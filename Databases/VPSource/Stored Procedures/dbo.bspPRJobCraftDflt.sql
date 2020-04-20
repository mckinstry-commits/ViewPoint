SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRJobCraftDflt    Script Date: 8/28/99 9:33:24 AM ******/
    
     
     CREATE  proc [dbo].[bspPRJobCraftDflt]
     /***********************************************************
      * CREATED BY: kb 2/19/99
      * MODIFIED By : EN 10/8/02 - issue 18877 change double quotes to single
      *
      * USAGE:
      * called by PRTimeCards to return the craft from a template
      *
      * INPUT PARAMETERS
      *   
      * OUTPUT PARAMETERS
      *   @msg      error message if error occurs otherwise Description of EarnCode
      * RETURN VALUE
      *   0         success
      *   1         Failure
      *****************************************************/ 
     
     	(@prco bCompany, @craft bCraft, @template smallint, @jobcraft bCraft output, 
     		@msg varchar(200) output)
     as
     
     set nocount on
     
     declare @rcode int, @recipopt char(1)
     
     select @rcode = 0
     
     select @jobcraft=JobCraft from PRCT where PRCo = @prco and 
     	Craft = @craft and Template = @template and RecipOpt='O'
     if @@rowcount = 0
     	begin
     	select @jobcraft = null
     	end
     	
     
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRJobCraftDflt] TO [public]
GO
