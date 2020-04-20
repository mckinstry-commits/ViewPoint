SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE     view [dbo].[brvHQAuditDetail] as 
 select ViewName=SubString(TableName,2,30),
        KeyString,
        Co= IsNull(HQCO.HQCo,0),
        RecType,
        FieldName,
        OldValue,
        NewValue, 
        DateTime,
        UserName
 From HQMA 
 Cross Join HQCO
where Co is NULL

UNION ALL

 select ViewName=SubString(TableName,2,30),
        KeyString,
        Co,
        RecType,
        FieldName,
        OldValue,
        NewValue, 
        DateTime,
        UserName
 From bHQMA 
Where Co is not NULL


GO
GRANT SELECT ON  [dbo].[brvHQAuditDetail] TO [public]
GRANT INSERT ON  [dbo].[brvHQAuditDetail] TO [public]
GRANT DELETE ON  [dbo].[brvHQAuditDetail] TO [public]
GRANT UPDATE ON  [dbo].[brvHQAuditDetail] TO [public]
GRANT SELECT ON  [dbo].[brvHQAuditDetail] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvHQAuditDetail] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvHQAuditDetail] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvHQAuditDetail] TO [Viewpoint]
GO
