SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE procedure [dbo].[vspVAWDQueryEmailList]
  /************************************************************************
  * CREATED: 	MV 02/28/07   
  * MODIFIED:   HH 10/17/12  TK-18458 added VPGridQueryColumns for type VPGridQueries
  *
  * Purpose of Stored Procedure:	Used by VAWDQueries form to fill the 
  *									Email Fields list view.  
  * 
  *
  * returns 0 if successfull 
  * returns 1 and error msg if failed
  *
  *************************************************************************/
          
(@queryname varchar(50), @querytype int = 0)

as
set nocount on

declare @rcode int
select @rcode = 0

if @querytype = 1
	Select	'[' + ColumnName + ']' as EMailField
			, ColumnName as TableColumn 
	from	VPGridColumns 
	Where	QueryName = @queryname 
	Order By TableColumn
else
	Select	EMailField
			, TableColumn 
	from WDQF 
	Where QueryName = @queryname 
	Order By TableColumn

if @@rowcount = 0
begin
	select @rcode=1
end

bspexit:
return @rcode








GO
GRANT EXECUTE ON  [dbo].[vspVAWDQueryEmailList] TO [public]
GO
