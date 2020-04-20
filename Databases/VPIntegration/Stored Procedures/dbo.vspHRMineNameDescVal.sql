SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRMineNameDescVal]
/************************************************************************
* CREATED:	mh 9/12/06    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*	Get Mine Name     
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@mshaid varchar(10), @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	select @msg = MineName from dbo.HRMN with (nolock) where MSHAID = @mshaid

bspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRMineNameDescVal] TO [public]
GO
