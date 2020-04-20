SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jonathan Paullin
-- Create date: 07/03/2008
-- Modified:
--		CG 12/09/2010 - Issue #140507 - Changed to no longer require column named "KeyID" to indicate identity column
-- Description:	The stored procedure will bring back all the columns in the clustered
--				index for a batch posting table from a given DDFH record.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMGetIndexColumnsForDDFHBatchPostingTable]
	-- Add the parameters for the stored procedure here
	@DDFHForm varchar(30), @batchPostingView varchar(30) output, @returnMessage varchar(255) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @returnCode int
	SELECT @returnCode = 0
		
	-- Get the posted table and then remove the first character to get the view.	
	SELECT @batchPostingView = PostedTable FROM DDFH WHERE Form = @DDFHForm	
	SELECT @batchPostingView = SUBSTRING(@batchPostingView, 1, len(@batchPostingView))
	
	-- Get the identity column of the table
	declare @identityColumn varchar(128)
	exec vspDDGetIdentityColumn @batchPostingView, @identityColumn output
	
	-- Get all of the columns involved in any of the indexes for the specified table. (exclude KeyID)
	SELECT DISTINCT c.name as [Column Name], '' as [Filter Value]
		FROM sys.indexes si
		INNER JOIN sys.index_columns ic 
			ON ic.object_id = si.object_id AND ic.index_id = si.index_id
		INNER JOIN sys.columns c 
			ON c.object_id = ic.object_id AND c.column_id = ic.column_id			
		WHERE si.object_id = object_id(@batchPostingView) AND c.name <> @identityColumn AND c.name <> 'UniqueAttchID'
	   
END




/****** Object:  StoredProcedure [dbo].[vspDDQueryColumnValidate]    Script Date: 12/09/2010 09:42:56 ******/
SET ANSI_NULLS ON

GO
GRANT EXECUTE ON  [dbo].[vspDMGetIndexColumnsForDDFHBatchPostingTable] TO [public]
GO
