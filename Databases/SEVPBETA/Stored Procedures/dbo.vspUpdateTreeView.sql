SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE   proc [dbo].[vspUpdateTreeView]
   /*************************************
   *	Created by:		GP 6/26/2010 - Issue 138988
   *	Modified by:	
   *
   *	Used by the dymanic menu to update each menu folder
   *	with VPUserName, FolderName, and FolderIcon
   *	in zGPDynamicMenu.
   *
   **************************************/
   	(@VPUserName bVPUserName, @Name varchar(50), @Index tinyint, @Level tinyint, @ParentIndex tinyint = null, 
   	@ParentFolderName varchar(50) = null, @NodeKeyID bigint, @msg varchar(255) output)
	as 
	set nocount on

	declare @rcode int, @OldName varchar(50), @ParentLevel tinyint, @ParentID bigint
	select @rcode = 0
   
   
	--update for label text changed
	select @OldName = Name from dbo.GPDynamicMenu with (nolock) where KeyID = @NodeKeyID
	if @OldName <> @Name
	begin
		update dbo.zGPDynamicMenu
		set Name = @Name
		where KeyID = @NodeKeyID
	end
	
	


	
	
	vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspUpdateTreeView] TO [public]
GO
