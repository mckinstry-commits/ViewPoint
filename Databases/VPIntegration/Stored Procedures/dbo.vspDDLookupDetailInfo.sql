SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    PROCEDURE [dbo].[vspDDLookupDetailInfo]
/********************************
* Created: GG 08/12/03 
* Modified: 
 * GG 01/26/04 - return 2 resultsets 
*
* Retrieves DD Lookup form position and column detail information.  Called from the 
* Lookup class each time a user requests a lookup at a form or report parmeter input.
*
* Input:
*	@lookup		Current active company #
*
* Output:
*	1st resultset of Lookup form size and position
*	Commented out:  (2nd resultset of column detail )
*						
* Return code:
*	0 = success, 1 = failure
*
*********************************/
  (@lookup varchar(30) = null, @errmsg varchar(512) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @lookup is null 
	begin
	select @errmsg = 'Missing required input parameter: Lookup!', @rcode = 1
	goto vspexit
	end

if not exists(select top 1 1 from DDLHShared where Lookup = @lookup)
	begin
	select @errmsg = 'Lookup: ' + @lookup + ' is not a valid lookup title!', @rcode = 1
	goto vspexit
	end

-- 1st resultset contains lookup form size and position info
select FormPosition, isnull(GridRowHeight,0) as GridRowHeight 
from vDDUL
where VPUserName = suser_sname() and Lookup = @lookup

-- 2nd resultset returns Lookup column detail 
select Seq, ColumnName, ColumnHeading, Hidden, ld.Datatype, 
	isnull(ld.InputType, dt.InputType) as [InputType], isnull(ld.InputLength, dt.InputLength) as [InputLength], 
	isnull(ld.InputMask, dt.InputMask) as [InputMask], isnull(ld.Prec, dt.Prec) as [Prec]
from DDLDShared ld
left join DDDTShared dt on ld.Datatype = dt.Datatype
where ld.Lookup = @lookup 
order by Seq 

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDLookupDetailInfo]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDLookupDetailInfo] TO [public]
GO
