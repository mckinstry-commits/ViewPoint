SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 CREATE	PROC [dbo].[vspHQUDGetRelatedForms]
 /***********************************************************
  * CREATED BY	: kb 9/29/00
  * RECREATED BY: JRK 01/25/07 Port for VP6.  Source tables were redesigned.  All different now.
  * Modified By:  RM 04/05/2010 - 135111 - Re-designed query to return a concise set of info, including whether the column exists.
  *			      CC 06/04/10 - Issue #139368 - Use the CustomFieldView to override viewname when convention does not work
  *
  * USED IN: frmVACustomFields
  *
  * USAGE: 
  * Find related forms that have the same custom field on it.
  * Returns a multi-row dataset with many fields from DDFIc, including 
  * the names of the forms where these same-named custom fields are already in use.
  * Joins vDDFIc to vDDFR.
  *
  * INPUT PARAMETERS
  *  @formname is required.
  *  @columnname is required.  Look for related forms that have the same named column.
  * OUTPUT PARAMETERS
  *   @msg      error message if error occurs
  * RETURN VALUE
  *   0         success
  *   1         Failure
  *****************************************************/

     (@formname varchar(30) = null, 
      @columnname varchar(30) = null, 
	  @msg varchar(30) output)
AS
BEGIN
	SET NOCOUNT ON;
   
    DECLARE @rcode int;
    SELECT @rcode = 0;
	IF @formname = NULL
	BEGIN
		SELECT @rcode=1, @msg='No form specified!';
		GOTO bspexit;
	END

	IF @columnname = NULL
	BEGIN
		SELECT @rcode=1, @msg='No column specified!';
		GOTO bspexit;
	END
		-- Find only forms related to the specified form that have custom field.
	SELECT f.RelatedForm as Form, h.Title, COALESCE(h.CustomFieldView, h.ViewName) AS ViewName, h.CustomFieldTable,
	CASE WHEN c.Form IS NULL THEN 'N' ELSE 'Y' END AS FormContainsColumn,
	c.Tab AS FormColumnTab
	FROM vDDFR f
	INNER JOIN vDDFH h on f.RelatedForm = h.Form
	LEFT JOIN vDDFIc c on f.RelatedForm = c.Form AND c.ColumnName = @columnname
	WHERE f.Form = @formname
	
	UNION
	
	SELECT f.Form, h.Title, COALESCE(h.CustomFieldView, h.ViewName) AS ViewName, h.CustomFieldTable,
	CASE WHEN c.Form IS NULL THEN 'N' ELSE 'Y' END AS FormContainsColumn,
	c.Tab AS FormColumnTab
	FROM vDDFR f
	INNER JOIN vDDFH h ON f.Form = h.Form
	LEFT JOIN vDDFIc c ON f.Form = c.Form AND c.ColumnName = @columnname
	WHERE f.RelatedForm = @formname
		
		/*
		select r.RelatedForm from vDDFR r
		join vDDFIc c on c.Form = r.RelatedForm
		where r.Form = @formname and c.ColumnName = @columnname
		*/
		/*
		select distinct c.Form from vDDFIc c
		join vDDFR r on r.Form = c.Form or r.RelatedForm = c.Form
		*/
bspexit:
     	return @rcode
END
GO
GRANT EXECUTE ON  [dbo].[vspHQUDGetRelatedForms] TO [public]
GO
