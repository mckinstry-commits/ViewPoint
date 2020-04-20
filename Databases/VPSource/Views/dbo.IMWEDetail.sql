SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.IMWEDetail
   /**************************************************
   * Created: CC 03/26/2008
   * Modified: 
   *
   * Used by IMWorkEdit Detail to include notes
   *
   ***************************************************/
    AS		
	SELECT CAST(UploadVal AS VARCHAR(MAX)) AS UploadVal, CAST(ImportedVal AS VARCHAR(MAX)) AS ImportedVal, Identifier, ImportId, 'N' AS IsNote, ImportTemplate, RecordType, Form, RecordSeq
	FROM IMWE e
UNION ALL
	SELECT UploadVal, ImportedVal, Identifier, ImportId, 'Y' AS IsNote, ImportTemplate, RecordType, Form, RecordSeq
	FROM IMWENotes

GO
GRANT SELECT ON  [dbo].[IMWEDetail] TO [public]
GRANT INSERT ON  [dbo].[IMWEDetail] TO [public]
GRANT DELETE ON  [dbo].[IMWEDetail] TO [public]
GRANT UPDATE ON  [dbo].[IMWEDetail] TO [public]
GO
