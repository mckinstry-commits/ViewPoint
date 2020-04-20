SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMUTStdTemplateVal    Script Date: 7/10/2006 ******/
CREATE proc [dbo].[vspPMUTStdTemplateVal]
/*************************************
 * Created By:	GF 07/10/2006
 * Modified By:
 *
 *
 * Validates PM Std Template in PM Import Master.
 *
 * Pass:
 * PM Import Template
 * PM Std Template
 * PM Std Template Import Routine
 *
 * Success returns:
 *	0 and Description from PMUT
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@template varchar(10) = null, @stdtemplate varchar(10) = null, @importroutine varchar(20) = null,
 @msg varchar(255) output)
as 
set nocount on

declare @rcode int, @stdtemplate_routine varchar(20)

select @rcode = 0

if @template is null
	begin
	select @msg = 'Missing Import Template', @rcode = 1
	goto bspexit
	end

if @stdtemplate is null
	begin
	select @msg = 'Missing Standard Template', @rcode = 1
	goto bspexit
	end

if @importroutine is null
	begin
	select @msg = 'Missing Import Routine for Template', @rcode = 1
	goto bspexit
	end

------ standard template must not equal template
if @stdtemplate = @template
	begin
	select @msg = 'Standard Template cannot equal template', @rcode = 1
	goto bspexit
	end

------ validate template and get import routine
select @msg=Description, @stdtemplate_routine=ImportRoutine
from PMUT with (nolock) where Template = @stdtemplate
if @@rowcount = 0
	begin
	select @msg = 'Not a valid Standard Template', @rcode = 1
	goto bspexit
	end

if @stdtemplate_routine <> @importroutine
	begin
	select @msg = 'The import routine for the standard template is not the same as the import routine for this template', @rcode = 1
	goto bspexit
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMUTStdTemplateVal] TO [public]
GO
