SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGetFormQueryForProxy]
/**************************************************
* Created: Chris G 4/26/2013
*
* This procedure returns enough data to load a VPForm proxy.
*
* Inputs:
*	@FormName		The name of the form in DDFH
*	
*
* Output:
*	resultset1	DDFI Sequences
*	resultset2	Query Text, KeyID ColumnName
*
* Return code:
*
****************************************************/

(@FormName VARCHAR(30))

AS
BEGIN
	DECLARE @formSql VARCHAR(MAX)
	DECLARE @keyIdColumn VARCHAR(256)

	-- get DDFI sequences
	
	  SELECT Seq, ColumnName
	    FROM dbo.vfDDFIShared(@FormName)
    ORDER BY Seq
	
	-- get the form query
	exec vspVPGetFormQueryText @FormName, null, @formSql output, @keyIdColumn output;
	
	SELECT @formSql, @keyIdColumn	
END
GO
GRANT EXECUTE ON  [dbo].[vspVPGetFormQueryForProxy] TO [public]
GO
