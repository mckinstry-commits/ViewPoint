SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE proc [dbo].[vspJCPPudUpdate]
/****************************************************************************
* Created By:	GF 04/10/2009 - issue #133206
* Modified By:	
*
*
*
* USAGE:
* Used to update custom fields for progress from initialize and triggers
* for JC progress entry
*
* INPUT PARAMETERS:
* @sql		sequel statement
*
* OUTPUT PARAMETERS:
*
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@sql nvarchar(max) = null)

with execute as 'viewpointcs'
as
set nocount on

declare @rcode int

select @rcode = 0

exec sp_executesql @sql


bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCPPudUpdate] TO [public]
GO
