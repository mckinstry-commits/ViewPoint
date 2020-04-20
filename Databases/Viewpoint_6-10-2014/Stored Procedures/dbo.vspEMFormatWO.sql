SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMFormatWO]
/************************************************************************
* CREATED:  TRL 11/17/2008 Issue 131082 Add Format for Work Order
* MODIFIED:      
*    
*           
* Notes about Stored Procedure
* 
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
(@unformatted_value varchar(10) = null output, @msg varchar(255) output)   	
as
set nocount on
  
declare @rcode int, @inputmask varchar(30), @itemlength varchar(10)

select @rcode = 0

-- get datatype format from DDFT
select @inputmask=InputMask, @itemlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bWO'
if @@rowcount = 0
begin
	select @msg = 'Datatype "bWO" is missing!', @rcode = 1
	goto vspexit
end

If  IsNull(convert(smallint,@itemlength),0)> 10
begin
	select @msg = 'Work Order: ' + @unformatted_value +' excedes field size!', @rcode = 1
	goto vspexit
end

If Len(@unformatted_value) > IsNull(convert(smallint,@itemlength),0)
begin
	select @msg = 'Work Order: ' + @unformatted_value +'!', @rcode = 1
	goto vspexit
end

if isnull(@inputmask,'') = '' 
begin
	select @inputmask = 'L'
end

if isnull(@itemlength,'') = '' 
begin
	select @itemlength = '10'
end 

if @inputmask in ('R','L')
begin
  	select @inputmask = @itemlength + @inputmask + 'N'
end

select @msg = ''
exec @rcode = dbo.bspHQFormatMultiPart @unformatted_value, @inputmask, @msg output
If @rcode = 0
begin
	select @unformatted_value = @msg
	select @msg = ''
end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMFormatWO] TO [public]
GO
