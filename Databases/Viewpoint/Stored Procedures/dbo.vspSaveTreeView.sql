SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE   proc [dbo].[vspSaveTreeView]
   /*************************************
   *	Created by:		GP 6/26/2010 - Issue 138988
   *	Modified by:	
   *
   *	Used by the dymanic menu to insert each menu folder
   *	with VPUserName, FolderName, and FolderIcon
   *	into zGPDynamicMenu.
   *
   **************************************/
   	(@VPUserName bVPUserName, @Name varchar(50), @Index tinyint, @Level tinyint, @Type varchar(10), @ParentIndex tinyint = null, 
   	@ParentFolderName varchar(50) = null, @NodeKeyID bigint output, @msg varchar(255) output)
	as 
	set nocount on

	declare @rcode int, @ParentLevel tinyint, @ParentID bigint
	select @rcode = 0
   
   
	--insert parent
	if @Level = 0
	begin
		insert zGPDynamicMenu (VPUserName, Name, [Index], Type, ParentID)
		values (@VPUserName, @Name, @Index, @Type, -1)
		set @NodeKeyID = scope_identity()
	end
	else --insert child
	begin
		--get parent key id
		select @ParentID = KeyID 
		from zGPDynamicMenu 
		where VPUserName = @VPUserName and Name = @ParentFolderName and [Index] = @ParentIndex
			
		insert zGPDynamicMenu (VPUserName, Name, [Index], [Level], Type, ParentID)
		values (@VPUserName, @Name, @Index, @Level, @Type, @ParentID)
		set @NodeKeyID = scope_identity()
	end

	
	
	vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSaveTreeView] TO [public]
GO
