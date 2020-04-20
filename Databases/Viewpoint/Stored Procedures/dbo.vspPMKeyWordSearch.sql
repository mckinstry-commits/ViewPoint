SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMKeyWordSearch Script Date: 08/17/2005 ******/
CREATE PROC [dbo].[vspPMKeyWordSearch]
/*************************************
 * Created By:	GF 11/05/2010 - TFS #
 * Modified by: 
 *
 * used in PM Manage record association to find a key word
 * in various PM tables and return a list of records.
 *
 * 
 *
 *
 * Pass:
 * PMCo				PM Company
 * Project			PM Project
 *
 *
 *
 * Returns:
 * 
 * Success returns:
 * ================
 * 0 AND result set of PM records that have the keyword
 * in the record.
 * @msg
 *
 * Error returns:
 * ==============
 * 1 AND @msg - error message
 *  
 **************************************/
(@ColumnToSearch NVARCHAR(128) = NULL, @SearchCondition NVARCHAR(max) = NULL,
 @msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

---- FIRST FIND OUT WHAT VERSION OF SQL SERVER WE ARE ON.
DECLARE @rcode INT, @SQLVersion INT

SET @rcode = 0

SET @SQLVersion = SUBSTRING(@@VERSION, CHARINDEX(N' - ', @@VERSION) + 3,1)

SET @msg = CAST(@SQLVersion AS VARCHAR)







vspExit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMKeyWordSearch] TO [public]
GO
