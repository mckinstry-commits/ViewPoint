SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHRCodeTypeValForHREH]
   /************************************************************************
   * CREATED:  MH 1/27/04    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Validate Code type for HREH.  HREH allows code types of
   *	H, N, and P.	    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@type char(1) = 'H', @msg varchar(60) output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @type = 'H' or @type = 'P' or @type = 'N'
   		exec bspHRCodeTypeVal @type, @msg output
   	else
   		select @msg = 'Invalid History Code Type.  Must be (H, P, or N)', @rcode = 1
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCodeTypeValForHREH] TO [public]
GO
