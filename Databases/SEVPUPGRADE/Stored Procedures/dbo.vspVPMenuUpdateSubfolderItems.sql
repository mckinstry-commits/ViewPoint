SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











CREATE           PROCEDURE [dbo].[vspVPMenuUpdateSubfolderItems]
/**************************************************
* Created: JRK 04/14/06
* Modified: 
*
* Called by RemoteHelper's UpdateDDSITable.
* First read the record, then update it with the passed in value.
*
*
* Inputs:
*   @menuseq - the only new piece of data.
*   The other inputs are for the Where clause.
*
* Output:
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@menuseq smallint = null, @co bCompany = null, @userid bVPUserName, 
	 @mod char(2)=null, @subfolder smallint = null, @itemtype char(1)=null,
	 @menuitem varchar(30)=null,
     @errmsg varchar(512) output)
as

set nocount on 

declare @rcode int, @rowsaffected int

if @menuseq is null or @co is null or @userid is null or @mod is null 
or @subfolder is null or @itemtype is null or @menuitem is null
	begin
	select @errmsg = 'Missing required input parameters: MenuSeq, Company #, User ID, Mod, Sub-Folder, Item Type or Menu Item!', @rcode = 1
	goto vspexit
	end

select @rcode = 0 

/*
		Update a row with a new sequence number
*/

UPDATE [DDSI]
 SET [MenuSeq]=@menuseq 
WHERE [Co]=@co AND [VPUserName]=@userid AND [Mod]=@mod
 AND [SubFolder]=@subfolder AND [ItemType]=@itemtype AND [MenuItem]=@menuitem

SELECT @rowsaffected = @@rowcount

-- We should get 1 and only 1 row.
if @rowsaffected <> 1
	begin
	select @errmsg = 'The row of DDSI was not updated.', @rcode = 1
	goto vspexit
	end

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) 
	 + '[vspVPMenuUpdateSubfolderItems]'
	return @rcode

















GO
GRANT EXECUTE ON  [dbo].[vspVPMenuUpdateSubfolderItems] TO [public]
GO
