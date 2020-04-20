SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMGetInputFieldMask]
/************************************************************************
* CREATED:   RT 01/10/2013
* MODIFIED:  D-05423 : Cross Reference Viewpoint Value not applying formats properly
*
* Purpose of Stored Procedure
*
*    Return the input mask for a given Template and CrossReference
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successful 
* returns 1 and error msg if failed
*
*************************************************************************/

	@Template varchar(max)
,	@XRefName varchar(max)
,	@msg varchar(60) output

as
set nocount on   
declare @rcode int   
select @rcode = 1

if @Template is null
begin
	select @msg = 'Missing required paramter, @Template.', @rcode = 1
	goto bspexit
end

if @XRefName is null
begin
	select @msg = 'Missing required paramter, @XRefName.', @rcode = 1
	goto bspexit
end

Select top 1 
	 DDDTShared.InputLength as InputLength
	,DDDTShared.InputType as InputType
	,DDDTShared.InputMask as InputMask
	,DDDTShared.Prec as Prec
from IMXH 
	inner join IMTD IMTD with (nolock) on IMXH.ImportTemplate = IMTD.ImportTemplate and IMXH.RecordType = IMTD.RecordType and IMXH.Identifier = IMTD.Identifier
	inner join DDDTShared with (nolock) on IMTD.Datatype=DDDTShared.Datatype 
Where IMXH.ImportTemplate = @Template
	and IMXH.XRefName = @XRefName

select @rcode = 0

bspexit:

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMGetInputFieldMask] TO [public]
GO
