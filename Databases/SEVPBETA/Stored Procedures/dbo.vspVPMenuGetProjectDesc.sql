SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE                   PROCEDURE [dbo].[vspVPMenuGetProjectDesc]
/**************************************************
* Created:  JK 08/10/05
* Modified: 
*
* Used by VPMenu to retrieve the description of a project so it
* can be displayed in the menu's heading.
* 
* Inputs
*       @co		Company
*	@project	Project bJob, varchar(10)
*
* Output
*	@errmsg
*
****************************************************/
	(@co bCompany = null, @project bJob = null,
	 @errmsg varchar(512) output)
as

set nocount on 

declare @rcode int
select @rcode = 0

if @co is null or @project is null
	begin
	select @errmsg = 'Missing required input parameter(s): Company # and/or Project!', @rcode = 1
	goto vspexit
	end



SELECT Description FROM JCJM 
WHERE JCCo = @co AND Job = @project

   
vspexit:
	return @rcode






GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetProjectDesc] TO [public]
GO
