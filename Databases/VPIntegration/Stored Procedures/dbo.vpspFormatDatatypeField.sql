SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vpspFormatDatatypeField  ******/
CREATE  procedure [dbo].[vpspFormatDatatypeField]
  /************************************************************************
  * CREATED:  
  * MODIFIED:      
  *    
  *           
  * Notes about Stored Procedure
  * 
  * returns 0 if successfull 
  * returns 1 and error msg if failed
  *
  *************************************************************************/
(@datatype varchar(30) = null, @unformatted_value varchar(120) = null, @msg varchar(255) output)   	
as
set nocount on
  
declare @rcode int, @inputmask varchar(30), @itemlength varchar(10)

select @rcode = 0


-- -- -- get datatype format from DDFT
select @inputmask=InputMask, @itemlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = @datatype
if @@rowcount = 0
	begin
	select @msg = 'Invalid Datatype!', @rcode = 1
	goto bspexit
	end

if isnull(@inputmask,'') = '' select @inputmask = 'L'
if isnull(@itemlength,'') = '' select @itemlength = '10'
if @inputmask in ('R','L')
  	begin
  	select @inputmask = @itemlength + @inputmask + 'N'
  	end

-- -- -- format input value
select @msg = null
exec @rcode = dbo.bspHQFormatMultiPart @unformatted_value, @inputmask, @msg output


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vpspFormatDatatypeField] TO [VCSPortal]
GO
