SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [dbo].[vspEMCategoryDeleteVal] 
/***********************************************************
* CREATED BY: TJL 10/05/07 - Issue #123060, Do not allow Category to be deleted when exists in related tables.
* MODIFIED BY: 
*
*
*USAGE:
* 	Warns of existing records that would be orphaned in other 
*	tables if Category record is deleted.
* 
* 	Current tables being checked:
*		bEMEM
*		bEMRR
*		bEMTC
*		bEMUC
*		bEMRD
*
*
*INPUT PARAMETERS:
*	@emco		EMCo to validate against 
*	@category   Category value to check
*
*OUTPUT PARAMETERS:
*	@errormsg   Error message if error occurs
*
*RETURN VALUE:
*	0			Success
*	1			Failure
*****************************************************/ 
   
@emco bCompany = NULL, 
@category bCat = NULL,
@errormsg varchar(255) OUTPUT
   
AS
SET NOCOUNT ON
   
declare @rcode int

--Verify Category does not exist on pieces of equipment in Equipment Master (bEMEM)
if exists(select top 1 1 from bEMEM with (nolock) where EMCo = @emco and Category = @category)
	begin
	select @errormsg = 'Category exists on piece(s) of equipment in equipment master.'
	goto ErrorHandler
	end

--Verify Category does not exist in Revenue Rates (bEMRR)
if exists(select top 1 1 from bEMRR with (nolock) where EMCo = @emco and Category = @category)
	begin
	select @errormsg = 'Revenue Rate(s) exist for this category.'
	goto ErrorHandler
	end
   
--Verify Category does not exist in Revenue Template (bEMTC)
if exists(select top 1 1 from bEMTC with (nolock) where EMCo = @emco and Category = @category)
	begin
	select @errormsg = 'Revenue Template(s) exist for this category.'
	goto ErrorHandler
	end

--Verify Category does not exist in Auto Use Template (bEMUC)
if exists(select top 1 1 from bEMUC with (nolock) where EMCo = @emco and Category = @category)
	begin
	select @errormsg = 'Revenue Auto Use Template(s) exist for this category.'
	goto ErrorHandler
	end

--Verify Category does not exist in Revenue detail transactions (bEMRD)
if exists(select top 1 1 from bEMRD with (nolock) where EMCo = @emco and Category = @category)
	begin
	select @errormsg = 'Revenue detail transaction(s) exist for this category.'
	goto ErrorHandler
	end

--Create a successful return because no orphaned Equipment entries will be left (that we're currently checking...)
select @rcode = 0

ExitHandler:
return @rcode
   
ErrorHandler:
--Set the return code to a failure and construct the Error message.
select @rcode = 1
select @errormsg = ISNULL(@errormsg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMCategoryDeleteVal] TO [public]
GO
