SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  VIEW [dbo].[IMWEHeader]
   /**************************************************
   * Created: ??
   * Modified: 
   *
   * Used by IMWorkEdit.
   *
   ***************************************************/
    AS
    SELECT ImportId, ImportTemplate, Form, RecordType, 
        RecordSeq
    FROM bIMWE a
    GROUP BY ImportId, ImportTemplate, Form, RecordType, 
        RecordSeq

GO
GRANT SELECT ON  [dbo].[IMWEHeader] TO [public]
GRANT INSERT ON  [dbo].[IMWEHeader] TO [public]
GRANT DELETE ON  [dbo].[IMWEHeader] TO [public]
GRANT UPDATE ON  [dbo].[IMWEHeader] TO [public]
GRANT SELECT ON  [dbo].[IMWEHeader] TO [Viewpoint]
GRANT INSERT ON  [dbo].[IMWEHeader] TO [Viewpoint]
GRANT DELETE ON  [dbo].[IMWEHeader] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[IMWEHeader] TO [Viewpoint]
GO
