SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE  PROCEDURE [dbo].[vsp_GetInfoForFormFilter]
/********************************
* Created: kb 9/7/6
* Modified: 
*
* 
* Input:
*	@co		Current active company #
*	@form	Form name
*
* Output:
*	
*
* Return code:
*	0 = success, 1 = failure
*
*********************************/
  (@co bCompany = null, @form varchar(30) = null, @errmsg varchar(512) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @co is null or @form is null
	begin
	select @errmsg = 'Missing required input parameters: Company # and/or Form!', @rcode = 1
	goto vspexit
	end

vspexit:
	
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vsp_GetInfoForFormFilter]'
	return @rcode













GO
GRANT EXECUTE ON  [dbo].[vsp_GetInfoForFormFilter] TO [public]
GO
