SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspAPOnCostUpdateAPTL    Script Date: 8/28/99 9:34:02 AM ******/
CREATE                    proc [dbo].[vspAPOnCostUpdateAPTL]
/***********************************************************
* CREATED BY:   MV	04/27/12	TK-14132 APOnCost Processing
* MODIFIED By :	
*
* USAGE:
* Called from AP OnCost Workfile to update OnCostStatus in bAPTL
* for all workfile invoices that are not being processed. 
*
*
*  INPUT PARAMETERS
*  @APCo				AP Company
*
* OUTPUT PARAMETERS
*  @msg                error message if error occurs
*
* RETURN VALUE
*  0                   success
*  1                   failure
*************************************************************/
   
(@APCo bCompany, 
 @Msg varchar(255) OUTPUT)

AS
SET NOCOUNT ON
   
DECLARE @rcode INT,@UserId bVPUserName

SELECT	@rcode = 0, @UserId = SUSER_SNAME() 

-- validate input parameters
IF @APCo IS NULL
BEGIN
	SELECT @Msg = 'Missing AP Company.'
	RETURN 1
END

-- Update APTL OnCostAction = 2 'Never Process'
UPDATE dbo.APTL 
SET SubjToOnCostYN  = 'Y',
	OnCostStatus = 2
FROM dbo. APTL l 
JOIN dbo.vAPOnCostWorkFileDetail o ON l.APCo = o.APCo AND l.Mth = o.Mth AND l.Mth = o.Mth AND l.APTrans = o.APTrans	AND l.APLine = o.APLine
WHERE l.APCo=@APCo AND o.OnCostAction = 2 AND o.UserID = @UserId
-- Delete from workfile
DELETE FROM vAPOnCostWorkFileDetail
WHERE APCo=@APCo AND OnCostAction = 2 AND UserID = @UserId

---- Update APTL OnCostAction = 0 'Ready to process'
UPDATE dbo.APTL 
SET SubjToOnCostYN  = 'Y',
	OnCostStatus = 0
FROM dbo. APTL l 
JOIN dbo.vAPOnCostWorkFileDetail o ON l.APCo = o.APCo AND l.Mth = o.Mth AND l.Mth = o.Mth AND l.APTrans = o.APTrans	AND l.APLine = o.APLine
WHERE l.APCo=@APCo AND o.OnCostAction = 0 AND o.UserID = @UserId
--Delete from workfile
DELETE FROM vAPOnCostWorkFileDetail
WHERE APCo=@APCo AND OnCostAction = 0 AND UserID = @UserId

-- Delete workfile lines
DELETE FROM
dbo.APOnCostWorkFileDetail
WHERE APCo=@APCo AND UserID=@UserId

-- delete workfile headers
DELETE FROM dbo.APOnCostWorkFileHeader
WHERE APCo=@APCo AND UserID=@UserId


RETURN 

GO
GRANT EXECUTE ON  [dbo].[vspAPOnCostUpdateAPTL] TO [public]
GO
