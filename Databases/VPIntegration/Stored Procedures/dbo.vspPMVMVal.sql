SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMVMVal    Script Date: 01/14/2008 ******/
CREATE   proc [dbo].[vspPMVMVal]
/*************************************
 *
 * Created By:	GP 01/14/2008
 * Modified by:
 *
 * Validates PM Document Tracking View in PMVM from Source View field
 * on PM Document Tracking View Copy.
 *
 * Input:
 * PM Document Tracking View
 * 
 * Output:
 * Success - 0 
 * Failure - 1
 *
 **************************************/
(@ViewName varchar(10), @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

-- Validate that view exists in PMVM
if not exists(select top 1 1 from PMVM with (nolock) where ViewName = @ViewName)
begin
	select @msg = 'Source view name must exist in PM Document Tracking Views.', @rcode = 1
	goto vspexit
end

-- Get view description
if isnull(@ViewName,'') <> ''
begin
	select @msg = Description from PMVM with (nolock) where ViewName = @ViewName
end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMVMVal] TO [public]
GO
