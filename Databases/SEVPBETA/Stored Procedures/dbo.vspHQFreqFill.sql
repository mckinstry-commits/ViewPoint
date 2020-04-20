SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHQFreqFill]
   /*************************************
   * Created MV 3/13/06 - 6X recode
   * Returns all HQ Frequency Codes
   *  and description
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@msg varchar(60) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
 	Select Frequency,Description from HQFC with (nolock)
   	if @@rowcount = 0
   		begin
   		select @msg = 'No Frequency codes in HQFC.', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQFreqFill] TO [public]
GO
