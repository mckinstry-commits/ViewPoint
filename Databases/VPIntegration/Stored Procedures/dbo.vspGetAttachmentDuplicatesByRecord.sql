SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:        Ken Eucker, vspGetAttachmentDuplicatesByRecord
-- Create date: 2/9/2012
-- Description:   Takes an optional parameter of the UniquAttachID of a form record to find the duplicates. 
-- If no parameter is sent, the procedure returns all duplicates for all records. The columns it returns 
-- are the AttachmentID, the UniqueAttachId, and a unique identifier that matches a set of attachments 
-- to a single UniqueAttachId.
-- =============================================
CREATE PROCEDURE [dbo].[vspGetAttachmentDuplicatesByRecord]
      (@uniqueattachid varchar(120)='')
AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;
      IF @uniqueattachid <> ''
            BEGIN
                  SELECT a.AttachmentID, a.UniqueAttchID, a.UniqueKey
                  FROM 
                  (
                          SELECT f.AttachmentID,t.UniqueAttchID,
                                    ROW_NUMBER() OVER(PARTITION BY CHECKSUM(CONVERT(VARBINARY(MAX), [AttachmentData])) ORDER BY f.AttachmentID DESC) AS RowNum,
                                    ROW_NUMBER() OVER(PARTITION BY CHECKSUM(CONVERT(VARBINARY(MAX), [AttachmentData])) ORDER BY f.AttachmentID ASC) AS RowNumASC,
                                    CONVERT(VARCHAR(36),t.UniqueAttchID) + CONVERT(varchar(MAX),CHECKSUM(CONVERT(VARBINARY(MAX),[AttachmentData]))) AS UniqueKey
                          FROM bHQAF f -- unique attach stuff
                                    JOIN bHQAT t ON t.AttachmentID = f.AttachmentID         
                          WHERE t.UniqueAttchID = @uniqueattachid
                        
                  ) a 
                  WHERE a.RowNum > 1
                  OR a.RowNumASC > 1
                  GROUP BY a.UniqueKey,a.AttachmentID, a.UniqueAttchID
            END
      ELSE
            BEGIN
                  SELECT a.AttachmentID, a.UniqueAttchID, a.UniqueKey
                  FROM 
                  (
                          SELECT f.AttachmentID,t.UniqueAttchID,
                                    ROW_NUMBER() OVER(PARTITION BY CHECKSUM(CONVERT(VARBINARY(MAX), [AttachmentData])) ORDER BY f.AttachmentID DESC) AS RowNum,
                                    ROW_NUMBER() OVER(PARTITION BY CHECKSUM(CONVERT(VARBINARY(MAX), [AttachmentData])) ORDER BY f.AttachmentID ASC) AS RowNumASC,
                                    CONVERT(VARCHAR(36),t.UniqueAttchID) + CONVERT(varchar(MAX),CHECKSUM(CONVERT(VARBINARY(MAX),[AttachmentData]))) AS UniqueKey
                          FROM bHQAF f -- unique attach stuff
                                    JOIN bHQAT t ON t.AttachmentID = f.AttachmentID         
                        
                  ) a 
                  WHERE a.RowNum > 1
                  OR a.RowNumASC > 1
                  GROUP BY a.UniqueKey,a.AttachmentID, a.UniqueAttchID
            END
END
GO
GRANT EXECUTE ON  [dbo].[vspGetAttachmentDuplicatesByRecord] TO [public]
GO
