SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE   proc [dbo].[vspUpdateTreeViewDragDrop]
   /*************************************
   *	Created by:		GP 7/6/2010 - Issue 138988
   *	Modified by:	
   *
   *	Used by the dymanic menu to update each menu folder
   *	after drag drop performed.
   *
   **************************************/
   	(@VPUserName bVPUserName, 
   	@MoveNodeIndex tinyint,
   	@MoveNodeParentIndex tinyint = null, 
   	@MoveNodeParentFolderName varchar(50) = null, @MoveNodeKeyID bigint, 
   	@DropNodeIndex tinyint, @DropNodeLevel tinyint, @DropNodeParentIndex tinyint = null, 
   	@DropNodeParentFolderName varchar(50) = null, @DropNodeKeyID bigint,  
   	@msg varchar(255) output)
	as 
	set nocount on

	declare @rcode int, @MoveNodeParentID bigint, @DropNodeParentID bigint
	select @rcode = 0
   
	----catch items dropped from parent level 0 or null into lower level node
	--if (select ParentID from zGPDynamicMenu where KeyID = @MoveNodeKeyID) = -1
	--begin
	--	select @DropNodeParentIndex = @DropNodeParentIndex + 1
	--end

	--get parent key id's
	select @MoveNodeParentID = KeyID 
	from zGPDynamicMenu 
	where VPUserName = @VPUserName and Name = @MoveNodeParentFolderName and [Index] = @MoveNodeParentIndex 
	
	select @DropNodeParentID = KeyID 
	from zGPDynamicMenu 
	where VPUserName = @VPUserName and Name = @DropNodeParentFolderName and [Index] = @DropNodeParentIndex 
 
	--catch items dropped into blank area below tree view
	if isnull(@DropNodeKeyID, 0) = 0
	begin
		select @DropNodeLevel = null, @DropNodeParentID = -1 
	end
	
	--update move node
	update zGPDynamicMenu
	set [Index] = @DropNodeIndex, [Level] = @DropNodeLevel, ParentID = @DropNodeParentID
	where KeyID = @MoveNodeKeyID
 
 
	--increment/decrement index values if node stayed under same parent
	if @MoveNodeParentID = @DropNodeParentID
	begin
		--increment node indexes if node moved up
		if @DropNodeIndex < @MoveNodeIndex
		begin
			update zGPDynamicMenu
			set [Index] = [Index] + 1
			where ParentID = @DropNodeParentID and [Index] >= @DropNodeIndex and [Index] <= @MoveNodeIndex and KeyID <> @MoveNodeKeyID
		end	
		else --decrement if node moved down
		begin
			update zGPDynamicMenu
			set [Index] = [Index] - 1
			where ParentID = @DropNodeParentID and [Index] >= @MoveNodeIndex and [Index] <= @DropNodeIndex  and KeyID <> @MoveNodeKeyID
		end
	end
	else --increment/decrement index values if node moved to another parent
	begin
		--increment node indexes under parent node
		update zGPDynamicMenu
		set [Index] = [Index] + 1
		where ParentID = @DropNodeParentID and [Index] >= @DropNodeIndex and KeyID <> @MoveNodeKeyID
		
		--decrement node indexes under old parent node
		update zGPDynamicMenu
		set [Index] = [Index] - 1
		where ParentID = @MoveNodeParentID and [Index] >= @MoveNodeIndex and KeyID <> @MoveNodeKeyID
	end	
	
	

	
	
	vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspUpdateTreeViewDragDrop] TO [public]
GO
