SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE   proc [dbo].[vspDeleteTreeView]
   /*************************************
   *	Created by:		GP 6/26/2010 - Issue 138988
   *	Modified by:	
   *
   *	Used by the dymanic menu to update each menu folder
   *	with VPUserName, FolderName, and FolderIcon
   *	in zGPDynamicMenu.
   *
   **************************************/
   	(@NodeKeyID bigint, @msg varchar(255) output)
	as 
	set nocount on

	declare @rcode int
	select @rcode = 0
   
   
	--delete node by KeyID
	delete dbo.zGPDynamicMenu
	where KeyID = @NodeKeyID
	
	
	
	
	vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDeleteTreeView] TO [public]
GO
