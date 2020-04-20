SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
*	Created by: JonathanP 08/25/2008
*	Description: This view will show all the columns in DDFIShared and DDQueryableColumns that are queryable.
*
*/

CREATE VIEW [dbo].[DDQueryableColumnsShared]
AS 

select Form, Seq, isnull(QueryColumnName, ColumnName) as QueryColumnName, Datatype, InputType, InputMask, InputLength, Prec, 
	   ControlType, ComboType, ShowInQueryFilter, ShowInQueryResultSet, 'DD Form Column' as [Column Type]	   
from DDFIShared
where isnull(QueryColumnName, ColumnName) is not null and (ShowInQueryFilter = 'Y' or ShowInQueryResultSet = 'Y')
union 

select Form, Seq, QueryColumnName, Datatype, InputType, InputMask, InputLength, Prec, 
	   ControlType, ComboType, ShowInQueryFilter, ShowInQueryResultSet, 'DD Queryable Column' as [Column Type]
from DDQueryableColumns




GO
GRANT SELECT ON  [dbo].[DDQueryableColumnsShared] TO [public]
GRANT INSERT ON  [dbo].[DDQueryableColumnsShared] TO [public]
GRANT DELETE ON  [dbo].[DDQueryableColumnsShared] TO [public]
GRANT UPDATE ON  [dbo].[DDQueryableColumnsShared] TO [public]
GO
