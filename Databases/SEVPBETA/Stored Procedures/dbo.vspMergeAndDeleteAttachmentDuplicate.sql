SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:        Ken Eucker
-- Create date: 2/9/2012
-- Description:   takes two paramaters, one AttachmentID 
-- to delete and merge and the target AttachmentID to merge into. 
-- The procedure then takes all of the records in HQAI that are CustomYN 
-- and merges them into the target record and deletes the record from HQAT.
-- =============================================
CREATE  PROCEDURE [dbo].[vspMergeAndDeleteAttachmentDuplicate]
      (@attachid VarChar(25), @targetattachid VarChar(25))
AS
BEGIN
      SET NOCOUNT ON;
      
      DECLARE @targetIndexSeq INT
      -- Get a lock on all records before running transaction
      SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
      BEGIN TRAN
      SELECT @targetIndexSeq=MAX(IndexSeq)
           FROM bHQAI 
           WHERE AttachmentID=@targetattachid 
      
      IF @targetIndexSeq IS NOT NULL
      BEGIN
		  UPDATE bHQAI SET AttachmentID=@targetattachid,IndexSeq=newI.newIndexSeq
		  FROM bHQAI targetHQAI
		  CROSS APPLY
		  (      
			  SELECT @targetIndexSeq + ROW_NUMBER() OVER(ORDER BY IndexSeq) As newIndexSeq
			  FROM bHQAI fromHQAI
			  WHERE targetHQAI.AttachmentID=fromHQAI.AttachmentID 
				AND targetHQAI.[CustomYN]='Y' 
				AND targetHQAI.IndexSeq=fromHQAI.IndexSeq
		  )
		  AS newI  
		  WHERE AttachmentID=@attachid AND [CustomYN]='Y'
	  END 
	  -- Delete the indexes that exist for the attachment that aren't custom
	  DELETE FROM bHQAI WHERE AttachmentID=@attachid AND [CustomYN]='N'
      -- Delete attachment from HQAT
      -- DELETE FROM bHQAT WHERE AttachmentID=@attachid
      -- Archive attachment from HQAF (REPLACE WITH API CALL)
      --DELETE FROM bHQAF WHERE AttachmentID=@attachid
      COMMIT
 END
GO
GRANT EXECUTE ON  [dbo].[vspMergeAndDeleteAttachmentDuplicate] TO [public]
GO
