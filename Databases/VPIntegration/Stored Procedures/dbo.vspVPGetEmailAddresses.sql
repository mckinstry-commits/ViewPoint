SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE       PROCEDURE [dbo].[vspVPGetEmailAddresses]
/**************************************************
* Created: JRK 08/26/2005
* Modified: 
*	
*
* Gets the collection of email addresses and corresponding names from vDDUP.
*
* Inputs:
*	none
*
* Output:
*	resultset consists of 2 fields, multi rows.
*	@errmsg		Error message
*
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@errmsg varchar(512) output)
as

set nocount on 

declare @rcode int
select @rcode = 0

select distinct FullName, EMail
from DDUP where EMail is not null
order by FullName

vspexit:
if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPGetEmailAddresses]'
return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspVPGetEmailAddresses] TO [public]
GO
