SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE       PROCEDURE [dbo].[vspVPMenuGetDbVersion]


/**************************************************
* Created: JRK 03/23/05
* Modified: 
*
* Retrieves the version of this database.
* Used as part of the VPConfigurator project, for a RemoteService
* to record what version of the Viewpoint database it is using.
*
* Inputs:
*	none
*
* Output:
*	resultset of users' accessible items for the sub folder
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@errmsg varchar(512) output)
as

set nocount on 

declare @rcode int

select @rcode = 0	--not used at this point.

SELECT Version FROM DDVS

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) 
	 + '[vspVPMenuGetDbVersion]'
	return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetDbVersion] TO [public]
GO
