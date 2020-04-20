SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspDDGetFieldPropertiesFields]
/********************************
* Created: MJ 4 -25-06
* Modified: GG 06/01/06 - cleanup
*			AMR - 6/27/11 - TK-06411, Fixing performance issue by using an inline table function.
*
* Returns all of the Sequences for a form except type '99' for use in
* the Field Properties form
*
* Input:
*	@form		current form name

* Output:
*	resultset of form sequence #s and descriptions
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/ 
( @form VARCHAR(30) = NULL )
AS 
    SET nocount ON
	
    DECLARE @rcode INT
	
    SELECT  @rcode = 0

-- get seq# and description for all inputs linked to a control on the form
    SELECT  Seq,
            [Description]
    FROM    dbo.vfDDFIShared(@form)
    WHERE   Form = @form
            AND ControlType <> 99
    ORDER BY Seq

    RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspDDGetFieldPropertiesFields] TO [public]
GO
