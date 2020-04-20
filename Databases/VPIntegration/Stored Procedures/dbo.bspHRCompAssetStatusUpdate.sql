SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRCompAssetStatusUpdate]
   /************************************************************************
   * CREATED:  mh 6/15/04    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Update the Status field in bHRCA.    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @asset varchar(20), @newstatus tinyint, @msg varchar(100) output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   	
   	Update dbo.HRCA set Status = @newstatus where HRCo = @hrco and Asset = @asset
   
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCompAssetStatusUpdate] TO [public]
GO
