SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRREDeleteVal]
   /************************************************************************
   * CREATED:    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@state bState, @liccodetype char(1), @liccode varchar(10), @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @state is null
   	begin
   		select @msg = 'Missing State code.', @rcode = 1
   		goto bspexit
   	end
   
   	if @liccodetype is null
   	begin
   		select @msg = 'Missing License Code Type', @rcode = 1
   		goto bspexit
   	end
   
   	if @liccode is null
   	begin
   		select @msg = 'Missing License Code', @rcode = 1
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.HRDL where State = @state and LicCodeType = @liccodetype and
   	LicCode = @liccode)
   	begin
   		select @msg = 'Entries exist in HR Resource License Endorse.  Remove using Resource Master.', @rcode = 1
   		goto bspexit
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRREDeleteVal] TO [public]
GO
