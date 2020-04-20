SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPROccupCatStatusVal]
   /************************************************************************
   * CREATED:	mh 8/14/03    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Validate Occupational Category Status.  Limit possible values to: 
   *		A = Apprentice
   *		J = Journeyman
   *		T = Trainee
   *		N = None of the above  
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@catstatus char(1), @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @catstatus is not null
   	begin	
   		if @catstatus not in ('A', 'J', 'T', 'N')
   		begin
   			select @msg = 'Category Status must be ''A'', ''J'', ''T'', or ''N''', @rcode = 1
   		end
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPROccupCatStatusVal] TO [public]
GO
