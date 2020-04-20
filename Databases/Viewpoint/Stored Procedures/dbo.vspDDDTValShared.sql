SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspDDDTValShared]
/***************************************
* Created: TL 6/29/5
* Modified: GG 11/10/06 - added @reportlookup parameter
*
* Used to validate Viewpoint datatype setup in vDDDT and vDDDTc
*
* Used by form frmVACustomFields - (not used in RPRP, RPRTParamters as this comment used to say)
*
* Inputs:
*	@datatype		Datatype to validate
*	
* Outputs:
*	@lookup			Lookup used on forms
*	@setupform		Setup Form (F5)
*	@reportlookup	Lookup used on reports
*   @inputtype		InputType (eg, text = 0, numeric = 1)
*	@msg			Datatype description or error message
*
* Return code:
*	0 = success, 1 = failure
*
**************************************/
	(@datatype char(30) = null, @lookup varchar(30) = null output,
	@setupform varchar(30) = null output, @reportlookup varchar(30) = null output,
	@inputtype tinyint = null output, @msg varchar(60) = null output)

as
set nocount on

declare @rcode int
select @rcode = 0

if @datatype is null
	begin
	select @msg = 'Missing Datatype!', @rcode = 1
	goto vspexit
	end

select @msg = Description, @lookup = Lookup, @setupform = SetupForm, @reportlookup = ReportLookup, @inputtype = InputType
from dbo.DDDTShared (nolock)
where Datatype = @datatype
if @@rowcount = 0
	begin
	select @msg = 'Datatype not setup!', @rcode = 1
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDDTValShared] TO [public]
GO
