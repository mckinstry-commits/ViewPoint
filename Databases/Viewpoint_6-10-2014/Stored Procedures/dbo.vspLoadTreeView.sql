SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE   proc [dbo].[vspLoadTreeView]
   /*************************************
   *	Created by:		GP 6/26/2010 - Issue 138988
   *	Modified by:	
   *
   *	Used by the dymanic menu to load menu.
   *
   **************************************/
   	(@VPUserName bVPUserName, @msg varchar(255) output)
	as 
	set nocount on

	declare @rcode int
	set @rcode = 0
   
	
	--fill dataset with all menu records
	--for this user, in the correct order
	select * from GPDynamicMenu
	where VPUserName = @VPUserName
	order by [Level], [Index]
	

	
	vspexit:
		return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspLoadTreeView] TO [public]
GO
