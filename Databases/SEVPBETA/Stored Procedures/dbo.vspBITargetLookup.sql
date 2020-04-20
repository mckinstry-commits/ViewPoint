SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    PROCEDURE [dbo].[vspBITargetLookup]
/********************************
* Created: HH 01/11/2013 TK-20362
* Modified: 
*
* Retrieves Lookup form position and column detail information Called from the 
* BITHLookup class.
*
* Input:
*	@targetType		Form #
*	@targetSequence Seq
*
* Output:
*	1st resultset of Lookup form size and position
*	Commented out:  (2nd resultset of column detail )
*						
* Return code:
*	0 = success, 1 = failure
*
*********************************/
  (@targetType varchar(30) = null, @targetSequence smallint, @lookup varchar(30), @errmsg varchar(512) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @targetType is null 
	begin
	select @errmsg = 'Missing required input parameter: TargetType!', @rcode = 1
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
;with cte as
(
	select -1 as Seq
			, ViewName + '.' + CoColumn as ColumnName
			, ISNULL(CoColumn, 'Company') as ColumnHeading
			, 'N' as Hidden
			, 'bCompany' as Datatype
			, null as InputType
			, null as InputLength
			, null as InputMask
			, null as Prec
	from DDFHShared 
	where Form = @targetType
	
	union all
	
	select Seq
			, ViewName + '.' + ColumnName as ColumnName
			, ISNULL([Description], ColumnName) as ColumnHeading
			, 'N' as Hidden
			, Datatype
			, InputType
			, InputLength
			, InputMask
			, Prec
	from DDFIShared 
	where Form = @targetType
)
select (ROW_NUMBER() OVER ( ORDER BY Seq)) - 1 AS [Order]
		,Seq
		,ColumnName
		,ColumnHeading
		,Hidden
		,Datatype
		,InputType
		,InputLength
		,InputMask
		,Prec
from cte
where Seq = @targetSequence
order by Seq 

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspBITargetLookup]'
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspBITargetLookup] TO [public]
GO
