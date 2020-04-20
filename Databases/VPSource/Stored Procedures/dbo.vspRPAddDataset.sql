SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
* Create date:  10/14/2008
* Description:	Adds a DataSet and Query for the given report
*
*	Inputs:
*	@ReportID		The report to add the dataset & query for
*	@DataSetName	The name of the dataset
*	@Query		The query associated with the dataset
*
*	Outputs:
*	None
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspRPAddDataset]
	-- Add the parameters for the stored procedure here
	@ReportID int,
	@DataSetName VARCHAR(50) = NULL,
	@Query VARCHAR(MAX) = NULL
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE FROM RPRQShared WHERE ReportID = @ReportID AND DataSetName = @DataSetName

	INSERT INTO RPRQShared (ReportID, DataSetName, QueryText) VALUES (@ReportID, @DataSetName, @Query);

END


GO
GRANT EXECUTE ON  [dbo].[vspRPAddDataset] TO [public]
GO
