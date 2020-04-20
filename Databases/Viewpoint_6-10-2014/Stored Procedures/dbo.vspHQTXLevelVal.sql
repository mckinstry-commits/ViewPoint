SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspHQTXLevelVal]
/***********************************************************
* Created: GG 03/09/07
* Modified:
*
* Usage:
* Determines whether a tax code multi-level option is valid. 
* Multi-level codes cannot be assigned to other multi-level codes, and
* a single level code cannot have assigned links in bHQTL.
*
* Inputs:
*   @taxgroup		TaxGroup 
*   @taxcode		TaxCode
*	@multilevel		Y = Multi-level, N = Single level 
*
* Outputs:
*	@errmsg			Error message
*
* Return Value:
*   @rcode			0 = success, 1 = error
*   
*****************************************************/ 

(@taxgroup bGroup = null, @taxcode bTaxCode = null, @multilevel bYN = null, @errmsg varchar(255) output)

as	
set nocount on
declare @rcode int
set @rcode = 0

-- check for Tax Code
if not exists(select top 1 1 from dbo.bHQTX where TaxGroup = @taxgroup and TaxCode = @taxcode)
	begin
	goto vspexit -- no need to check for links if tax code not setup yet
	end

-- check for Tax Links
if @multilevel = 'N'
	begin
	if exists(select top 1 1 from dbo.bHQTL (nolock) 
			where TaxGroup = @taxgroup and TaxCode = @taxcode)
   		begin
   		select @errmsg = 'Tax Code has links, cannot be changed to single-level', @rcode = 1
   		goto vspexit
   		end
	end
if @multilevel = 'Y'
	begin
	if exists(select top 1 1 from dbo.bHQTL (nolock)
   			where TaxGroup = @taxgroup and TaxLink = @taxcode)
   		begin
   		select @errmsg = 'Tax Code has been linked to another, cannot be changed to multi-level', @rcode = 1
   		goto vspexit
		end
	end

vspexit:
	return @rcode


grant execute on [vspHQTXLevelVal] to public

GO
GRANT EXECUTE ON  [dbo].[vspHQTXLevelVal] TO [public]
GO
