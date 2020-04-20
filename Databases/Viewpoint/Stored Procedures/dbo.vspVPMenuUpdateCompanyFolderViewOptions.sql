SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE           PROCEDURE [dbo].[vspVPMenuUpdateCompanyFolderViewOptions]
/**************************************************
* Created: JRK 01/20/04
* Modified: JRK 3/8/06 to use DDSF rather than vDDSF.
*
* Used by VPMenu Administrator to update the ViewOptions field of a DDSF record.
* First read the record, then update it with the passed in value.
*
*
* Inputs:
*	@co			Active Company # - needed for selection and security
*	@subfolder		Sub-Folder ID# - 0 used for module level items
*       @viewoptions		String data to update the ViewOptions field.
* Output:
*
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@co bCompany = null, @subfolder smallint = null, @viewoptions varchar(20),
	 @errmsg varchar(512) output)
as

set nocount on 

declare @rcode int, @oldviewoptions varchar(20), @rowsaffected int

if @co is null or @subfolder is null or @viewoptions is null
	begin
	select @errmsg = 'Missing required input parameters: Company #, Sub-Folder or ViewOptions!', @rcode = 1
	goto vspexit
	end

if @co = 0 	
	begin
	select @errmsg = 'Company cannot be zero!', @rcode = 1
	goto vspexit
	end

if LEN(@viewoptions) <> 3 or ISNUMERIC(@viewoptions) = 0
	begin
	select @errmsg = 'ViewOptions length must be 3 numeric chars!', @rcode = 1
	goto vspexit
	end


select @rcode = 0  --, @user = suser_sname()

/*
		Read the row matching the company and subfolder
*/
  
SELECT @oldviewoptions = ViewOptions
FROM DDSF
WHERE Co = @co AND SubFolder = @subfolder 

SELECT @rowsaffected = @@rowcount

-- We should get 1 and only 1 row.
if @rowsaffected <> 1
	begin
	select @errmsg = 'No data returned by SELECT.', @rcode = 1
	goto vspexit
	end
	
/*
		Update the row with a new ViewOptions value
*/

UPDATE DDSF 
SET ViewOptions = @viewoptions
WHERE Co = @co and SubFolder = @subfolder

SELECT @rowsaffected = @@rowcount

-- We should get 1 and only 1 row.
if @rowsaffected <> 1
	begin
	select @errmsg = 'The row of DDSF was not updated.', @rcode = 1
	goto vspexit
	end


vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) 
	 + '[vspVPMenuUpdateCompanyFolderViewOptions]'
	return @rcode















GO
GRANT EXECUTE ON  [dbo].[vspVPMenuUpdateCompanyFolderViewOptions] TO [public]
GO
