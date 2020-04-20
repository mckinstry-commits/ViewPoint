SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Based on Stored Procedure dbo.bspVAGetInstanceInput    Script Date: 8/28/99 9:35:52 AM ******/
   CREATE   proc [dbo].[vspVAGetInstanceInput]
   /* Gets Input Type and Mask for Instance in DDDS from DDDT
    * pass in Datatype 
    * returns InputType, InputMask, MasterTable, MasterColumn, MasterDescColumn, QualifierColumn, Lookup
    * DANF 10/01/2004  - Issue 25671 Add Input Length for Right justified fields.
    * JRK  11/27/2006  - Port to VP6x.
   */
   	(@datatype char(30) = null, @msg varchar(60) output)
   as
set nocount on 
   	declare @rcode int
   	select @rcode = 0
   
   
   if @datatype is null
   
   	begin
   	select @msg = 'Missing Datatype!', @rcode = 1
   	goto bspexit
   	end
   
   select InputType, Prec, InputMask, MasterTable, MasterColumn, MasterDescColumn, QualifierColumn, Lookup, InputLength
   from DDDTShared with (nolock)
   where Datatype = @datatype
   if @@rowcount = 0
   	begin
   	select @msg = 'Datatype not setup in DDDTShared!', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVAGetInstanceInput] TO [public]
GO
