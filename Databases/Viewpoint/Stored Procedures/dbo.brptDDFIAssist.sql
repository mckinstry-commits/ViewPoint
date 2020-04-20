SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[brptDDFIAssist] 
/**************************************
* Created: ?
* Modified: GG 05/02/07 - V6 and SQL2005 mods
*			AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function.
*
*
**************************************/ ( @FormName VARCHAR(30) )
AS -- create temp table 
    CREATE TABLE #DDFIAssist
        (
          Form VARCHAR(30) NULL,
          Seq INT NULL,
          ColumnName VARCHAR(500) NULL,
          RecType VARCHAR(12) NULL,
          ObjName VARCHAR(30) NULL,
          Params VARCHAR(255) NULL,
          WhereClause VARCHAR(512) NULL,
          ProcCol VARCHAR(30) NULL,
          Datatype VARCHAR(30) NULL,
          Leng INT NULL,
          InOut VARCHAR(3) NULL
        )

-- Form Seq#s w/Datatype Lookup info  
    INSERT  #DDFIAssist
            ( Form,
              Seq,
              ColumnName,
              Datatype,
              RecType,
              ObjName,
              WhereClause,
              Params
            )
            SELECT  i.Form,
                    i.Seq,
                    i.ColumnName,
                    i.Datatype,
                    'Lookups',
                    d.Lookup,
                    l.WhereClause,
                    i.LookupParams
                    -- use inline table function for perf
            FROM    dbo.vfDDFIShared(@FormName) i
                    JOIN dbo.DDDTShared d ( NOLOCK ) ON d.Datatype = i.Datatype
                    JOIN dbo.DDLHShared l ( NOLOCK ) ON l.Lookup = d.Lookup
               
-- Form Seq#s w/Setup info
    INSERT  #DDFIAssist
            ( Form,
              Seq,
              ColumnName,
              Datatype,
              RecType,
              ObjName,
              Params
            )
            SELECT  i.Form,
                    i.Seq,
                    i.ColumnName,
                    i.Datatype,
                    'Setups',
                    d.SetupForm,
                    i.SetupParams
                    -- use inline table function for perf
            FROM    dbo.vfDDFIShared(@FormName) i
                    JOIN dbo.DDDTShared d ( NOLOCK ) ON d.Datatype = i.Datatype
               
-- Form Seq#s w/Validation Proc info
    INSERT  #DDFIAssist
            ( Form,
              Seq,
              ColumnName,
              RecType,
              ObjName,
              Params,
              ProcCol,
              Datatype,
              Leng,
              InOut
            )
            SELECT  i.Form,
                    i.Seq,
                    i.ColumnName,
                    'Validations',
                    i.ValProc,
                    i.ValParams,
                    s.name,
                    t.name,
                    s.length,
                    CASE s.status
                      WHEN 0 THEN 'In'
                      ELSE 'Out'
                    END
                    -- use inline table function for perf
            FROM    dbo.vfDDFIShared(@FormName) i
                    JOIN sys.syscolumns s ON s.id = OBJECT_ID(i.ValProc)
                    LEFT JOIN sys.systypes t ON t.type = s.type
                                                AND t.usertype = s.usertype
            WHERE    s.id = OBJECT_ID(i.ValProc)
 
-- return resultset from temp table 
    SELECT  *
    FROM    #DDFIAssist
    
    DROP TABLE #DDFIAssist

GO
GRANT EXECUTE ON  [dbo].[brptDDFIAssist] TO [public]
GO
