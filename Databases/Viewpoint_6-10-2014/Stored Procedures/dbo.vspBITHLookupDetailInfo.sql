SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    PROCEDURE [dbo].[vspBITHLookupDetailInfo]
/********************************
* Created: HH 12/18/2012 TK-20362
* Modified: 
*
* Retrieves Lookup form position and column detail information for BITargetHeader.TargetID  Called from the 
* BITHLookup class.
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
  (@targetType varchar(30) = null, @errmsg varchar(512) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @targetType is null 
	begin
	select @errmsg = 'Missing required input parameter: TargetType!', @rcode = 1
	goto vspexit
	end

if not exists(select top 1 1 from DDLHShared where Lookup = 'BITargetID')
	begin
	select @errmsg = 'Lookup: BITargetID is not a valid lookup title!', @rcode = 1
	goto vspexit
	end

-- 1st resultset contains lookup form size and position info
select FormPosition, isnull(GridRowHeight,0) as GridRowHeight 
from vDDUL
where VPUserName = suser_sname() and Lookup = 'BITargetID'

-- 2nd resultset returns Lookup column detail 
;with cte as
(
	select Seq, (select ViewName from DDFHShared where Form = @targetType) + '.' + ColumnName as ColumnName, ColumnHeading, Hidden, ld.Datatype, 
	isnull(ld.InputType, dt.InputType) as [InputType], isnull(ld.InputLength, dt.InputLength) as [InputLength], 
	isnull(ld.InputMask, dt.InputMask) as [InputMask], isnull(ld.Prec, dt.Prec) as [Prec]
	from DDLDShared ld
	left join DDDTShared dt on ld.Datatype = dt.Datatype
	where ld.Lookup = 'BITargetID' 
	
	union all 
	
	select Seq
			, ViewName + '.' + ColumnName
			, ISNULL([Description], ColumnName) as ColumnHeading
			, 'N' as Hidden
			, Datatype
			, InputType
			, InputLength
			, InputMask
			, Prec
	from DDFIShared 
	where Form = @targetType
		and FieldType = 2
		and ViewName is not null
		and substring(ColumnName,1,1) <> ''''
	
	union all 
	
	select Seq
			, ViewName + '.' + ColumnName
			, ISNULL([Description], ColumnName) as ColumnHeading
			, 'N' as Hidden
			, Datatype
			, InputType
			, InputLength
			, InputMask
			, Prec
	from DDFIShared 
	where Form = @targetType
		and FieldType <> 2
		and ViewName is not null
		and ColumnName is not null 
		and substring(ColumnName,1,1) <> ''''
		
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
order by Seq 

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDLookupDetailInfo]'
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspBITHLookupDetailInfo] TO [public]
GO
