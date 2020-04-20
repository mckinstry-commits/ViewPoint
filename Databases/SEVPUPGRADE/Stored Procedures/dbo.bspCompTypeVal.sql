SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspCompTypeVal    Script Date: 8/28/99 9:32:38 AM ******/
CREATE  proc [dbo].[bspCompTypeVal]
/*************************************
* validates EM Component Type
* Modified By:	GF 07/26/2012 TK-00000 need EM Group for validation
*
*
* Pass:
*	Component Type
*
* Success returns:
*	0 and Description from bEMTY
*
* Error returns:
*	1 and error message
**************************************/
(@EMGroup bGroup = NULL, @comp_type varchar(10) = null,
 @msg varchar(255) output)
as 
set nocount ON

declare @rcode INT

SET @rcode = 0

select @msg = Description
from dbo.bEMTY
WHERE EMGroup = @EMGroup
	AND ComponentTypeCode = @comp_type
if @@rowcount = 0
	begin
	select @msg = 'Not a valid Component Type Code', @rcode = 1
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCompTypeVal] TO [public]
GO
