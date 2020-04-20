SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQStateVal    Script Date: 8/28/99 9:34:54 AM ******/
   CREATE   Procedure [dbo].[bspHQStateVal]
/*************************************
* validates HQ State
*
*		RM	03/26/2004	- Issue# 23061 - Added IsNulls
*		CHS 10/24/2008	- issue #130774 changed state datatype from bState to varchar(4)
*
* Pass:
*	HQ State abbreviation
*
* Success returns:
*	0 and State Name from bHQST
*
* Error returns:
*	1 and error message
**************************************/
   	(@state varchar(4) = null, @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   
   if @state is null
   	begin
   	select @msg = 'Missing HQ State', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Name from bHQST where State = @state
   	if @@rowcount = 0
   		begin
   		select @msg = isnull(@state,'') + ' is not a valid HQ State.', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQStateVal] TO [public]
GO
