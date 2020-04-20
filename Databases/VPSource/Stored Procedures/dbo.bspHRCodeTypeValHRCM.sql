SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRCodeTypeValHRCM]
   /************************************************************************
   * CREATED:  MH 4/8/03    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Validate Code type for HRCM.  Need to exclude Type = 'P'
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   	(@Type char(1), @msg varchar(80) output)
   
   as
   set nocount on
   
   	declare @rcode int, @Codetype char(1)
      	select @rcode = 0
   
   	if @Type = 'P'
   	begin
   		select @msg = 'Not a valid Code Type for HR Code Master.  Use HR Position Codes.', @rcode = 1
   		goto bspexit
   	end
   	else
   	begin
   		exec @rcode = bspHRCodeTypeVal @Type, @msg output
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCodeTypeValHRCM] TO [public]
GO
