SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvDDIndexes]
    as
    select module=substring(object_name(o.id),2,2),'objectname'=convert(varchar(10),object_name(o.id)),
    keyname=convert(varchar(10),i.name),keycnt,colname=col_name(k.id,k.colid),k.colid from 
    sysobjects o left join sysindexes i on o.id=i.id and i.name like 'bi%'
    left join sysindexkeys k on i.id=k.id and i.indid=k.indid
    where o.name like 'b%' and type='U'

GO
GRANT SELECT ON  [dbo].[brvDDIndexes] TO [public]
GRANT INSERT ON  [dbo].[brvDDIndexes] TO [public]
GRANT DELETE ON  [dbo].[brvDDIndexes] TO [public]
GRANT UPDATE ON  [dbo].[brvDDIndexes] TO [public]
GRANT SELECT ON  [dbo].[brvDDIndexes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvDDIndexes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvDDIndexes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvDDIndexes] TO [Viewpoint]
GO
